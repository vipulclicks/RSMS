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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appVM)
                .environment(appVM.dataStore)
        }
    }
}
