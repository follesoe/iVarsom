import Foundation

struct AvalancheAdvice: Sendable, Codable {
    var AdviceID: Int
    var ImageUrl: String
    var Text: String
}

extension AvalancheAdvice: Identifiable {
    var id: Int { AdviceID }
}
