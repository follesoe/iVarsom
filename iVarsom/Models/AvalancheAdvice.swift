import Foundation

struct AvalancheAdvice: Codable {
    var AdviceID: Int
    var ImageUrl: String
    var Text: String
}

extension AvalancheAdvice: Identifiable {
    var id: Int { AdviceID }
}
