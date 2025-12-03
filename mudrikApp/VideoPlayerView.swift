//
//  VideoPlayerView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 12/06/1447 AH.
//

import SwiftUI
import AVKit

// MARK: - VideoPlayerView (صفحة الفيديو الرئيسية)
struct VideoPlayerView: View {
    let extractedText: String?
    let clipNameFromLibrary: String?
    
    @Binding var allSavedClips: [SavedClip]
    @Binding var categories: [String]
    @Binding var navigateToLibrary: Bool
    
    @State private var showSavePopup = false
    @State private var showCategoryPopup = false
    @State private var popupKind: PopupKind = .clipName
    @State private var inputText: String = ""
    @State private var clipName: String = ""
    
    @State private var selectedCategory: String? = nil
    // @Environment(\.dismiss) private var dismiss   // no longer needed
    
    var pageTitle: String {
        if let name = clipNameFromLibrary {
            return name
        } else if let text = extractedText, !text.isEmpty {
            return "ترجمة النص"
        } else {
            return "صفحة الفيديو"
        }
    }
    
    var categoriesForPopup: [String] {
        var list = categories
        if !list.contains("المكتبة") {
            list.insert("المكتبة", at: 0)
        }
        return list
    }
    
    init(
        extractedText: String? = nil,
        clipNameFromLibrary: String? = nil,
        allSavedClips: Binding<[SavedClip]>,
        categories: Binding<[String]>,
        navigateToLibrary: Binding<Bool>
    ) {
        self.extractedText = extractedText
        self.clipNameFromLibrary = clipNameFromLibrary
        self._allSavedClips = allSavedClips
        self._categories = categories
        self._navigateToLibrary = navigateToLibrary
    }
    
    var body: some View {
        ZStack {
            // 🔹 Hidden NavigationLink that pushes LibraryView when navigateToLibrary == true
            NavigationLink(
                destination: LibraryView(allClips: $allSavedClips, categories: $categories),
                isActive: $navigateToLibrary
            ) {
                EmptyView()
            }
            .hidden()
            
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Text(pageTitle)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding(.top, 20)
                
                VStack {
                    if let videoURL = Bundle.main.url(forResource: "avatarr", withExtension: "mp4") {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 350)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                    } else {
                        Text("فشل تحميل الفيديو: avatarr.mp4 غير موجود")
                            .foregroundColor(.red)
                            .frame(height: 350)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                if clipNameFromLibrary == nil {
                    Button(action: {
                        popupKind = .clipName
                        inputText = ""
                        showSavePopup = true
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                    .padding(.bottom, 30)
                    .padding(.trailing, 30)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            
            // CATEGORY POPUP
            if showCategoryPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                CategoryPopup(
                    categories: categoriesForPopup,
                    onAddNewCategory: {
                        popupKind = .categoryName
                        inputText = ""
                        showCategoryPopup = false
                        showSavePopup = true
                    },
                    onCategoryTap: { category in
                        selectedCategory = category
                        showCategoryPopup = false
                        saveClipAndNavigate(category: category)
                    }
                )
            }
            
            // TEXTFIELD POPUP
            if showSavePopup {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                
                TextFieldAlert(
                    kind: popupKind,
                    text: $inputText,
                    onCancel: {
                        showSavePopup = false
                    },
                    onConfirm: {
                        handleTextFieldConfirm()
                    }
                )
            }
        }
    }
    
    // MARK: - Logic
    
    private func handleTextFieldConfirm() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        switch popupKind {
        case .clipName:
            clipName = trimmed
            showSavePopup = false
            showCategoryPopup = true
            
        case .categoryName:
            if !categories.contains(trimmed) {
                categories.append(trimmed)
            }
            showSavePopup = false
            saveClipAndNavigate(category: trimmed)
        }
    }
    
    private func saveClipAndNavigate(category: String) {
        if !categories.contains(category) {
            categories.append(category)
        }
        
        let finalClipName = clipName.isEmpty ? "مقطع بدون اسم" : clipName
        let newClip = SavedClip(name: finalClipName, category: category)
        allSavedClips.append(newClip)
        
        // ✅ This now triggers the NavigationLink above to push LibraryView
        navigateToLibrary = true
    }
}

// MARK: - Preview
struct VideoPlayerView_Previews: PreviewProvider {
    struct PreviewWrapper: View {
        @State private var clips: [SavedClip] = [
            SavedClip(name: "مقطع 1", category: "قصص")
        ]
        @State private var cats: [String] = ["قصص", "مطبخ"]
        @State private var navigate = false
        
        var body: some View {
            VideoPlayerView(
                extractedText: "هذا نص مستخرج من الصورة",
                allSavedClips: $clips,
                categories: $cats,
                navigateToLibrary: $navigate
            )
        }
    }
    static var previews: some View {
        PreviewWrapper()
    }
}
