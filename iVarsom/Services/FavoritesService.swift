import Foundation

class FavoritesService {
    private let key = "favoriteRegionIds"
    private let defaults: UserDefaults

    #if os(watchOS)
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
    #else
    nonisolated(unsafe) static let sharedDefaults: UserDefaults = .standard
    #endif

    init(defaults: UserDefaults = sharedDefaults) {
        self.defaults = defaults
    }

    func loadFavorites() -> [Int] {
        return defaults.object(forKey: key) as? [Int] ?? []
    }

    func saveFavorites(_ ids: [Int]) {
        defaults.set(ids, forKey: key)
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
}
