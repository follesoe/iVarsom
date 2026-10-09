import SwiftUI

@main
struct SkredvarselApp: App {
    @State private var vm = RegionBrowserModel()

    @SceneBuilder var body: some Scene {
        WindowGroup {
            RegionListView(vm: vm)
        }
    }
}
