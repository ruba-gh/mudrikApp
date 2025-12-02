//
//  SplashView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 11/06/1447 AH.
//

import SwiftUI

struct SplashView: View {
    @State private var animate = false
    @State private var navigate = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()

            // Moving Logo
            Image(colorScheme == .light ? "LogoLight" : "LogoDark")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .offset(y: animate ? -10 : 0)
                .opacity(animate ? 1 : 0.5)
                .animation(.easeInOut(duration: 1.8).repeatForever(), value: animate)
        }
        .onAppear {
            animate = true

            // Auto navigate after 4 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                navigate = true
            }
        }
        // Transition to the main ContentView
        .fullScreenCover(isPresented: $navigate) {
            ContentView()
        }
    }
}
#Preview {
    SplashView()
}
