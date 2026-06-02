//
//  RSMSApp.swift
//  RSMS
//
//  App entry point. Injects AppViewModel and DataStore into the environment.
//

import SwiftUI

@main
struct RSMSApp: App {
    @State private var appVM = AppViewModel()

    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        if let darkRed = UIColor(named: "darkRed") {
            appearance.largeTitleTextAttributes = [.foregroundColor: darkRed]
            appearance.titleTextAttributes = [.foregroundColor: darkRed]
        }
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appVM)
                .environment(appVM.dataStore)
                .task {
                    await VideoConsultationNotificationService.shared.requestPermission()
                }
        }
    }
}
