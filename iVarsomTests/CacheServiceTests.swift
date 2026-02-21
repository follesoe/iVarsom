import XCTest
@testable import Skredvarsel

@MainActor
class CacheServiceTests: XCTestCase {
    private var cacheService: Skredvarsel.CacheService!

    override func setUp() async throws {
        cacheService = CacheService()
        cacheService.clearAll()
    }

    override func tearDown() async throws {
        cacheService.clearAll()
        cacheService = nil
    }

    func testSaveAndLoadRegionsRoundTrip() {
        let regions: [Skredvarsel.RegionSummary] = [
            RegionSummary(Id: 3003, Name: "Nordenskiöld Land", TypeName: "A", AvalancheWarningList: []),
            RegionSummary(Id: 3006, Name: "Finnmarkskysten", TypeName: "A", AvalancheWarningList: [])
        ]

        cacheService.saveRegions(regions, country: Skredvarsel.Country.norway)
        let loaded = cacheService.loadRegions(country: Skredvarsel.Country.norway)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 2)
        XCTAssertEqual(loaded?[0].Id, 3003)
        XCTAssertEqual(loaded?[0].Name, "Nordenskiöld Land")
        XCTAssertEqual(loaded?[1].Id, 3006)
    }

    func testSaveAndLoadWarningsRoundTrip() {
        let warnings = [makeWarning(regionId: 3003, dangerLevel: .level3)]

        cacheService.saveWarningsDetailed(warnings, regionId: 3003)
        let loaded = cacheService.loadWarningsDetailed(regionId: 3003)

        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.count, 1)
        XCTAssertEqual(loaded?[0].RegionId, 3003)
        XCTAssertEqual(loaded?[0].DangerLevel, Skredvarsel.DangerLevel.level3)
    }

    func testLoadRegionsReturnsNilWhenNoCache() {
        let loaded = cacheService.loadRegions(country: Skredvarsel.Country.norway)
        XCTAssertNil(loaded)
    }

    func testLoadWarningsReturnsNilWhenNoCache() {
        let loaded = cacheService.loadWarningsDetailed(regionId: 9999)
        XCTAssertNil(loaded)
    }

    func testIsFreshReturnsTrueForRecentCache() {
        let regions: [Skredvarsel.RegionSummary] = [
            RegionSummary(Id: 3003, Name: "Test", TypeName: "A", AvalancheWarningList: [])
        ]
        cacheService.saveRegions(regions, country: Skredvarsel.Country.norway)

        XCTAssertTrue(cacheService.isFresh(country: Skredvarsel.Country.norway))
    }

    func testIsFreshReturnsFalseWhenNoCache() {
        XCTAssertFalse(cacheService.isFresh(country: Skredvarsel.Country.norway))
    }

    func testIsWarningFreshReturnsTrueForRecentCache() {
        let warnings = [makeWarning(regionId: 3003, dangerLevel: .level2)]
        cacheService.saveWarningsDetailed(warnings, regionId: 3003)

        XCTAssertTrue(cacheService.isWarningFresh(regionId: 3003))
    }

    func testIsWarningFreshReturnsFalseWhenNoCache() {
        XCTAssertFalse(cacheService.isWarningFresh(regionId: 9999))
    }

    func testClearAllRemovesCachedData() {
        let regions: [Skredvarsel.RegionSummary] = [
            RegionSummary(Id: 3003, Name: "Test", TypeName: "A", AvalancheWarningList: [])
        ]
        cacheService.saveRegions(regions, country: Skredvarsel.Country.norway)
        cacheService.saveRegions(regions, country: Skredvarsel.Country.sweden)

        cacheService.clearAll()

        XCTAssertNil(cacheService.loadRegions(country: Skredvarsel.Country.norway))
        XCTAssertNil(cacheService.loadRegions(country: Skredvarsel.Country.sweden))
    }

    func testPerRegionWarningCachesAreIndependent() {
        let warnings1 = [makeWarning(regionId: 3003, dangerLevel: .level2)]
        let warnings2 = [makeWarning(regionId: 3006, dangerLevel: .level4)]

        cacheService.saveWarningsDetailed(warnings1, regionId: 3003)
        cacheService.saveWarningsDetailed(warnings2, regionId: 3006)

        let loaded1 = cacheService.loadWarningsDetailed(regionId: 3003)
        let loaded2 = cacheService.loadWarningsDetailed(regionId: 3006)

        XCTAssertEqual(loaded1?[0].DangerLevel, Skredvarsel.DangerLevel.level2)
        XCTAssertEqual(loaded2?[0].DangerLevel, Skredvarsel.DangerLevel.level4)
    }

    func testNorwayAndSwedenCachesAreIndependent() {
        let norwayRegions: [Skredvarsel.RegionSummary] = [
            RegionSummary(Id: 3003, Name: "Norway Region", TypeName: "A", AvalancheWarningList: [])
        ]
        let swedenRegions: [Skredvarsel.RegionSummary] = [
            RegionSummary(Id: 100001, Name: "Sweden Region", TypeName: "A", AvalancheWarningList: [])
        ]

        cacheService.saveRegions(norwayRegions, country: Skredvarsel.Country.norway)
        cacheService.saveRegions(swedenRegions, country: Skredvarsel.Country.sweden)

        let loadedNorway = cacheService.loadRegions(country: Skredvarsel.Country.norway)
        let loadedSweden = cacheService.loadRegions(country: Skredvarsel.Country.sweden)

        XCTAssertEqual(loadedNorway?[0].Name, "Norway Region")
        XCTAssertEqual(loadedSweden?[0].Name, "Sweden Region")
    }

    // MARK: - Helpers

    private func makeWarning(regionId: Int, dangerLevel: Skredvarsel.DangerLevel) -> Skredvarsel.AvalancheWarningDetailed {
        let now = Date()
        return Skredvarsel.AvalancheWarningDetailed(
            PreviousWarningRegId: nil,
            DangerLevelName: nil,
            UtmZone: 33,
            UtmEast: 0,
            UtmNorth: 0,
            Author: nil,
            AvalancheDanger: nil,
            EmergencyWarning: nil,
            SnowSurface: nil,
            CurrentWeaklayers: nil,
            LatestAvalancheActivity: nil,
            LatestObservations: nil,
            ExposedHeightFill: 0,
            ExposedHeight1: 0,
            AvalancheProblems: nil,
            AvalancheAdvices: nil,
            RegId: regionId,
            RegionId: regionId,
            RegionName: "Test Region",
            RegionTypeId: 10,
            RegionTypeName: "A",
            DangerLevel: dangerLevel,
            ValidFrom: now,
            ValidTo: Calendar.current.date(byAdding: .day, value: 1, to: now)!,
            NextWarningTime: Calendar.current.date(byAdding: .day, value: 1, to: now)!,
            PublishTime: now,
            MainText: "Test warning",
            LangKey: 1
        )
    }
}
