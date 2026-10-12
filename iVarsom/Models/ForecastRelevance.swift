import Foundation

enum ForecastRelevance {
    /// Morning suggestions only cover an actual, published, unexpired bulletin.
    /// Dates are in the forecast region's time zone, including DST transitions.
    static func morningWindows(snapshot: ForecastSnapshot, now: Date) -> [DateInterval] {
        let calendar = ForecastSelection.calendar(regionID: snapshot.regionID)
        return (0...2).compactMap { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: now)!
            let morning = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: day)!
            let end = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: day)!
            guard let warning = ForecastSelection.warning(in: snapshot.warnings, day: .today, at: max(now, morning)),
                  warning.PublishTime <= now else { return nil }
            let start = max(now, morning, warning.validityStart)
            // Revalidation is a download opportunity, not bulletin expiry. A
            // published evening forecast can already support tomorrow's morning.
            let finish = min(end, warning.validityEnd)
            return start < finish ? DateInterval(start: start, end: finish) : nil
        }
    }
}
