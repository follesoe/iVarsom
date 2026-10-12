import Foundation
import Testing
import UIKit

@testable import Skredvarsel

@MainActor
struct PresentationTests {
    @Test func widgetAccessibilityRetainsForecastEmergencyAndFreshness() {
        var warning = Fixtures.warning().summary
        warning.MainText = "Avoid steep slopes with wind-drifted snow."
        warning.EmergencyWarning = "Large natural avalanches are expected."
        let label = warning.accessibilitySummary(downloadedAt: Fixtures.date, isCached: true)
        #expect(label.contains(warning.RegionName))
        #expect(label.contains(warning.DangerLevel.localizedName))
        #expect(label.contains(warning.MainText))
        #expect(label.contains(warning.EmergencyWarning!))
        #expect(label.contains(String(localized: "Saved forecast")))
        #expect(label.contains(String(localized: "Downloaded")))
        #expect(label.contains(Fixtures.date.formatted(date: .abbreviated, time: .shortened)))
    }

    @Test(arguments: [nil, "", "Not given", "Ikke gitt"] as [String?])
    func widgetAccessibilitySkipsInactiveEmergencyText(emergency: String?) {
        var warning = Fixtures.warning().summary
        let withoutEmergency = warning.accessibilitySummary(downloadedAt: nil, isCached: false)
        warning.EmergencyWarning = emergency
        #expect(warning.accessibilitySummary(downloadedAt: nil, isCached: false) == withoutEmergency)
        #expect(withoutEmergency.contains(warning.MainText))
        #expect(!withoutEmergency.contains(String(localized: "Saved forecast")))
    }

    @Test func translationSelectionTracksRevisionsOfSameWarning() {
        let model = WarningTranslationModel()
        var warning = Fixtures.warning()
        model.select(warning)
        model.toggle()
        #expect(model.isTranslating)
        warning.PublishTime = warning.PublishTime.addingTimeInterval(60)
        model.select(warning)
        #expect(!model.isTranslating)
        #expect(model.configuration == nil)
        #expect(model.texts.isEmpty)
    }

    @Test func retryInvalidatesExistingTranslationConfiguration() {
        let model = WarningTranslationModel()
        model.select(Fixtures.warning())
        model.toggle()
        let initial = model.configuration
        model.toggle()
        #expect(model.configuration != initial)
    }

    @Test func translationIncludesEmergencyAndSkipsEmptyOptionalText() {
        var warning = Fixtures.warning()
        warning.EmergencyWarning = "Emergency"
        warning.AvalancheDanger = ""
        #expect(WarningTranslationModel.sourceTexts(for: warning) == [warning.MainText, "Emergency"])
    }

    @Test func regionNamesWithSlashesRemainSingleExportFiles() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { _ in }
        let item = try #require(ShareImage(image: image, filename: "Abisko/Riksgränsfjällen.png"))
        #expect(item.url.lastPathComponent == "Abisko-Riksgränsfjällen.png")
        #expect(FileManager.default.fileExists(atPath: item.url.path))
    }

    @Test func shareExportsDoNotCollideAndAreRemovedWhenReleased() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
        var first = ShareImage(image: image, filename: "forecast.png")
        let second = try #require(ShareImage(image: image, filename: "forecast.png"))
        let url = try #require(first?.url)
        #expect(url != second.url)
        #expect(FileManager.default.fileExists(atPath: url.path))
        first = nil
        #expect(!FileManager.default.fileExists(atPath: url.path))
        #expect(FileManager.default.fileExists(atPath: second.url.path))
    }
}
