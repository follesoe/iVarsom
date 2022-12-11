import Foundation
import Combine

@MainActor
class RegionListViewModel: RegionListViewModelProtocol {    
    private var language: VarsomApiClient.Language {
        return Locale.current.identifier.starts(with: "nb") ? .norwegian : .english
    }
    
    @Published private(set) var state = LoadState.idle
    @Published private(set) var locationIsAuthorized = false
    @Published private(set) var regions = [RegionSummary]()
    @Published private(set) var localRegion: RegionSummary? = nil
    @Published var favoriteRegionIds: [Int]
    @Published var filteredRegions = [RegionSummary]()
    @Published var favoriteRegions = [RegionSummary]()
    @Published var searchTerm = ""
    @Published var selectedRegionId: Int? = nil
    
    private let client: VarsomApiClient
    private let locationManager: LocationManager
    private let favoriteRegionIdsKey = "favoriteRegionIds"
    
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
        if (favoriteRegionIds.contains(id)) {
            let index = favoriteRegionIds.firstIndex(of: id)
            favoriteRegionIds.remove(at: index!)
            
        } else if (id == localRegion?.id) {
            let index = favoriteRegionIds.firstIndex(of: RegionOption.currentPositionOption.id)
            favoriteRegionIds.remove(at: index!)
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
            return regions[0].AvalancheWarningList[0].ValidTo < Date.now
        }
    }
    
    func loadRegions() async {
        do {
            self.state = .loading

            self.regions = try await client.loadRegions(lang: language).filter { region in
                return region.TypeName == "A"
            }
                        
            if (locationManager.isAuthorized) {
                await loadLocalRegion()
            }

            self.state = .loaded
        } catch {
            self.state = .failed
            print(error)
        }
    }
    
    func loadLocalRegion() async {
        do {
            let location = try await locationManager.updateLocation()
            self.localRegion = try await client.loadRegions(lang: language, coordinate: location)
        } catch {
            print(error)
        }
    }
    
    func updateLocation() async {
        do {
            let _ = try await locationManager.updateLocation()
            self.locationIsAuthorized = locationManager.isAuthorized
            await loadLocalRegion()
        } catch {
            self.locationIsAuthorized = false
            print(error)
        }
    }
}
