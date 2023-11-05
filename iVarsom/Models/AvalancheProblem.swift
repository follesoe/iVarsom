import Foundation

typealias DangerLevelEnumType = DangerLevel

struct AvalancheProblem: Codable {
    var AvalancheProblemId: Int
    var AvalancheExtId: Int
    var AvalancheExtName: String
    var AvalCauseId: Int
    var AvalCauseName: String
    var AvalProbabilityId: Int
    var AvalProbabilityName: String
    var AvalTriggerSimpleId: Int
    var AvalTriggerSimpleName: String
    var AvalTriggerSensitivityId: Int
    var AvalTriggerSensitivityName: String
    var DestructiveSizeExtId: Int
    var DestructiveSizeExtName: String
    var AvalPropagationId: Int
    var AvalPropagationName: String
    var AvalancheTypeId: Int
    var AvalancheTypeName: String
    var AvalancheProblemTypeId: Int
    var AvalancheProblemTypeName: String
    var ValidExpositions: String
    var ExposedHeight1: Int
    var ExposedHeight2: Int
    var ExposedHeightFill: Int
    var TriggerSenitivityPropagationDestuctiveSizeText: String
    var DangerLevel: Int
    var DangerLevelName: String
    var DangerLevelEnum: DangerLevelEnumType {
        return DangerLevelEnumType(rawValue: String(DangerLevel)) ?? .unknown
    }
}

extension AvalancheProblem: Identifiable {
    var id: Int { AvalancheProblemId }
}
