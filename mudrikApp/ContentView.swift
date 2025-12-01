//
//  ContentView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 09/06/1447 AH.
//

import SwiftUI

struct ContentView: View {
    @State private var showPopup = false
    @State private var popupKind: PopupKind = .clipName
    @State private var inputText: String = ""
    @Environment(\.colorScheme) private var colorScheme
    
    
    var body: some View {
        
        ZStack {
            LinearGradient(
                gradient: Gradient(stops: [
                    .init( color: Color(uiColor: .systemBackground),   location: 0.0),
                    .init( color: Color(uiColor: .systemBackground),   location: 0.7),
                    .init(color: .orange, location: 1.0)    //
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 10) {
                Image(colorScheme == .light ? "LogoLight" : "LogoDark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .clipShape(Circle())
                    .padding(.top,100)
                
                
                Spacer()
                
                AppButton(
                    title: "المترجم",
                    iconName: "camera.viewfinder",
                    type: .systemWhite
                ) {
                    print("White tapped")
                }
                
                AppButton(
                    title: "المكتبة",
                    iconName: "books.vertical.fill",
                    type: .systemBlack
                ) {
                    print("Black tapped")
                }
                
            }.padding()
            
        }
    }
}

#Preview {
    ContentView()
}

