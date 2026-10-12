import Foundation
import WidgetKit

/// A provider snapshot, shared with extensions. Download time and bulletin
/// validity are separate: successfully reading a file does not refresh a forecast.
struct ForecastSnapshot: Codable, Sendable {
    let regionID: Int
    let language: String
    let requestStartedAt: Date
    let downloadedAt: Date
    let warnings: [AvalancheWarningSimple]
}

actor SharedForecastStore {
    private let directory: URL?
    private let reloadWidgets: Bool
    private let now: @Sendable () -> Date

    init(directory: URL? = nil, reloadWidgets: Bool = false, now: @escaping @Sendable () -> Date = { .current }) {
        self.directory = directory ?? FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.no.follesoe.iVarsom")?
            .appendingPathComponent("Library/Caches/Forecasts-v1", isDirectory: true)
        self.reloadWidgets = reloadWidgets
        self.now = now
    }

    static func languageKey(regionID: Int, language: VarsomApiClient.Language) -> String {
        // Both providers offer English and a native-language bulletin.
        "\(Country.from(regionId: regionID) == .sweden ? "sweden" : "norway")-\(language.description)"
    }

    func load(regionID: Int, language: String, now: Date) -> ForecastSnapshot? {
        guard let url = fileURL(regionID: regionID, language: language),
              let snapshot = read(url), snapshot.regionID == regionID,
              snapshot.language == language, snapshot.downloadedAt <= now,
              snapshot.requestStartedAt <= snapshot.downloadedAt else { return nil }
        return snapshot
    }

    /// Coordination protects read/compare/write across the app and widget
    /// processes; atomic writes alone would still allow an older request to win.
    @discardableResult
    func save(_ snapshot: ForecastSnapshot) -> ForecastSnapshot {
        guard let directory,
              let url = fileURL(regionID: snapshot.regionID, language: snapshot.language),
              snapshot.requestStartedAt <= snapshot.downloadedAt else { return snapshot }
        var accepted = snapshot
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            var saved = false
            let coordinator = NSFileCoordinator()
            coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: nil) { coordinatedURL in
                // Read the clock after acquiring coordination: completion times
                // can predate another request whose save reached disk first.
                if let previous = read(coordinatedURL), previous.requestStartedAt > snapshot.requestStartedAt,
                   previous.requestStartedAt <= previous.downloadedAt, previous.downloadedAt <= now() {
                    accepted = previous
                    return
                }
                if let data = try? JSONEncoder().encode(snapshot),
                   (try? data.write(to: coordinatedURL, options: .atomic)) != nil {
                    saved = true
                }
            }
            if saved && reloadWidgets {
                WidgetCenter.shared.reloadTimelines(ofKind: "iVarsomWidget")
            }
        } catch {
            // Storage is best-effort; never turn a successful download into an error.
        }
        return accepted
    }

    private func fileURL(regionID: Int, language: String) -> URL? {
        guard language.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" }) else { return nil }
        return directory?.appendingPathComponent("\(regionID)-\(language).json")
    }

    private func read(_ url: URL) -> ForecastSnapshot? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(ForecastSnapshot.self, from: data)
    }
}
