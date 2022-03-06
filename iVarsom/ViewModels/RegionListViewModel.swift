import Foundation
import Combine

@MainActor
class RegionListViewModel: RegionListViewModelProtocol {
    enum State {
        case idle
        case loading
        case failed(Error)
        case loaded
    }
    
    private var language: VarsomApiClient.Language {
        return Locale.current.languageCode == "nb" ? .norwegian : .english
    }
    
    @Published private(set) var state = State.idle
    @Published private(set) var locationIsAuthorized = false
    @Published private(set) var regions = [RegionSummary]()
    @Published private(set) var localRegion: RegionSummary? = nil
    @Published var filteredRegions = [RegionSummary]()
    @Published var searchTerm = ""
    @Published var selectedRegionId: Int? = nil
    
    private let client: VarsomApiClient
    private let locationManager: LocationManager
    
    init(client: VarsomApiClient, locationManager: LocationManager) {
        self.client = client
        self.locationManager = locationManager
        self.locationIsAuthorized = locationManager.isAuthorized
        
        Publishers.CombineLatest($regions, $searchTerm)
            .map { regions, searchTerm in
                regions.filter { region in
                    searchTerm.isEmpty ? true : region.Name.contains(searchTerm)
                }
            }
            .assign(to: &$filteredRegions)
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
            self.state = .failed(error)
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
