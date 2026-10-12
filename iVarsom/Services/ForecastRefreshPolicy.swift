import Foundation

enum ForecastRefreshPolicy {
    static let maximumAge: TimeInterval = 4 * 60 * 60
    static let retryInterval: TimeInterval = 15 * 60

    static func nextRefresh(warnings: [AvalancheWarningSimple], downloadedAt: Date) -> Date {
        let regions = Dictionary(grouping: warnings, by: \.RegionId)
        if regions.count > 1 {
            return regions.values.map { nextRefresh(warnings: $0, downloadedAt: downloadedAt) }.min()!
        }
        guard let first = warnings.first else { return downloadedAt.addingTimeInterval(60 * 60) }
        let calendar = ForecastSelection.calendar(regionID: first.RegionId)
        let dayStart = calendar.startOfDay(for: downloadedAt)
        let published = warnings.filter { $0.PublishTime <= downloadedAt }
        let lastPublication = published.map(\.PublishTime).max() ?? .distantPast
        // Include the preceding bulletin: Varsom commonly puts today's expected
        // publication time in yesterday's NextWarningTime. Never infer a fixed
        // 16:00/18:00 schedule when the provider supplies an actual timestamp.
        let publication = warnings.map(\.NextWarningTime)
            .filter { deadline in
                guard deadline >= dayStart, deadline > lastPublication else { return false }
                // Providers normally publish shortly BEFORE their deadline.
                // A next-day bulletin published on the deadline's day already
                // satisfies it; don't poll every 15 minutes for an update we have.
                let publicationDay = calendar.startOfDay(for: deadline)
                let forecastDay = calendar.date(byAdding: .day, value: 1, to: publicationDay)!
                return !published.contains { $0.PublishTime >= publicationDay && $0.ValidFrom >= forecastDay }
            }.min()
        var candidates = [downloadedAt.addingTimeInterval(maximumAge)]
        if let publication {
            let lateRetry: TimeInterval = downloadedAt.timeIntervalSince(publication) < 60 * 60
                ? retryInterval : 60 * 60
            candidates.append(publication > downloadedAt
                ? publication.addingTimeInterval(60)
                : downloadedAt.addingTimeInterval(lateRetry))
        }
        if let expiry = warnings.map(\.validityEnd).filter({ $0 > downloadedAt }).min() {
            candidates.append(expiry)
        } else {
            candidates.append(downloadedAt.addingTimeInterval(60 * 60))
        }
        return candidates.min()!
    }
}
