//
//  TestView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 09/06/1447 AH.
//


import SwiftUI

struct TestView: View {
    @State private var showPopup = false
    @State private var popupKind: PopupKind = .clipName
    @State private var inputText: String = ""
    
    var body: some View {
        ZStack {
            
            VStack(spacing: 20) {
                AppButton(title: "Adaptive White", type: .systemWhite) {
                    print("White tapped")
                }
                .padding()
                
                AppButton(title: "Adaptive Black", type: .systemBlack) {
                    print("Black tapped")
                }
                .padding()
                
                AppButton(title: "Orange", type: .orange) {
                    print("Orange tapped")
                }
                .padding()
                
                RoundOrangeButton(size: 70, icon: "plus") {
                    print("Tapped small button")
                }
                
                VStack(spacing: 20) {
                    Button("تسمية المقطع") {
                        popupKind = .clipName
                        inputText = ""
                        showPopup = true
                    }
                    
                    Button("تسمية التصنيف") {
                        popupKind = .categoryName
                        inputText = ""
                        showPopup = true
                    }
                }
                .padding()
            }
            // Disable all interactions when popup is visible
            .allowsHitTesting(!showPopup)
            
            // POPUP OVERLAY
            if showPopup {
                ZStack {
                    // Dim background that also captures taps
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        //tap outside to dismiss
                        .onTapGesture {
                            showPopup = false
                        }
                    
                    TextFieldAlert(
                        kind: popupKind,
                        text: $inputText,
                        onCancel: {
                            showPopup = false
                        },
                        onConfirm: {
                            print("User entered: \(inputText)")
                            showPopup = false
                        }
                    )
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showPopup)
            }
        }
    }
}

#Preview {
    TestView()
}

