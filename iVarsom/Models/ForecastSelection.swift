import AppIntents
import Foundation

enum ForecastDay: String, AppEnum, Codable, Sendable {
    case today, tomorrow

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Forecast day"
    static let caseDisplayRepresentations: [ForecastDay: DisplayRepresentation] = [
        .today: "Current forecast", .tomorrow: "Tomorrow"
    ]
}

enum ForecastSelection {
    static func calendar(regionID: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: Country.from(regionId: regionID) == .sweden
            ? "Europe/Stockholm" : "Europe/Oslo")!
        return calendar
    }

    /// A bulletin's day belongs to its region, even when the reader is abroad.
    static func dateText(_ date: Date, regionID: Int, style: Date.FormatStyle) -> String {
        var style = style
        style.calendar = calendar(regionID: regionID)
        style.timeZone = style.calendar.timeZone
        return style.format(date)
    }

    static func dayLabel(_ date: Date, regionID: Int, now: Date, locale: Locale = .current) -> String {
        let calendar = calendar(regionID: regionID)
        let offset = calendar.dateComponents([.day], from: calendar.startOfDay(for: now),
                                             to: calendar.startOfDay(for: date)).day!
        if (-1...1).contains(offset) {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = locale
            formatter.dateTimeStyle = .named
            formatter.unitsStyle = .short
            return formatter.localizedString(from: DateComponents(day: offset)).firstUppercased
        }
        return dateText(date, regionID: regionID, style: .dateTime.weekday(.wide).locale(locale)).firstUppercased
    }

    /// Shared snapshots can contain the app's longer history. Each widget entry
    /// has its own six-day display window, including when it advances at midnight.
    static func widgetWarnings(in warnings: [AvalancheWarningSimple], at date: Date, regionID: Int) -> [AvalancheWarningSimple] {
        let calendar = calendar(regionID: regionID)
        let today = calendar.startOfDay(for: date)
        let start = calendar.date(byAdding: .day, value: -3, to: today)!
        let end = calendar.date(byAdding: .day, value: 3, to: today)!
        return warnings.filter { $0.ValidFrom >= start && $0.ValidFrom < end && $0.PublishTime <= date }
            .sorted { $0.ValidFrom < $1.ValidFrom }
    }

    static func warning(in warnings: [AvalancheWarningSimple], day: ForecastDay, at date: Date) -> AvalancheWarningSimple? {
        warnings.filter { warning in
            guard warning.PublishTime <= date, warning.validityEnd > date else { return false }
            if day == .today { return warning.validityStart <= date }
            let calendar = calendar(regionID: warning.RegionId)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: date)!
            return calendar.isDate(warning.ValidFrom, inSameDayAs: tomorrow)
        }.max { $0.PublishTime < $1.PublishTime }
    }

    /// The latest published bulletin for a forecast day, such as a past date asked
    /// about in Siri. Days follow the region's calendar.
    static func warning(in warnings: [AvalancheWarningSimple], on day: Date, at now: Date) -> AvalancheWarningSimple? {
        warnings.filter { warning in
            warning.PublishTime <= now && calendar(regionID: warning.RegionId).isDate(warning.ValidFrom, inSameDayAs: day)
        }.max { $0.PublishTime < $1.PublishTime }
    }

    /// Schedule known transitions, including expiry, without relying on a
    /// network wake-up at midnight. WidgetKit still controls rendering cadence.
    static func transitionDates(in warnings: [AvalancheWarningSimple], after now: Date, regionID: Int) -> [Date] {
        let calendar = calendar(regionID: regionID)
        let horizon = calendar.date(byAdding: .day, value: 3, to: now)!
        var dates = warnings.flatMap { [$0.validityStart, $0.validityEnd, $0.PublishTime] }
        for day in 1...3 {
            dates.append(calendar.date(byAdding: .day, value: day, to: calendar.startOfDay(for: now))!)
        }
        return [now] + Set(dates.filter { $0 > now && $0 <= horizon }).sorted()
    }
}

struct ForecastTimeline {
    struct Entry {
        let date: Date
        let warning: AvalancheWarningSimple?
        let warnings: [AvalancheWarningSimple]
        let isCached: Bool
    }
    let entries: [Entry]
    let refreshAfter: Date

    init(loaded: LoadedForecast, day: ForecastDay, now: Date) {
        let snapshot = loaded.snapshot
        let nextRefresh = ForecastRefreshPolicy.nextRefresh(warnings: snapshot.warnings, downloadedAt: snapshot.downloadedAt)
        let dates = ForecastSelection.transitionDates(in: snapshot.warnings, after: now, regionID: snapshot.regionID)
        entries = Set(dates).sorted().map { date in
            Entry(date: date, warning: ForecastSelection.warning(in: snapshot.warnings, day: day, at: date),
                  warnings: ForecastSelection.widgetWarnings(in: snapshot.warnings, at: date, regionID: snapshot.regionID),
                  isCached: loaded.isCached)
        }
        let requested = loaded.isCached ? now.addingTimeInterval(ForecastRefreshPolicy.retryInterval) : nextRefresh
        refreshAfter = max(now.addingTimeInterval(60), requested)
    }
}
