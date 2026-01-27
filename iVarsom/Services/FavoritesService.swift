import Foundation

class FavoritesService {
    private let key = "favoriteRegionIds"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
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
