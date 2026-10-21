import CoreLocation
import Foundation

private protocol UniqueRegIdSettable {
    var RegId: Int { get set }
    var RegionId: Int { get }
}

extension AvalancheWarningSimple: UniqueRegIdSettable {}
extension AvalancheWarningDetailed: UniqueRegIdSettable {}

/// The transport is injectable so API tests never depend on live avalanche forecasts.
protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionTransport: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await URLSession.shared.data(for: request)
    }
}

protocol VarsomAPIProviding: Sendable {
    func loadRegions(lang: VarsomApiClient.Language) async throws -> [RegionSummary]
    func loadWarnings(lang: VarsomApiClient.Language, regionId: Int, from: Date, to: Date) async throws
        -> [AvalancheWarningSimple]
    func loadWarningsDetailed(lang: VarsomApiClient.Language, regionId: Int, from: Date, to: Date) async throws
        -> [AvalancheWarningDetailed]
}

actor VarsomApiClient: VarsomAPIProviding {

    public nonisolated static func currentLang() -> Language {
        let identifier = Locale.current.identifier
        if identifier.starts(with: "nb") || identifier.starts(with: "sv") {
            return .norwegian
        }
        return .english
    }

    /// The bulletin language for a person's locale, such as the language of a
    /// Siri request: the native-language bulletin (Norwegian for Norway, Swedish
    /// for Sweden) for Norwegian or Swedish speakers, otherwise English.
    public nonisolated static func language(for locale: Locale) -> Language {
        switch locale.language.languageCode?.identifier {
        case "nb", "no", "sv": .norwegian
        default: .english
        }
    }

    public enum Language: Sendable, CustomStringConvertible {
        case norwegian
        case english

        var description: String {
            switch self {
            case .norwegian: return "1"
            case .english: return "2"
            }
        }
    }

    public enum VarsomError: Error {
        case requestError
        case invalidUrlError
        case noWarnings
    }

    private let baseUrl = "https://api01.nve.no/hydrology/forecast/avalanche/v6.3.0/api"
    private let argumentDateFormatter: DateFormatter

    private let now: @Sendable () -> Date
    private let transport: any HTTPTransport

    init(transport: any HTTPTransport = URLSessionTransport(), now: @escaping @Sendable () -> Date = { Date.current }) {
        self.now = now
        self.transport = transport
        argumentDateFormatter = DateFormatter()
        argumentDateFormatter.locale = Locale(identifier: "en_US_POSIX")
        argumentDateFormatter.calendar = Calendar(identifier: .gregorian)
        argumentDateFormatter.dateFormat = "yyyy-MM-dd"
        argumentDateFormatter.timeZone = TimeZone(identifier: "Europe/Oslo")
    }

    public func loadRegions(lang: Language) async throws -> [RegionSummary] {
        let from = now()
        let fromArg = argumentDateFormatter.string(from: from)
        guard let url = URL(string: "\(baseUrl)/RegionSummary/Simple/\(lang)/\(fromArg)") else {
            throw VarsomError.invalidUrlError
        }
        var regions: [RegionSummary] = try await getData(url: url)

        for (index, region) in regions.enumerated() {
            regions[index].AvalancheWarningList = setUniqueRegId(warnings: region.AvalancheWarningList)
        }

        return regions
    }

    public func loadRegions(lang: Language, coordinate: CLLocationCoordinate2D) async throws -> RegionSummary {
        let from = now()
        let to = Calendar.current.date(byAdding: .day, value: 2, to: from)!
        let warnings = try await loadWarnings(lang: lang, coordinate: coordinate, from: from, to: to)
        guard let warning = warnings.first else { throw VarsomError.noWarnings }
        let region = RegionSummary(
            Id: warning.RegionId,
            Name: warning.RegionName,
            TypeName: warning.RegionTypeName,
            AvalancheWarningList: warnings)
        return region
    }

    public func loadWarnings(lang: Language, regionId: Int, from: Date, to: Date) async throws
        -> [AvalancheWarningSimple]
    {
        let fromArg = argumentDateFormatter.string(from: from)
        let toArg = argumentDateFormatter.string(from: to)
        guard
            let url = URL(string: "\(baseUrl)/AvalancheWarningByRegion/Simple/\(regionId)/\(lang)/\(fromArg)/\(toArg)")
        else { throw VarsomError.invalidUrlError }
        let warnings: [AvalancheWarningSimple] = try await getData(url: url)
        return setUniqueRegId(warnings: warnings)
    }

    public func loadWarnings(lang: Language, coordinate: CLLocationCoordinate2D, from: Date, to: Date) async throws
        -> [AvalancheWarningSimple]
    {
        let fromArg = argumentDateFormatter.string(from: from)
        let toArg = argumentDateFormatter.string(from: to)
        guard
            let url = URL(
                string:
                    "\(baseUrl)/AvalancheWarningByCoordinates/Simple/\(coordinate.latitude)/\(coordinate.longitude)/\(lang)/\(fromArg)/\(toArg)"
            )
        else { throw VarsomError.invalidUrlError }
        let warnings: [AvalancheWarningSimple] = try await getData(url: url)
        return setUniqueRegId(warnings: warnings)
    }

    public func loadWarningsDetailed(lang: Language, regionId: Int, from: Date, to: Date) async throws
        -> [AvalancheWarningDetailed]
    {
        let fromArg = argumentDateFormatter.string(from: from)
        let toArg = argumentDateFormatter.string(from: to)
        guard
            let url = URL(string: "\(baseUrl)/AvalancheWarningByRegion/Detail/\(regionId)/\(lang)/\(fromArg)/\(toArg)")
        else { throw VarsomError.invalidUrlError }
        let warnings: [AvalancheWarningDetailed] = try await getData(url: url)
        return setUniqueRegId(warnings: warnings)
    }

    private func setUniqueRegId<T: UniqueRegIdSettable>(warnings: [T]) -> [T] {
        // Ensure no duplicate RegId as regions without assessment generates
        // multiple warnings with RegId = 0, which causes problems with duplicate Identifiable id.
        var array = warnings
        var usedIDs = Set(warnings.map(\.RegId))
        for (index, warning) in array.enumerated() {
            if warning.RegId == 0 {
                var nextID = warning.RegionId + index + 1
                while usedIDs.contains(nextID) { nextID += 1 }
                array[index].RegId = nextID
                usedIDs.insert(nextID)
            }
        }
        return array
    }

    private func getData<T>(url: URL) async throws -> T where T: Codable {
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await transport.data(for: request)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw VarsomError.requestError }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .varsomAPIDate
        return try decoder.decode(T.self, from: data)
    }
}
