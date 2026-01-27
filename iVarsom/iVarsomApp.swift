import SwiftUI

@main
struct iVarsomApp: App {
    @State var vm = RegionListViewModel(
        client: VarsomApiClient(),
        locationManager: LocationManager())

    var body: some Scene {
        WindowGroup {
            RegionList<RegionListViewModel>(vm: vm)
                .onOpenURL { url in
                    let regionId = UrlUtils.extractParam(url: url, name: "id")
                    if let regionId = regionId {
                        Task {
                            await vm.selectRegionById(regionId: regionId)
                        }
                    }
                }
        }
    }
}
