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
}
