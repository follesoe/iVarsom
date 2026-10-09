import Foundation
import Observation
import Testing
@testable import Skredvarsel

@MainActor
private final class TestCloudStore: NSObject, FavoritesCloudStore {
    var value: [Int]?
    func object(forKey key: String) -> Any? { value }
    func set(_ value: Any?, forKey key: String) { self.value = value as? [Int] }
    func synchronize() -> Bool { true }
}

@MainActor
struct FavoritesServiceTests {
    @Test func addingIsIdempotentAndPreservesOrder() {
        let preferences = TestPreferences()
        let favorites = preferences.favorites()
        favorites.addFavorite(3006)
        favorites.addFavorite(3003)
        favorites.addFavorite(3006)
        #expect(favorites.ids == [3006, 3003])
        #expect(preferences.defaults.array(forKey: "favoriteRegionIds") as? [Int] == [3006, 3003])
    }

    @Test func cloudDeletionReplacesLocalSnapshot() {
        let preferences = TestPreferences()
        let cloud = TestCloudStore()
        let favorites = FavoritesService(defaults: preferences.defaults, cloudStore: cloud, migrateLegacyDefaults: false)
        favorites.addFavorite(3003)
        favorites.addFavorite(3006)
        cloud.value = [3006]
        favorites.syncFromCloud()
        #expect(favorites.ids == [3006])
        cloud.value = []
        favorites.syncFromCloud()
        #expect(favorites.ids.isEmpty)
    }

    @Test func cloudImportDeduplicatesWithoutReordering() {
        let preferences = TestPreferences()
        let cloud = TestCloudStore()
        cloud.value = [3006, 3003, 3006]
        let favorites = FavoritesService(defaults: preferences.defaults, cloudStore: cloud, migrateLegacyDefaults: false)
        #expect(favorites.ids == [3006, 3003])
        favorites.removeFavorite(3006)
        #expect(cloud.value == [3003])
    }

    @Test func missingCloudDoesNotEraseLocalFavorites() {
        let preferences = TestPreferences()
        preferences.defaults.set([3003], forKey: "favoriteRegionIds")
        let favorites = FavoritesService(defaults: preferences.defaults, cloudStore: TestCloudStore(), migrateLegacyDefaults: false)
        #expect(favorites.ids == [3003])
    }
}

@MainActor
struct FavoritesObservationTests {
    @Test func cloudNotificationUpdatesObservableState() async {
        let preferences = TestPreferences()
        let cloud = TestCloudStore()
        let notifications = NotificationCenter()
        let favorites = FavoritesService(defaults: preferences.defaults, cloudStore: cloud,
                                         notifications: notifications, migrateLegacyDefaults: false)
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            withObservationTracking {
                _ = favorites.ids
            } onChange: {
                continuation.resume()
            }
            cloud.value = [3006]
            notifications.post(name: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud)
        }
        #expect(favorites.ids == [3006])
    }

    @Test func observationDoesNotRetainService() {
        let preferences = TestPreferences()
        let cloud = TestCloudStore()
        weak var weakService: FavoritesService?
        do {
            let service = FavoritesService(defaults: preferences.defaults, cloudStore: cloud, migrateLegacyDefaults: false)
            weakService = service
            #expect(weakService != nil)
        }
        #expect(weakService == nil)
    }
}
