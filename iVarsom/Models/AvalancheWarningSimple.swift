import Foundation
import SwiftUI

struct AvalancheWarningSimple: Codable, Sendable, AvalancheWarningProtocol {
    var RegId: Int
    var RegionId: Int
    var RegionName: String
    var RegionTypeName: String
    var ValidFrom: Date
    var ValidTo: Date
    var NextWarningTime: Date
    var PublishTime: Date
    var DangerLevel: DangerLevel
    var MainText: String
    var LangKey: Int
    var EmergencyWarning: String?
    /// Actual interval start when the provider's display day differs (Sweden).
    var BulletinValidFrom: Date?

    var hasActiveEmergencyWarning: Bool {
        guard let warning = EmergencyWarning, !warning.isEmpty else { return false }
        return warning != "Not given" && warning != "Ikke gitt"
    }

    /// Widgets expose a single accessibility element, so its label must retain
    /// the provider's guidance and emergency text as well as the danger level.
    func accessibilitySummary(downloadedAt: Date?, isCached: Bool) -> String {
        var text = "\(RegionName). \(DangerLevel.description), \(DangerLevel.localizedName). \(formattedForecastDate(.init(date: .abbreviated, time: .omitted)))."
        if hasActiveEmergencyWarning, let EmergencyWarning { text += " \(EmergencyWarning)" }
        if !MainText.isEmpty { text += " \(MainText)" }
        if isCached { text += " \(String(localized: "Saved forecast"))" }
        if let downloadedAt { text += " \(String(localized: "Downloaded")) \(downloadedAt.formatted(date: .abbreviated, time: .shortened))." }
        return text
    }
}
