import Foundation
import Observation

@MainActor
protocol FavoritesCloudStore: AnyObject {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
    @discardableResult func synchronize() -> Bool
}

extension NSUbiquitousKeyValueStore: FavoritesCloudStore {}

/// One observable source of favorites, shared by the app's windows.
@Observable
@MainActor
final class FavoritesService {
    private(set) var ids: [Int]
    private let key = "favoriteRegionIds"
    private let defaults: UserDefaults
    private let cloudStore: (any FavoritesCloudStore)?
    private let notifications: NotificationCenter
    @ObservationIgnored private var observer: (any NSObjectProtocol)?

    // Each caller gets Foundation's thread-safe defaults store without sharing
    // an unchecked Swift reference across actors. Widgets only read the snapshot.
    nonisolated static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: "group.no.follesoe.iVarsom") ?? .standard
    }

    nonisolated static func savedFavorites() -> [Int] {
        sharedDefaults.object(forKey: "favoriteRegionIds") as? [Int] ?? []
    }

    init(defaults: UserDefaults = sharedDefaults,
         cloudStore: (any FavoritesCloudStore)? = NSUbiquitousKeyValueStore.default,
         notifications: NotificationCenter = .default,
         migrateLegacyDefaults: Bool = true) {
        self.defaults = defaults
        self.cloudStore = cloudStore
        self.notifications = notifications
        if migrateLegacyDefaults, defaults.object(forKey: key) == nil,
           let existing = UserDefaults.standard.object(forKey: key) as? [Int] {
            defaults.set(existing, forKey: key)
        }
        ids = defaults.object(forKey: key) as? [Int] ?? []
        cloudStore?.synchronize()
        syncFromCloud()
        if let cloudStore {
            observer = notifications.addObserver(
                forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
                object: cloudStore, queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in self?.syncFromCloud() }
            }
        }
    }

    isolated deinit {
        if let observer { notifications.removeObserver(observer) }
    }

    func addFavorite(_ id: Int) {
        guard !ids.contains(id) else { return }
        save(ids + [id])
    }

    func removeFavorite(_ id: Int) {
        save(ids.filter { $0 != id })
    }

    /// Cloud snapshots include removals. Unioning them with local values would
    /// resurrect deleted favorites every time another device synchronizes.
    func syncFromCloud() {
        guard let cloudIDs = cloudStore?.object(forKey: key) as? [Int] else { return }
        ids = Self.unique(cloudIDs)
        defaults.set(ids, forKey: key)
    }

    private func save(_ values: [Int]) {
        ids = Self.unique(values)
        defaults.set(ids, forKey: key)
        cloudStore?.set(ids, forKey: key)
        cloudStore?.synchronize()
    }

    private static func unique(_ values: [Int]) -> [Int] {
        var seen = Set<Int>()
        return values.filter { seen.insert($0).inserted }
    }
}
