#if DEBUG
    import CoreLocation
    import Foundation

    @MainActor
    enum PreviewModels {
        private static var defaults: UserDefaults { UserDefaults(suiteName: "no.follesoe.iVarsom.previews")! }

        static func browser(regions: [RegionSummary] = testARegions) -> RegionBrowserModel {
            let favorites = FavoritesService(defaults: defaults, cloudStore: nil, migrateLegacyDefaults: false)
            regions.forEach { favorites.addFavorite($0.id) }
            return RegionBrowserModel(
                repository: PreviewRepository(regions: regions),
                locationManager: PreviewLocation(), favorites: favorites)
        }

        static func reviewPrompt() -> ReviewPromptService { ReviewPromptService(defaults: defaults) }
    }

    private struct PreviewRepository: WarningRepositoryProviding {
        let regions: [RegionSummary]
        func loadRegions() async throws -> RegionCatalog {
            RegionCatalog(norway: regions, sweden: [], isEntirelyFresh: true)
        }
        func loadWarnings(_ request: WarningRequest, cachePolicy: WarningCachePolicy) async throws -> LoadedWarnings {
            let warnings: [AvalancheWarningDetailed] = load("DetailedWarning.json")
            return LoadedWarnings(warnings: warnings.filter { $0.RegionId == request.regionID }, source: .network)
        }
        func loadSummaries(_ request: WarningRequest) async throws -> [AvalancheWarningSimple] { [] }
    }

    @MainActor
    private final class PreviewLocation: LocationProviding {
        var authorizationStatus: CLAuthorizationStatus? { .notDetermined }
        var isAuthorized: Bool { false }
        func checkAuthorization() async throws -> Bool { false }
        func requestPermission() async throws -> Bool { false }
        func updateLocation() async throws -> Location2D? { nil }
    }
#endif
