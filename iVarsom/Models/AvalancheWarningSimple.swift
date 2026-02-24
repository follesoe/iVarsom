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

    var hasActiveEmergencyWarning: Bool {
        guard let warning = EmergencyWarning, !warning.isEmpty else { return false }
        return warning != "Not given" && warning != "Ikke gitt"
    }
}
