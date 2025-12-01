//
//  VideoView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 10/06/1447 AH.
//

import SwiftUI

struct VideoView: View {
    // POPUPS
    @State private var showCategoryPopup = false
    @State private var showTextFieldAlert = false
    @State private var popupKind: PopupKind = .clipName
    @State private var inputText: String = ""

    // This will hold the name of the clip (not used yet)
    @State private var clipName: String = ""

    // Categories
    @State private var categories: [String] = ["المكتبة", "قصص", "مقابلات"]
    
    // Navigation
    @State private var selectedCategory: String? = nil
    @State private var goToLibrary = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Hidden NavigationLink
                NavigationLink(
                    destination: LibraryView(category: selectedCategory ?? ""),
                    isActive: $goToLibrary
                ) {
                    EmptyView()
                }
                .hidden()

                LinearGradient(
                    colors: [Color(.systemBackground), Color.orange.opacity(0.4)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("شاشة الفيديو")
                        .font(.title2)

                    RoundOrangeButton(size: 70, icon: "square.and.arrow.down") {
                        popupKind = .clipName
                        inputText = ""
                        showTextFieldAlert = true
                    }

                }

                // 1) CATEGORY POPUP (only AFTER clip name is done)
                if showCategoryPopup {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    CategoryPopup(
                        categories: categories,
                        onAddNewCategory: {
                            popupKind = .categoryName
                            inputText = ""
                            showTextFieldAlert = true
                        },
                        onCategoryTap: { category in
                            selectedCategory = category
                            showCategoryPopup = false
                            goToLibrary = true
                        }
                    )
                }

                // 2) TEXTFIELD POPUP (used for both clip name + new category)
                if showTextFieldAlert {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()

                    TextFieldAlert(
                        kind: popupKind,
                        text: $inputText,
                        onCancel: {
                            showTextFieldAlert = false
                        },
                        onConfirm: {
                            handleTextFieldConfirm()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Handle TextField Confirm
    private func handleTextFieldConfirm() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch popupKind {
        case .clipName:
            // Save the clip name (for later use)
            clipName = trimmed
            // Close name popup → open category popup
            showTextFieldAlert = false
            showCategoryPopup = true

        case .categoryName:
            if !trimmed.isEmpty {
                categories.append(trimmed)
                selectedCategory = trimmed
                showCategoryPopup = false
                goToLibrary = true
            }
            showTextFieldAlert = false

        default:
            showTextFieldAlert = false
        }
    }
}

// MARK: - CATEGORY POPUP

struct CategoryPopup: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let categories: [String]
    let onAddNewCategory: () -> Void
    let onCategoryTap: (String) -> Void
    
    var body: some View {
        let bgColor   = colorScheme == .light ? Color.black : Color.white
        let textColor = colorScheme == .light ? Color.white : Color.black
        
        VStack(spacing: 14) {
            Text("اختر التصنيف")
                .font(.headline)
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            
            Divider()
                .overlay(Color.gray.opacity(0.4))
            
            AppButton(
                title: "إضافة تصنيف جديد",
                iconName: "plus",
                type: .orange
            ) {
                onAddNewCategory()
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        AppButton(
                            title: category,
                            iconName: nil,
                            type: .systemWhite
                        ) {
                            onCategoryTap(category)
                        }
                    }
                }
            }
            .frame(maxHeight: 150)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .background(bgColor)
        .cornerRadius(18)
        .shadow(radius: 8)
        .frame(maxWidth: 320)
        .padding(.horizontal, 32)
    }
}

// MARK: - PREVIEW

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
