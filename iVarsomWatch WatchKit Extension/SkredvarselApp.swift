import SwiftUI

@main
struct SkredvarselApp: App {
    @State var vm = RegionListViewModel(
        client: VarsomApiClient(),
        locationManager: LocationManager())

    @SceneBuilder var body: some Scene {
        WindowGroup {
            RegionListView<RegionListViewModel>(vm: vm).environment(vm)
        }
    }
}
