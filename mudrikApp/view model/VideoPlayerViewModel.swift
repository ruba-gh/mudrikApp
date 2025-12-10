import Foundation
import SwiftUI
import Combine
import AVKit

@MainActor
final class VideoPlayerViewModel: ObservableObject {
    // Inputs
    let extractedText: String?
    let clipNameFromLibrary: String?

    // Bindings passed through from parent
    @Binding var allSavedClips: [SavedClip]
    @Binding var categories: [String]
    @Binding var navigateToLibrary: Bool

    // Local UI state
    @Published var showSavePopup = false
    @Published var showCategoryPopup = false
    @Published var popupKind: PopupKind = .clipName
    @Published var inputText: String = ""
    @Published var clipName: String = ""
    @Published var selectedCategory: String? = nil

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

    func onTapSaveButton() {
        popupKind = .clipName
        inputText = ""
        showSavePopup = true
    }

    func handleTextFieldConfirm() {
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

    func addNewCategoryFlow() {
        popupKind = .categoryName
        inputText = ""
        showCategoryPopup = false
        showSavePopup = true
    }

    func selectCategoryAndSave(_ category: String) {
        selectedCategory = category
        showCategoryPopup = false
        saveClipAndNavigate(category: category)
    }

//    private func saveClipAndNavigate(category: String) {
//        if !categories.contains(category) {
//            categories.append(category)
//        }
//
//        let finalClipName = clipName.isEmpty ? "مقطع بدون اسم" : clipName
//        let newClip = SavedClip(name: finalClipName, category: category)
//        allSavedClips.append(newClip)
//
//        navigateToLibrary = true
//    }
    
    private func saveClipAndNavigate(category: String) {

        if !categories.contains(category) {
            categories.append(category)
        }

        let finalClipName = clipName.isEmpty ? "مقطع بدون اسم" : clipName

        let newClip = SavedClip(
            name: finalClipName,
            category: category,
            videoFileName: "avatarr.mp4"
        )

        allSavedClips.append(newClip)

        StorageManager().saveClips(allSavedClips)
        StorageManager().saveCategories(categories)

        navigateToLibrary = true
    }

    
    
}
