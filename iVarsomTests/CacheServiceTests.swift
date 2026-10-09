import Foundation
import Testing
@testable import Skredvarsel

struct CacheServiceTests {
    @Test func regionsRoundTripAndCountryIsolation() async {
        let directory = TemporaryDirectory()
        let cache = CacheService(directory: directory.url)
        await cache.saveRegions([Fixtures.region()], country: .norway)
        await cache.saveRegions([Fixtures.region(100001)], country: .sweden)
        #expect(await cache.loadRegions(country: .norway)?.first?.id == 3003)
        #expect(await cache.loadRegions(country: .sweden)?.first?.id == 100001)
    }

    @Test func warningsRoundTripAndRegionIsolation() async {
        let directory = TemporaryDirectory()
        let cache = CacheService(directory: directory.url)
        await cache.saveWarningsDetailed([Fixtures.warning(danger: .level2)], regionId: 3003)
        await cache.saveWarningsDetailed([Fixtures.warning(3006, danger: .level4)], regionId: 3006)
        #expect(await cache.loadWarningsDetailed(regionId: 3003)?.first?.DangerLevel == .level2)
        #expect(await cache.loadWarningsDetailed(regionId: 3006)?.first?.DangerLevel == .level4)
        #expect(await cache.isWarningFresh(regionId: 3003))
    }

    @Test func missingAndCorruptFilesAreCacheMisses() async throws {
        let directory = TemporaryDirectory()
        let cache = CacheService(directory: directory.url)
        #expect(await cache.loadRegions(country: .norway) == nil)
        #expect(await cache.loadWarningsDetailed(regionId: 3003) == nil)
        #expect(await cache.isFresh(country: .norway) == false)
        #expect(await cache.isWarningFresh(regionId: 3003) == false)
        await cache.saveRegions([], country: .norway)
        try Data("corrupted".utf8).write(to: directory.url.appendingPathComponent("regions_norway.json"))
        #expect(await cache.loadRegions(country: .norway) == nil)
        #expect(await cache.isFresh(country: .norway) == false)
    }

    @Test(arguments: [(-1.0, false), (0.0, true), (14399.0, true), (14400.0, false)])
    func freshnessBoundary(age: Double, expected: Bool) async {
        let directory = TemporaryDirectory()
        let writer = CacheService(directory: directory.url, now: { Fixtures.date })
        await writer.saveRegions([], country: .norway)
        let reader = CacheService(directory: directory.url, now: { Fixtures.date.addingTimeInterval(age) })
        #expect(await reader.isFresh(country: .norway) == expected)
    }

    @Test func clearAndReuse() async {
        let directory = TemporaryDirectory()
        let cache = CacheService(directory: directory.url)
        await cache.saveRegions([], country: .norway)
        await cache.saveWarningsDetailed([], regionId: 3003)
        await cache.clearAll()
        #expect(await cache.loadRegions(country: .norway) == nil)
        #expect(await cache.loadWarningsDetailed(regionId: 3003) == nil)
        await cache.saveRegions([Fixtures.region()], country: .norway)
        #expect(await cache.loadRegions(country: .norway)?.count == 1)
    }
}
