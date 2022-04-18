import SwiftUI

@main
struct SkredvarselApp: App {
    @StateObject var vm = RegionListViewModel(
        client: VarsomApiClient(),
        locationManager: LocationManager())
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView<RegionListViewModel>(vm: vm)
            }.tint(Color("DangerLevel3"))
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
