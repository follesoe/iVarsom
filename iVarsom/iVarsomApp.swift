import SwiftUI

@main
struct iVarsomApp: App {    
    @StateObject var vm = RegionListViewModel(
        client: VarsomApiClient(),
        locationManager: LocationManager())

    var body: some Scene {
        WindowGroup {
            RegionList<RegionListViewModel>(vm: vm)
                .onOpenURL { url in
                    setSelectedRegion(url: url)
                }
        }
    }
    
    func setSelectedRegion(url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let components = components {
            if let queryItems = components.queryItems {
                for queryItem in queryItems {
                    if queryItem.name == "id" && queryItem.value != nil {
                        self.vm.selectedRegionId = Int(queryItem.value ?? "0")
                    }
                }
            }
        }
    }
}
