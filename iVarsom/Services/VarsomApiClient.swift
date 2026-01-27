import SwiftUI
import CoreLocation

private protocol UniqueRegIdSettable {
    var RegId: Int { get set }
    var RegionId: Int { get }
}

extension AvalancheWarningSimple: UniqueRegIdSettable {}
extension AvalancheWarningDetailed: UniqueRegIdSettable {}

@MainActor
class VarsomApiClient {

    public static func currentLang() -> Language {
        let identifier = Locale.current.identifier;
        return identifier.starts(with: "nb") ? .norwegian : .english
    }

    public enum Language: CustomStringConvertible {
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
    }

    private let baseUrl = "https://api01.nve.no/hydrology/forecast/avalanche/v6.3.0/api"
    private let argumentDateFormatter:DateFormatter

    init() {
        argumentDateFormatter = DateFormatter()
        argumentDateFormatter.dateFormat = "yyyy-MM-dd"
    }

    public func loadRegions(lang: Language) async throws -> [RegionSummary] {
        let from = Date.current
        let fromArg = argumentDateFormatter.string(from: from)
        guard let url = URL(string: "\(baseUrl)/RegionSummary/Simple/\(lang)/\(fromArg)") else { throw VarsomError.invalidUrlError }
        var regions: [RegionSummary] = try await getData(url: url);

        for (index, region) in regions.enumerated() {
            regions[index].AvalancheWarningList = setUniqueRegId(warnings: region.AvalancheWarningList)
        }

        return regions
    }

    public func loadRegions(lang: Language, coordinate: CLLocationCoordinate2D) async throws -> RegionSummary {
        let from = Date.current
        let to = Calendar.current.date(byAdding: .day, value: 2, to: from)!
        let warnings = try await loadWarnings(lang: lang, coordinate: coordinate, from: from, to: to)
        let region = RegionSummary(
            Id: warnings[0].RegionId,
            Name: warnings[0].RegionName,
            TypeName: warnings[0].RegionTypeName,
            AvalancheWarningList: warnings)
        return region
    }

    public func loadWarnings(lang: Language, regionId: Int, from: Date, to: Date) async throws -> [AvalancheWarningSimple] {
        let fromArg = argumentDateFormatter.string(from: from)
        let toArg = argumentDateFormatter.string(from: to)
        guard let url = URL(string: "\(baseUrl)/AvalancheWarningByRegion/Simple/\(regionId)/\(lang)/\(fromArg)/\(toArg)") else { throw VarsomError.invalidUrlError }
        let warnings: [AvalancheWarningSimple] = try await getData(url: url)
        return setUniqueRegId(warnings: warnings)
    }

    public func loadWarnings(lang: Language, coordinate: CLLocationCoordinate2D, from: Date, to: Date) async throws -> [AvalancheWarningSimple] {
        let fromArg = argumentDateFormatter.string(from: from)
        let toArg = argumentDateFormatter.string(from: to)
        guard let url = URL(string: "\(baseUrl)/AvalancheWarningByCoordinates/Simple/\(coordinate.latitude)/\(coordinate.longitude)/\(lang)/\(fromArg)/\(toArg)") else { throw VarsomError.invalidUrlError }
        let warnings: [AvalancheWarningSimple] = try await getData(url: url)
        return setUniqueRegId(warnings: warnings)
    }

    public func loadWarningsDetailed(lang: Language, regionId: Int, from: Date, to: Date) async throws -> [AvalancheWarningDetailed] {
        let fromArg = argumentDateFormatter.string(from: from)
        let toArg = argumentDateFormatter.string(from: to)
        guard let url = URL(string: "\(baseUrl)/AvalancheWarningByRegion/Detail/\(regionId)/\(lang)/\(fromArg)/\(toArg)") else { throw VarsomError.invalidUrlError }
        let warnings: [AvalancheWarningDetailed] = try await getData(url: url)
        return setUniqueRegId(warnings: warnings)
    }

    private func setUniqueRegId<T: UniqueRegIdSettable>(warnings: [T]) -> [T] {
        // Ensure no duplicate RegId as regions without assessment generates
        // multiple warnings with RegId = 0, which causes problems with duplicate Identifiable id.
        var array = warnings
        for (index, warning) in array.enumerated() {
            if (warning.RegId == 0) {
                array[index].RegId = warning.RegionId + (index + 1)
            }
        }
        return array
    }

    private func getData<T>(url: URL) async throws -> T where T : Codable {
        let (data, response) = try await URLSession.shared.data(from: url)

        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw VarsomError.requestError }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy =  .varsomDate
        return try decoder.decode(T.self, from: data)
    }
}
