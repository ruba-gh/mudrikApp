//
//  mudrikAppApp.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 09/06/1447 AH.
//

import SwiftUI

@main
struct mudrikAppApp: App {
    // Shared store for the whole app lifecycle
    @StateObject private var store = ClipsStore()

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environmentObject(store)
        }
    }
}
