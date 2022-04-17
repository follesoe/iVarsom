//
//  SkredvarselApp.swift
//  iVarsomWatch WatchKit Extension
//
//  Created by Jonas Follesø on 14/04/2022.
//

import SwiftUI

@main
struct SkredvarselApp: App {
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }

        WKNotificationScene(controller: NotificationController.self, category: "myCategory")
    }
}
