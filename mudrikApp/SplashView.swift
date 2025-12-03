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
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(alignment: .center, spacing: 20) {

            
                Spacer()
                    
                ZStack(alignment: .center) {
                    // Video
                    LoopingVideoView(resourceName: "video", resourceExtension: "mov")
                       //.frame(width: 200, height: 300)
                        .ignoresSafeArea()
                        .padding(.bottom,0)
                    
                    Image(colorScheme == .light ? "LogoLight" : "LogoDark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400)
                        .offset(y: animate ? -10 : 0)
                        .opacity(animate ? 1 : 0.5)
                        .animation(
                            .easeInOut(duration: 1.8).repeatForever(),
                            value: animate)
                        
                    
                    
                }
                
            }
        }
        .onAppear {
            animate = true

            // Auto navigate after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                navigate = true
            }
        }
        .fullScreenCover(isPresented: $navigate) {
            ContentView()
        }
    }
}

#Preview {
    SplashView()
}
