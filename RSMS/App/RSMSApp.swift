//
//  RSMSApp.swift
//  RSMS
//
//  Created by Yashika Sharma on 19/05/26.
//

import SwiftUI

@main
struct RSMSApp: App {
    @State private var appViewModel = AppViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appViewModel)
        }
    }
}
