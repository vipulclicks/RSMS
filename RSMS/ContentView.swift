//
//  ContentView.swift
//  RSMS
//
//  Created by Yashika Sharma on 19/05/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(RSMSTheme.primary)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
