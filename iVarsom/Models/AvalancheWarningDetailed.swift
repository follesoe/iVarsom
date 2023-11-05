import Foundation
import SwiftUI

struct AvalancheWarningDetailed: Codable, AvalancheWarningProtocol {
    var PreviousWarningRegId: Int
    var DangerLevelName: String
    var UtmZone: Int
    var UtmEast: Int
    var UtmNorth: Int
    var Author: String
    var AvalancheDanger: String
    var EmergencyWarning: String
    var SnowSurface: String
    var CurrentWeaklayers: String
    var LatestAvalancheActivity: String?
    var LatestObservations: String?
    var ExposedHeightFill: Int
    var ExposedHeight1: Int
    var AvalancheProblems: [AvalancheProblem]
    var AvalancheAdvices: [AvalancheAdvice]
    var RegId: Int
    var RegionId: Int
    var RegionName: String
    var RegionTypeId: Int
    var RegionTypeName: String
    var DangerLevel: DangerLevel
    var ValidFrom: Date
    var ValidTo: Date
    var NextWarningTime: Date
    var PublishTime: Date
    var MainText: String
    var LangKey: Int
}
