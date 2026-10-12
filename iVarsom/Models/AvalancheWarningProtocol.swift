import Foundation

protocol AvalancheWarningProtocol: Identifiable {
    var RegId: Int { get set }
    var RegionId: Int { get }
    var RegionName: String { get }
    var RegionTypeName: String { get }
    var ValidFrom: Date { get }
    var ValidTo: Date { get }
    var BulletinValidFrom: Date? { get }
    var PublishTime: Date { get }
    var DangerLevel: DangerLevel { get }
    var MainText: String { get }
    var LangKey: Int { get }
}

extension AvalancheWarningProtocol {
    var id: Int { RegId }
    var validityStart: Date { BulletinValidFrom ?? ValidFrom }

    /// Varsom includes the final second of the regional day. Represent that as
    /// an exclusive midnight boundary, matching Sweden's exclusive validity end.
    var validityEnd: Date {
        guard Country.from(regionId: RegionId) == .norway else { return ValidTo }
        let calendar = ForecastSelection.calendar(regionID: RegionId)
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: ValidTo))!
        return midnight.timeIntervalSince(ValidTo) == 1 ? midnight : ValidTo
    }

    func formattedForecastDate(_ style: Date.FormatStyle) -> String {
        ForecastSelection.dateText(ValidFrom, regionID: RegionId, style: style)
    }

    var forecastDateIdentifier: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = ForecastSelection.calendar(regionID: RegionId)
        formatter.timeZone = formatter.calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: ValidFrom)
    }

    var VarsomUrl: URL {
        if Country.from(regionId: RegionId) == .sweden {
            let slug = Country.swedishSlug(for: RegionId) ?? ""
            let dateParam = forecastDateIdentifier
            if Locale.current.identifier.starts(with: "nb") || Locale.current.identifier.starts(with: "sv") {
                return URL(string: "https://lavinprognoser.se/oversikt-alla-omraden/\(slug)/?forecast_date=\(dateParam)")!
            } else {
                return URL(string: "https://lavinprognoser.se/en/oversikt-alla-omraden/\(slug)/?forecast_date=\(dateParam)")!
            }
        }

        let warningDate = forecastDateIdentifier
        let encodedName = RegionName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        if (Locale.current.identifier.starts(with: "nb") || Locale.current.identifier.starts(with: "sv")) {
            return URL(string: "https://varsom.no/snoskredvarsling/varsel/\(encodedName)/\(warningDate)")!
        } else {
            return URL(string: "https://varsom.no/en/avalanche-bulletins/forecast/\(encodedName)/\(warningDate)")!
        }
    }
    var DangerLevelNumeric: Float {
        return Float(DangerLevel.rawValue) ?? 0
    }
    
    /// Language code for the warning text based on LangKey.
    /// LangKey: 1=Norwegian, 2=English, 3=Swedish.
    var textLanguageCode: String {
        switch LangKey {
        case 1: return "nb"
        case 3: return "sv"
        default: return "en"
        }
    }

    var DangerLevelName: String {
        switch DangerLevel {
        case .unknown: return "Not assessed"
        case .level1: return "Low"
        case .level2: return "Moderate"
        case .level3: return "Considerable"
        case .level4: return "High"
        case .level5: return "Very high"
        }
    }
}


extension Array where Element: AvalancheWarningProtocol {
    /// Detail screens prefer the currently valid bulletin (including Sweden's
    /// evening changeover), then retain historical navigation when none is valid.
    func currentWarningIndex(on date: Date, calendar: Calendar = .current) -> Index? {
        indices.filter { self[$0].validityStart <= date && self[$0].validityEnd > date && self[$0].PublishTime <= date }
            .max { self[$0].PublishTime < self[$1].PublishTime }
            ?? firstIndex { calendar.isDate($0.ValidFrom, inSameDayAs: date) }
            ?? indices.max { self[$0].ValidFrom < self[$1].ValidFrom }
    }
}
