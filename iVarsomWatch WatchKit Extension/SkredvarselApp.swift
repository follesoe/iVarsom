import SwiftUI

@main
struct SkredvarselApp: App {
    @StateObject var vm = RegionListViewModel(
        client: VarsomApiClient(),
        locationManager: LocationManager())
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            RegionListView<RegionListViewModel>(vm: vm).environmentObject(vm)
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
