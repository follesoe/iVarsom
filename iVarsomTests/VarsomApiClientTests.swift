import XCTest
@testable import Skredvarsel

class VarsomApiClientTests: XCTestCase {
    
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testLoadRegions() async throws {
        let client = VarsomApiClient()
        let regions = try await client.loadRegions(lang: .english)
        XCTAssertGreaterThan(regions.count, 0)
    }
    
    func testLoadWarnings() async throws {
        let client = VarsomApiClient()
        let from = Calendar.current.date(byAdding: .day, value: -5, to: Date.now())!
        let to = Calendar.current.date(byAdding: .day, value: 2, to: Date.now())!
        
        let warnings = try await client.loadWarnings(
            lang: .english,
            regionId: RegionOption.defaultOption.id,
            from: from,
            to: to)
        XCTAssertGreaterThan(warnings.count, 0)
    }
}
