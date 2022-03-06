import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static let varsomDate = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)
        if let date = Formatter.varsomDateWithFractionalSeconds.date(from: string) ?? Formatter.varsomDate.date(from: string) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(string)")
    }
}
