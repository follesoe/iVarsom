import WidgetKit

/// Foreground app use is an opportunity to download the regions actually used
/// by widgets. Reload only after writing snapshots, so extensions see new data.
enum WidgetForecastRefresher {
    @MainActor
    static func refresh(forceRefresh: Bool = false) async {
        let configurations = (try? await WidgetCenter.shared.currentConfigurations()) ?? []
        let configuredIDs = Set(configurations.filter { $0.kind == "iVarsomWidget" }.map {
            Int($0.widgetConfigurationIntent(of: SelectRegion.self)?.region?.id ?? "") ?? RegionOption.defaultOption.id
        })
        #if os(watchOS)
        // Keep the same favourite regions ready for contextual Smart Stack suggestions.
        let ids = configuredIDs.union(FavoritesService.savedFavorites().prefix(5))
        #else
        let ids = configuredIDs
        #endif
        let service = ForecastService()
        var resolved = Set<Int>()
        for id in ids {
            guard !Task.isCancelled else { return }
            if let regionID = try? await ForecastRegionResolver.resolve(id) { resolved.insert(regionID) }
        }
        await withTaskGroup(of: Void.self) { group in
            var remaining = Array(resolved).makeIterator()
            for _ in 0..<min(3, resolved.count) {
                if let id = remaining.next() { group.addTask { _ = try? await service.load(regionID: id, forceRefresh: forceRefresh) } }
            }
            while await group.next() != nil {
                if Task.isCancelled { group.cancelAll(); break }
                if let id = remaining.next() { group.addTask { _ = try? await service.load(regionID: id, forceRefresh: forceRefresh) } }
            }
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "iVarsomWidget")
        WidgetCenter.shared.invalidateConfigurationRecommendations()
    }
}
