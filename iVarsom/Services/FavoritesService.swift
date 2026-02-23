import Foundation

class FavoritesService: @unchecked Sendable {
    private let key = "favoriteRegionIds"
    private let defaults: UserDefaults
    private let cloudStore: NSUbiquitousKeyValueStore

    nonisolated(unsafe) static let sharedDefaults: UserDefaults = {
        let shared = UserDefaults(suiteName: "group.no.follesoe.iVarsom") ?? .standard
        // Migrate favorites from .standard to shared suite on first use
        if shared.object(forKey: "favoriteRegionIds") == nil,
           let existing = UserDefaults.standard.object(forKey: "favoriteRegionIds") as? [Int],
           !existing.isEmpty {
            shared.set(existing, forKey: "favoriteRegionIds")
        }
        return shared
    }()

    init(defaults: UserDefaults = sharedDefaults, cloudStore: NSUbiquitousKeyValueStore = .default) {
        self.defaults = defaults
        self.cloudStore = cloudStore
        syncFromCloud()
    }

    func loadFavorites() -> [Int] {
        return defaults.object(forKey: key) as? [Int] ?? []
    }

    func saveFavorites(_ ids: [Int]) {
        defaults.set(ids, forKey: key)
        syncToCloud(ids)
    }

    func addFavorite(_ id: Int, to favorites: inout [Int]) {
        if !favorites.contains(id) {
            favorites.append(id)
            saveFavorites(favorites)
        }
    }

    func removeFavorite(_ id: Int, from favorites: inout [Int]) {
        if let index = favorites.firstIndex(of: id) {
            favorites.remove(at: index)
            saveFavorites(favorites)
        }
    }

    // MARK: - iCloud Sync

    private func syncFromCloud() {
        cloudStore.synchronize()
        guard let cloudIds = cloudStore.object(forKey: key) as? [Int] else { return }
        let localIds = defaults.object(forKey: key) as? [Int] ?? []
        let merged = Array(Set(localIds).union(Set(cloudIds)))
        if Set(merged) != Set(localIds) {
            defaults.set(merged, forKey: key)
        }
    }

    private func syncToCloud(_ ids: [Int]) {
        cloudStore.set(ids, forKey: key)
        cloudStore.synchronize()
    }

    func startObservingCloudChanges(onChange: @escaping @Sendable ([Int]) -> Void) {
        NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            guard let cloudIds = self.cloudStore.object(forKey: self.key) as? [Int] else { return }
            let localIds = self.defaults.object(forKey: self.key) as? [Int] ?? []
            let merged = Array(Set(localIds).union(Set(cloudIds)))
            self.defaults.set(merged, forKey: self.key)
            onChange(merged)
        }
    }
}
