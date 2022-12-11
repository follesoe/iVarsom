import SwiftUI
import CoreLocation

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
    
    private let baseUrl = "https://api01.nve.no/hydrology/forecast/avalanche/v6.0.1/api"
    private let argumentDateFormatter:DateFormatter
    
    init() {
        argumentDateFormatter = DateFormatter()
        argumentDateFormatter.dateFormat = "yyyy-MM-dd"
    }
    
    public func loadRegions(lang: Language) async throws -> [RegionSummary] {
        guard let url = URL(string: "\(baseUrl)/RegionSummary/Simple/\(lang)/") else { throw VarsomError.invalidUrlError }
        return try await getData(url: url);
    }
    
    public func loadRegions(lang: Language, coordinate:CLLocationCoordinate2D) async throws -> RegionSummary {
        let from = Date()
        let to = Calendar.current.date(byAdding: .day, value: 2, to: from)!
        let warnings = try await loadWarnings(lang: lang, coordinate: coordinate, from: from, to: to)
        let region = RegionSummary(
            Id: warnings[0].RegionId,
            Name: warnings[0].RegionName,
            TypeName: warnings[0].RegionTypeName,
            AvalancheWarningList: warnings)
        return region
    }
    
    public func loadWarnings(lang: Language, regionId: Int, from:Date, to:Date) async throws -> [AvalancheWarningSimple] {
        let fromArg = argumentDateFormatter.string(from: from)
        let toArg = argumentDateFormatter.string(from: to)
        guard let url = URL(string: "\(baseUrl)/AvalancheWarningByRegion/Simple/\(regionId)/\(lang)/\(fromArg)/\(toArg)") else { throw VarsomError.invalidUrlError }
        return try await getData(url: url);
    }
    
    public func loadWarnings(lang: Language, coordinate:CLLocationCoordinate2D, from:Date, to:Date) async throws -> [AvalancheWarningSimple] {
        let fromArg = argumentDateFormatter.string(from: from)
        let toArg = argumentDateFormatter.string(from: to)
        guard let url = URL(string: "\(baseUrl)/AvalancheWarningByCoordinates/Simple/\(coordinate.latitude)/\(coordinate.longitude)/\(lang)/\(fromArg)/\(toArg)") else { throw VarsomError.invalidUrlError }
        return try await getData(url: url);
    }
    
    private func getData<T>(url: URL) async throws -> T where T : Codable {
        print(url.absoluteString)
        // try await Task.sleep(nanoseconds: 4_000_000_000)
        // throw VarsomError.requestError

        let (data, response) = try await URLSession.shared.data(from: url)
                
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw VarsomError.requestError }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy =  .varsomDate
        return try decoder.decode(T.self, from: data)
    }
}
