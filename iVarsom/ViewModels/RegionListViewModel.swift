import Foundation

@Observable
@MainActor
class RegionListViewModel: RegionListViewModelProtocol {
    private var language: VarsomApiClient.Language {
        return (Locale.current.identifier.starts(with: "nb") || Locale.current.identifier.starts(with: "sv"))
            ? .norwegian : .english
    }

    private(set) var regionLoadState = LoadState.idle
    private(set) var warningLoadState = LoadState.idle
    private(set) var locationIsAuthorized = false
    private(set) var regions = [RegionSummary]()
    private(set) var swedenRegions = [RegionSummary]()
    private(set) var localRegion: RegionSummary? = nil
    private(set) var userLocation: Location2D? = nil
    var favoriteRegionIds: [Int]
    var searchTerm = ""
    var selectedRegion: RegionSummary? = nil
    var warnings = [AvalancheWarningDetailed]()
    var selectedWarning: AvalancheWarningDetailed? = nil

    var filteredRegions: [RegionSummary] {
        regions.filter { region in
            searchTerm.isEmpty || region.Name.localizedCaseInsensitiveContains(searchTerm)
        }
    }

    var filteredSwedenRegions: [RegionSummary] {
        swedenRegions.filter { region in
            searchTerm.isEmpty || region.Name.localizedCaseInsensitiveContains(searchTerm)
        }
    }

    var favoriteRegions: [RegionSummary] {
        var result = (filteredRegions + filteredSwedenRegions).filter { region in
            favoriteRegionIds.contains(region.id)
        }
        if let localReg = localRegion {
            if favoriteRegionIds.contains(RegionOption.currentPositionOption.id) {
                result.insert(localReg, at: 0)
            }
        }
        return result
    }

    private let client: VarsomApiClient
    private let swedenClient = LavinprognoserApiClient()
    private let locationManager: LocationManager
    private let favoritesService: FavoritesService
    private let cacheService: CacheServiceProtocol
    private var loadWarningsTask: Task<Void, Never>?

    init(client: VarsomApiClient, locationManager: LocationManager, favoritesService: FavoritesService = FavoritesService(), cacheService: CacheServiceProtocol = CacheService()) {
        self.client = client
        self.locationManager = locationManager
        self.favoritesService = favoritesService
        self.cacheService = cacheService
        self.locationIsAuthorized = locationManager.isAuthorized
        self.favoriteRegionIds = favoritesService.loadFavorites()
    }

    func addFavorite(id: Int) {
        favoritesService.addFavorite(id, to: &favoriteRegionIds)
    }

    func removeFavorite(id: Int) {
        if favoriteRegionIds.contains(id), let index = favoriteRegionIds.firstIndex(of: id) {
            favoriteRegionIds.remove(at: index)
        } else if id == localRegion?.id, let index = favoriteRegionIds.firstIndex(of: RegionOption.currentPositionOption.id) {
            favoriteRegionIds.remove(at: index)
        }
        favoritesService.saveFavorites(favoriteRegionIds)
    }

    func needsRefresh() -> Bool {
        if (regions.isEmpty) {
            return true
        } else if (regions[0].AvalancheWarningList.isEmpty) {
            return true;
        } else if regions[0].AvalancheWarningList[0].ValidTo < Date.current {
            return true
        } else {
            return !cacheService.isFresh(country: .norway) || !cacheService.isFresh(country: .sweden)
        }
    }

    func loadRegions() async {
        // Try loading from cache first
        let cachedNorway = cacheService.loadRegions(country: .norway)
        let cachedSweden = cacheService.loadRegions(country: .sweden)

        if let cachedNorway = cachedNorway {
            self.regions = cachedNorway
            self.swedenRegions = cachedSweden ?? []
            self.regionLoadState = .loaded

            // If both caches are fresh, skip network
            if cacheService.isFresh(country: .norway) && cacheService.isFresh(country: .sweden) {
                if (locationManager.isAuthorized) {
                    await loadLocalRegion()
                }
                return
            }
        } else {
            self.regionLoadState = .loading
        }

        // Fetch from network
        do {
            async let norwayResult = client.loadRegions(lang: language)
            async let swedenResult = swedenClient.loadRegions()

            let norwayRegions = try await norwayResult.filter { region in
                return region.TypeName == "A"
            }
            self.regions = norwayRegions
            cacheService.saveRegions(norwayRegions, country: .norway)

            do {
                let swedenRegions = try await swedenResult
                self.swedenRegions = swedenRegions
                cacheService.saveRegions(swedenRegions, country: .sweden)
            } catch {
                if cachedSweden == nil {
                    self.swedenRegions = []
                }
            }

            if (locationManager.isAuthorized) {
                await loadLocalRegion()
            }

            self.regionLoadState = .loaded
        } catch {
            // On failure with cache, stay in .loaded
            if cachedNorway != nil {
                // Keep showing cached data
            } else {
                self.regionLoadState = .failed
            }
        }
    }

    func loadLocalRegion() async {
        do {
            let location = try await locationManager.updateLocation()
            if let location = location {
                if let geoData = RegionGeoData.load(),
                   let feature = geoData.findNearestRegion(at: location) {
                    let warnings: [AvalancheWarningSimple]
                    if Country.from(regionId: feature.id) == .sweden {
                        warnings = try await swedenClient.loadWarnings(regionId: feature.id)
                    } else {
                        warnings = try await client.loadWarnings(
                            lang: VarsomApiClient.currentLang(),
                            regionId: feature.id,
                            from: Date.current,
                            to: Date.current)
                    }
                    self.localRegion = RegionSummary(
                        Id: feature.id,
                        Name: feature.name,
                        TypeName: "A",
                        AvalancheWarningList: warnings)
                }
            }
        } catch {
            // Error loading local region - silently ignore
        }
    }

    func updateLocation() async {
        do {
            let _ = try await locationManager.requestPermission()
            self.locationIsAuthorized = locationManager.isAuthorized
            await loadLocalRegion()
        } catch {
            self.locationIsAuthorized = false
        }
    }

    func requestLocationForMap() async {
        let wasAuthorized = locationManager.isAuthorized
        if !wasAuthorized {
            do {
                let _ = try await locationManager.requestPermission()
                self.locationIsAuthorized = locationManager.isAuthorized
            } catch {
                self.locationIsAuthorized = false
                return
            }
        }
        do {
            let location = try await locationManager.updateLocation()
            self.userLocation = location
            if !wasAuthorized && locationManager.isAuthorized {
                await loadLocalRegion()
            }
        } catch {
            // Location unavailable - silently ignore
        }
    }

    func loadWarnings(from: Int = WarningDateRange.defaultDaysBefore, to: Int = WarningDateRange.defaultDaysAfter) async {
        // Cancel any existing load task to prevent multiple concurrent calls
        loadWarningsTask?.cancel()

        guard let selectedRegion = selectedRegion else {
            return
        }

        // Try loading from cache first
        let cachedWarnings = cacheService.loadWarningsDetailed(regionId: selectedRegion.Id)

        if let cachedWarnings = cachedWarnings, !cachedWarnings.isEmpty {
            self.warnings = cachedWarnings
            self.selectedWarning = selectTodayWarning(from: cachedWarnings)
            self.warningLoadState = .loaded

            // If cache is fresh, skip network
            if cacheService.isWarningFresh(regionId: selectedRegion.Id) {
                return
            }
        } else {
            self.warningLoadState = .loading
            self.selectedWarning = nil
            self.warnings = [AvalancheWarningDetailed]()
        }

        let hasCachedData = cachedWarnings != nil && !(cachedWarnings?.isEmpty ?? true)

        // Create a task that we can cancel if needed
        loadWarningsTask = Task {
            do {
                // Check if task was cancelled
                try Task.checkCancellation()

                let today = Date.current
                guard let fromDate = Calendar.current.date(byAdding: .day, value: from, to: today),
                      let toDate = Calendar.current.date(byAdding: .day, value: to, to: today) else {
                    await MainActor.run {
                        if !hasCachedData {
                            self.warningLoadState = .failed
                        }
                    }
                    return
                }

                // Check if task was cancelled before network call
                try Task.checkCancellation()

                let loadedWarnings: [AvalancheWarningDetailed]
                if Country.from(regionId: selectedRegion.Id) == .sweden {
                    loadedWarnings = try await swedenClient.loadWarningsDetailed(regionId: selectedRegion.Id)
                } else {
                    loadedWarnings = try await client.loadWarningsDetailed(
                        lang: VarsomApiClient.currentLang(),
                        regionId: selectedRegion.Id,
                        from: fromDate,
                        to: toDate)
                }

                // Check if task was cancelled after network call
                try Task.checkCancellation()

                // Update UI on main actor
                await MainActor.run {
                    self.warnings = loadedWarnings
                    self.selectedWarning = selectTodayWarning(from: loadedWarnings)
                    self.warningLoadState = .loaded
                    cacheService.saveWarningsDetailed(loadedWarnings, regionId: selectedRegion.Id)
                }
            } catch is CancellationError {
                // Task was cancelled, ignore
            } catch {
                await MainActor.run {
                    if !hasCachedData {
                        self.warningLoadState = .failed
                    }
                }
            }
        }

        // Don't await the task - let it run in the background
        // The task will update properties which will trigger UI updates automatically
    }

    func selectRegionById(regionId: Int) async {
        if (regions.count == 0) {
            await loadRegions()
        }

        let region = regions.first(where: { $0.Id == regionId})
            ?? swedenRegions.first(where: { $0.Id == regionId})
        if let region = region {
            selectedRegion = region
        } else if localRegion?.Id == regionId {
            selectedRegion = localRegion
        }
    }

    // MARK: - Private

    private func selectTodayWarning(from warnings: [AvalancheWarningDetailed]) -> AvalancheWarningDetailed? {
        let today = Date.current
        if let currentIndex = warnings.firstIndex(where: {
            Calendar.current.isDate($0.ValidFrom, equalTo: today, toGranularity: .day)
        }) {
            return warnings[currentIndex]
        } else if !warnings.isEmpty {
            return warnings[0]
        }
        return nil
    }
}
