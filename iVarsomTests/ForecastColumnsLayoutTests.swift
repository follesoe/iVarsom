import CoreGraphics
import Testing

@testable import Skredvarsel

/// The forecast's reading and avalanche problem columns.
struct ForecastColumnsLayoutTests {
    private let layout = ForecastColumnsLayout(division: nil, minimumColumnWidth: 340, gap: 16)

    @Test(arguments: [375.0, 466, 669, 695])
    func stacksWhenColumnsWouldBeTooNarrow(width: CGFloat) {
        #expect(layout.columns(width: width) == nil)
    }

    @Test func splitsEvenlyWithoutFold() throws {
        let columns = try #require(layout.columns(width: 1000))
        #expect(columns.leadingWidth == 492)
        #expect(columns.trailingStart == 508)
    }

    @Test func gapSitsOnFold() throws {
        var layout = layout
        // iPhone Duo in book pose, with the fold's interactive margins.
        layout.division = ColumnDivision(center: 480, width: 44)
        let columns = try #require(layout.columns(width: 951))
        #expect(columns.leadingWidth == 458)
        #expect(columns.trailingStart == 502)
    }

    @Test func flatFoldKeepsColumnsInPlaceWithMinimumGap() throws {
        var layout = layout
        layout.division = ColumnDivision(center: 475, width: 0)
        let columns = try #require(layout.columns(width: 951))
        #expect(columns.leadingWidth == 467)
        #expect(columns.trailingStart == 483)
    }

    @Test func foldNearEdgeFallsBackToEvenSplit() throws {
        var layout = layout
        layout.division = ColumnDivision(center: 200, width: 20)
        let columns = try #require(layout.columns(width: 1000))
        #expect(columns.leadingWidth == 492)
    }

    @Test func infiniteWidthStacks() {
        #expect(layout.columns(width: .infinity) == nil)
    }
}
