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
    var favoriteRegionIds: [Int]
    var searchTerm = ""
    var selectedRegion: RegionSummary? = nil
    var warnings = [AvalancheWarningDetailed]()
    var selectedWarning: AvalancheWarningDetailed? = nil

    var filteredRegions: [RegionSummary] {
        regions.filter { region in
            searchTerm.isEmpty || region.Name.contains(searchTerm)
        }
    }

    var filteredSwedenRegions: [RegionSummary] {
        swedenRegions.filter { region in
            searchTerm.isEmpty || region.Name.contains(searchTerm)
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
    private var loadWarningsTask: Task<Void, Never>?

    init(client: VarsomApiClient, locationManager: LocationManager, favoritesService: FavoritesService = FavoritesService()) {
        self.client = client
        self.locationManager = locationManager
        self.favoritesService = favoritesService
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
        } else {
            return regions[0].AvalancheWarningList[0].ValidTo < Date.current
        }
    }

    func loadRegions() async {
        do {
            self.regionLoadState = .loading

            async let norwayResult = client.loadRegions(lang: language)
            async let swedenResult = swedenClient.loadRegions()

            self.regions = try await norwayResult.filter { region in
                return region.TypeName == "A"
            }

            // Load Sweden gracefully - don't fail if Swedish API is down
            do {
                self.swedenRegions = try await swedenResult
            } catch {
                self.swedenRegions = []
            }

            if (locationManager.isAuthorized) {
                await loadLocalRegion()
            }

            self.regionLoadState = .loaded
        } catch {
            self.regionLoadState = .failed
        }
    }

    func loadLocalRegion() async {
        do {
            let location = try await locationManager.updateLocation()
            if let location = location {
                // Check if user is inside (or near) an A-region polygon
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
                } else {
                    // No A-region nearby - fall back to Norwegian coordinate API
                    let region = try await client.loadRegions(lang: language, coordinate: location)
                    self.localRegion = region
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

    func loadWarnings(from: Int = WarningDateRange.defaultDaysBefore, to: Int = WarningDateRange.defaultDaysAfter) async {
        // Cancel any existing load task to prevent multiple concurrent calls
        loadWarningsTask?.cancel()

        guard let selectedRegion = selectedRegion else {
            return
        }

        // Set loading state immediately
        self.warningLoadState = .loading
        self.selectedWarning = nil
        self.warnings = [AvalancheWarningDetailed]()

        // Create a task that we can cancel if needed
        loadWarningsTask = Task {
            do {
                // Check if task was cancelled
                try Task.checkCancellation()

                let today = Date.current
                guard let fromDate = Calendar.current.date(byAdding: .day, value: from, to: today),
                      let toDate = Calendar.current.date(byAdding: .day, value: to, to: today) else {
                    await MainActor.run {
                        self.warningLoadState = .failed
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

                    // Find the warning for today, or use the first available warning
                    if let currentIndex = loadedWarnings.firstIndex(where: {
                        Calendar.current.isDate($0.ValidFrom, equalTo: today, toGranularity: .day)
                    }) {
                        self.selectedWarning = loadedWarnings[currentIndex]
                    } else if !loadedWarnings.isEmpty {
                        // If no warning matches today, select the first one
                        self.selectedWarning = loadedWarnings[0]
                    } else {
                        // No warnings available
                        self.selectedWarning = nil
                    }

                    self.warningLoadState = .loaded
                }
            } catch is CancellationError {
                // Task was cancelled, ignore
            } catch {
                await MainActor.run {
                    self.warningLoadState = .failed
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
}
