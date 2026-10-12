import AppIntents
import RelevanceKit
import WidgetKit

extension Provider {
    func relevance() async -> WidgetRelevance<SelectRegion> {
        let store = SharedForecastStore()
        let now = Date.current
        var attributes: [WidgetRelevanceAttribute<SelectRegion>] = []
        for id in FavoritesService.savedFavorites().prefix(5) {
            guard let region = (RegionOption.aRegions + RegionOption.swedenRegions).first(where: { $0.id == id }),
                  let snapshot = await store.load(regionID: id,
                    language: SharedForecastStore.languageKey(regionID: id, language: VarsomApiClient.currentLang()), now: now)
            else { continue }
            let configuration = SelectRegion()
            configuration.region = RegionConfigOptionAppEntity(region)
            configuration.day = .today
            for interval in ForecastRelevance.morningWindows(snapshot: snapshot, now: now) {
                attributes.append(WidgetRelevanceAttribute(configuration: configuration,
                    context: .date(interval: interval, kind: .informational)))
            }
        }
        return WidgetRelevance(attributes)
    }
}
