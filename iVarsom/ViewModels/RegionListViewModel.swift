import Foundation
import Combine

@MainActor
class RegionListViewModel: RegionListViewModelProtocol {    
    private var language: VarsomApiClient.Language {
        return Locale.current.identifier.starts(with: "nb") ? .norwegian : .english
    }
    
    @Published private(set) var regionLoadState = LoadState.idle
    @Published private(set) var warningLoadState = LoadState.idle
    @Published private(set) var locationIsAuthorized = false
    @Published private(set) var regions = [RegionSummary]()
    @Published private(set) var localRegion: RegionSummary? = nil
    @Published var favoriteRegionIds: [Int]
    @Published var filteredRegions = [RegionSummary]()
    @Published var favoriteRegions = [RegionSummary]()
    @Published var searchTerm = ""
    @Published var selectedRegion: RegionSummary? = nil
    @Published var warnings = [AvalancheWarningDetailed]()
    @Published var selectedWarning: AvalancheWarningDetailed? = nil
    
    private let client: VarsomApiClient
    private let locationManager: LocationManager
    private let favoriteRegionIdsKey = "favoriteRegionIds"
    private var loadWarningsTask: Task<Void, Never>?
    
    init(client: VarsomApiClient, locationManager: LocationManager) {
        self.client = client
        self.locationManager = locationManager
        self.locationIsAuthorized = locationManager.isAuthorized
        self.favoriteRegionIds = UserDefaults.standard.object(forKey: favoriteRegionIdsKey) as? [Int] ?? [Int]()
        print("Loaded favorite regions", favoriteRegionIds)
        
        Publishers.CombineLatest($regions, $searchTerm)
            .map { regions, searchTerm in
                regions.filter { region in
                    searchTerm.isEmpty ? true : region.Name.contains(searchTerm)
                }
            }
            .assign(to: &$filteredRegions)
        
        
        Publishers.CombineLatest3($filteredRegions, $localRegion, $favoriteRegionIds)
            .map { regions, localRegion, ids in
                var filteredReg = regions.filter { region in
                    ids.contains(region.id)
                }
                if let localReg = localRegion {
                    if (ids.contains(RegionOption.currentPositionOption.id)) {
                        filteredReg.insert(localReg, at: 0)
                    }
                }
                return filteredReg
            }
            .assign(to: &$favoriteRegions)
    }
    
    func addFavorite(id: Int) {
        if (!favoriteRegionIds.contains(id)) {
            favoriteRegionIds.append(id)
            print("Updating favorite regions", favoriteRegionIds)
            UserDefaults.standard.set(favoriteRegionIds, forKey: favoriteRegionIdsKey)
        }
    }

    func removeFavorite(id: Int) {
        if favoriteRegionIds.contains(id), let index = favoriteRegionIds.firstIndex(of: id) {
            favoriteRegionIds.remove(at: index)
        } else if id == localRegion?.id, let index = favoriteRegionIds.firstIndex(of: RegionOption.currentPositionOption.id) {
            favoriteRegionIds.remove(at: index)
        }
        print("Updating favorite regions", favoriteRegionIds)
        UserDefaults.standard.set(favoriteRegionIds, forKey: favoriteRegionIdsKey)
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

            print("Loading regions")
            self.regions = try await client.loadRegions(lang: language).filter { region in
                return region.TypeName == "A"
            }
                    
            print("Loading local region")
            if (locationManager.isAuthorized) {
                await loadLocalRegion()
            }

            print("Done loading")
            self.regionLoadState = .loaded
        } catch {
            self.regionLoadState = .failed
            print(error)
        }
    }
    
    func loadLocalRegion() async {
        do {
            let location = try await locationManager.updateLocation()
            if let location = location {
                let region = try await client.loadRegions(lang: language, coordinate: location)
                self.localRegion = region
            }
        } catch {
            print("Error loading local region: \(error)")
        }
    }
    
    func updateLocation() async {
        do {
            let _ = try await locationManager.requestPermission()
            self.locationIsAuthorized = locationManager.isAuthorized
            await loadLocalRegion()
        } catch {
            self.locationIsAuthorized = false
            print("Error updating location: \(error)")
        }
    }
    
    func loadWarnings(from: Int = -5, to: Int = 2) async {
        // Cancel any existing load task to prevent multiple concurrent calls
        loadWarningsTask?.cancel()
        
        guard let selectedRegion = selectedRegion else {
            print("Warning: Can't load warnings as no region is selected")
            return
        }
        
        print("Starting to load warnings for region: \(selectedRegion.Name)")
        
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
                    print("Error: Could not calculate date range")
                    return
                }
                
                print("Loading warnings from \(fromDate) to \(toDate)")
                
                // Check if task was cancelled before network call
                try Task.checkCancellation()
                
                let loadedWarnings = try await client.loadWarningsDetailed(
                    lang: VarsomApiClient.currentLang(),
                    regionId: selectedRegion.Id,
                    from: fromDate,
                    to: toDate)
                
                print("Loaded \(loadedWarnings.count) warnings")
                
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
                        print("Selected warning for today at index \(currentIndex)")
                    } else if !loadedWarnings.isEmpty {
                        // If no warning matches today, select the first one
                        self.selectedWarning = loadedWarnings[0]
                        print("No warning for today, selected first warning")
                    } else {
                        // No warnings available
                        self.selectedWarning = nil
                        print("No warnings available")
                    }
                    
                    self.warningLoadState = .loaded
                    print("Warnings loaded successfully")
                }
            } catch is CancellationError {
                // Task was cancelled, ignore
                print("Load warnings task was cancelled")
            } catch {
                await MainActor.run {
                    self.warningLoadState = .failed
                }
                print("Error loading warnings: \(error)")
            }
        }
        
        // Don't await the task - let it run in the background
        // The task will update @Published properties which will trigger UI updates automatically
    }
    
    func selectRegionById(regionId: Int) async {
        if (regions.count == 0) {
            await loadRegions()
        }

        let region = regions.first(where: { $0.Id == regionId})
        if let region = region {
            print("Navigate to region \(region.Name)")
            selectedRegion = region
        } else if localRegion?.Id == regionId {
            print("Navigate to local region")
            selectedRegion = localRegion
        } else {
            print("Region not found, unable to navigate to \(regionId), total \(regions.count) regions loaded, local region: \(localRegion?.Id ?? 0)")
        }
    }
}
