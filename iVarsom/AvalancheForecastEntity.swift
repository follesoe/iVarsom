import AppIntents
import Foundation

struct AvalancheForecastEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Avalanche forecast"
    static let defaultQuery = Query()
    let id: String
    private let regionID: Int

    @Property(title: "Region") var region: String
    @Property(title: "Forecast date") var forecastDate: Date
    @Property(title: "Danger level") var dangerLevel: Int?
    @Property(title: "Summary") var summary: String
    @Property(title: "Valid until") var validUntil: Date
    @Property(title: "Downloaded") var downloadedAt: Date
    @Property(title: "Saved forecast") var isCached: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(region)", subtitle: "\(ForecastSelection.dateText(forecastDate, regionID: regionID, style: .init(date: .abbreviated, time: .omitted)))")
    }

    /// - Parameter archiveDay: The day of a bulletin from the provider's archive.
    ///   Its ID adds the day, so the query can fetch it again; current
    ///   forecasts keep the `region|language|bulletin` format.
    init(warning: AvalancheWarningSimple, snapshot: ForecastSnapshot, isCached: Bool, archiveDay: Date? = nil) {
        regionID = warning.RegionId
        id = "\(warning.RegionId)|\(snapshot.language)|\(warning.RegId)"
            + (archiveDay.map { "|" + Self.dayFormat(regionID: warning.RegionId).format($0) } ?? "")
        region = warning.RegionName
        forecastDate = warning.ValidFrom
        dangerLevel = Int(warning.DangerLevel.rawValue).flatMap { (1...5).contains($0) ? $0 : nil }
        summary = warning.MainText
        validUntil = warning.ValidTo
        downloadedAt = snapshot.downloadedAt
        self.isCached = isCached
    }

    static func dayFormat(regionID: Int) -> Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle(timeZone: ForecastSelection.calendar(regionID: regionID).timeZone).year().month().day()
    }

    struct Query: EntityQuery {
        private let store: SharedForecastStore
        private let now: @Sendable () -> Date
        /// The repository for archive bulletins in a provider language.
        private let archive: @Sendable (VarsomApiClient.Language) -> any WarningRepositoryProviding

        init() {
            self.init(store: SharedForecastStore()) { language in WarningRepository(cache: nil, language: { language }) }
        }

        init(
            store: SharedForecastStore, now: @escaping @Sendable () -> Date = { Date.current },
            archive: @escaping @Sendable (VarsomApiClient.Language) -> any WarningRepositoryProviding
        ) {
            self.store = store
            self.now = now
            self.archive = archive
        }

        func entities(for identifiers: [String]) async throws -> [AvalancheForecastEntity] {
            let now = now()
            var entities: [AvalancheForecastEntity] = []
            for id in identifiers {
                let parts = id.split(separator: "|")
                if parts.count == 4, let entity = await archived(parts) {
                    entities.append(entity)
                    continue
                }
                guard parts.count == 3, let regionID = Int(parts[0]), let warningID = Int(parts[2]),
                      let snapshot = await store.load(regionID: regionID, language: String(parts[1]), now: now),
                      let warning = snapshot.warnings.first(where: {
                          $0.RegId == warningID && $0.validityEnd > now && $0.PublishTime <= now
                      }) else { continue }
                entities.append(AvalancheForecastEntity(warning: warning, snapshot: snapshot, isCached: true))
            }
            return entities
        }

        /// Fetches an archive bulletin again; nothing is stored for earlier days.
        private func archived(_ parts: [Substring]) async -> AvalancheForecastEntity? {
            guard let regionID = Int(parts[0]), let warningID = Int(parts[2]),
                let midnight = try? AvalancheForecastEntity.dayFormat(regionID: regionID).parse(String(parts[3]))
            else { return nil }
            let key = String(parts[1])
            // Language keys end in the provider language: 1 is the native bulletin.
            let language: VarsomApiClient.Language = key.hasSuffix("-1") ? .norwegian : .english
            let day = midnight.addingTimeInterval(12 * 3600)
            let now = now()
            guard let warnings = try? await archive(language).loadWarnings(on: day, regionID: regionID),
                let warning = warnings.first(where: { $0.RegId == warningID })
            else { return nil }
            let snapshot = ForecastSnapshot(
                regionID: regionID, language: key, requestStartedAt: now, downloadedAt: now, warnings: warnings)
            return AvalancheForecastEntity(warning: warning, snapshot: snapshot, isCached: false, archiveDay: day)
        }
    }
}
