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

    init(warning: AvalancheWarningSimple, snapshot: ForecastSnapshot, isCached: Bool) {
        regionID = warning.RegionId
        id = "\(warning.RegionId)|\(snapshot.language)|\(warning.RegId)"
        region = warning.RegionName
        forecastDate = warning.ValidFrom
        dangerLevel = Int(warning.DangerLevel.rawValue).flatMap { (1...5).contains($0) ? $0 : nil }
        summary = warning.MainText
        validUntil = warning.ValidTo
        downloadedAt = snapshot.downloadedAt
        self.isCached = isCached
    }

    struct Query: EntityQuery {
        func entities(for identifiers: [String]) async throws -> [AvalancheForecastEntity] {
            let store = SharedForecastStore()
            var entities: [AvalancheForecastEntity] = []
            for id in identifiers {
                let parts = id.split(separator: "|")
                guard parts.count == 3, let regionID = Int(parts[0]), let warningID = Int(parts[2]),
                      let snapshot = await store.load(regionID: regionID, language: String(parts[1]), now: Date.current),
                      let warning = snapshot.warnings.first(where: {
                          $0.RegId == warningID && $0.validityEnd > Date.current && $0.PublishTime <= Date.current
                      }) else { continue }
                entities.append(AvalancheForecastEntity(warning: warning, snapshot: snapshot, isCached: true))
            }
            return entities
        }
    }
}
