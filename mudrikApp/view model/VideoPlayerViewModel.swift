import Foundation
import SwiftUI
import Combine
import AVKit

@MainActor
final class VideoPlayerViewModel: ObservableObject {

    // Inputs
    let extractedText: String?
    let clipNameFromLibrary: String?
    let clipID: UUID?

    // Bindings used for OCR flow only
    @Binding var allSavedClips: [SavedClip]
    @Binding var categories: [String]
    @Binding var navigateToLibrary: Bool

    // Environment store used for library flow
    private weak var store: ClipsStore?

    // Local UI state
    @Published var showSavePopup = false
    @Published var showCategoryPopup = false
    @Published var popupKind: PopupKind = .clipName
    @Published var inputText: String = ""
    @Published var clipName: String = ""
    @Published var selectedCategory: String? = nil

    // Editing title
    @Published var isEditingTitle: Bool = false
    @Published var editedTitle: String = ""

    // Delete confirm
    @Published var showDeleteConfirm: Bool = false

    init(
        extractedText: String? = nil,
        clipNameFromLibrary: String? = nil,
        clipID: UUID? = nil,
        allSavedClips: Binding<[SavedClip]>,
        categories: Binding<[String]>,
        navigateToLibrary: Binding<Bool>,
        store: ClipsStore?
    ) {
        self.extractedText = extractedText
        self.clipNameFromLibrary = clipNameFromLibrary
        self.clipID = clipID

        self._allSavedClips = allSavedClips
        self._categories = categories
        self._navigateToLibrary = navigateToLibrary

        self.store = store

        // If opened from library, prepare current title for editing
        if let id = clipID {
            if let clip = resolveClipsArray().first(where: { $0.id == id }) {
                self.clipName = clip.name
                self.editedTitle = clip.name
            } else {
                self.clipName = clipNameFromLibrary ?? ""
                self.editedTitle = clipNameFromLibrary ?? ""
            }
        }
    }

    func injectStoreIfNeeded(_ store: ClipsStore) {
        guard self.store == nil else { return }
        self.store = store

        // Refresh title from store if opened from library
        if let id = clipID, let clip = store.clips.first(where: { $0.id == id }) {
            self.clipName = clip.name
            self.editedTitle = clip.name
        }
    }

    var isFromLibrary: Bool { clipID != nil }
    var isFromOCR: Bool { clipID == nil }

    var pageTitle: String {
        if isFromLibrary {
            return clipName
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

    // MARK: - Resolve correct clips source
    private func resolveClipsArray() -> [SavedClip] {
        if isFromLibrary, let store { return store.clips }
        return allSavedClips
    }

    private func updateClip(id: UUID, mutate: (inout SavedClip) -> Void) {
        if isFromLibrary, let store {
            if let idx = store.clips.firstIndex(where: { $0.id == id }) {
                var clip = store.clips[idx]
                mutate(&clip)
                store.clips[idx] = clip
                StorageManager().saveClips(store.clips)
            }
        } else {
            if let idx = allSavedClips.firstIndex(where: { $0.id == id }) {
                mutate(&allSavedClips[idx])
                StorageManager().saveClips(allSavedClips)
            }
        }
    }

    private func removeClip(id: UUID) {
        if isFromLibrary, let store {
            store.clips.removeAll { $0.id == id }
            StorageManager().saveClips(store.clips)
        } else {
            allSavedClips.removeAll { $0.id == id }
            StorageManager().saveClips(allSavedClips)
        }
    }

    // MARK: - Saving flow (OCR only) – unchanged
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

    private func saveClipAndNavigate(category: String) {
        if !categories.contains(category) {
            categories.append(category)
        }

        let finalClipName = clipName.isEmpty ? "مقطع بدون اسم" : clipName

        // Generate a unique file name for the video to avoid overwriting
        let uniqueFileName = UUID().uuidString + ".mp4"

        let newClip = SavedClip(
            name: finalClipName,
            category: category,
            videoFileName: uniqueFileName
        )

        allSavedClips.append(newClip)

        StorageManager().saveClips(allSavedClips)
        StorageManager().saveCategories(categories)

        navigateToLibrary = true
    }

    // MARK: - Edit title (library only)
    func startEditingTitle() {
        guard isFromLibrary else { return }
        editedTitle = clipName
        isEditingTitle = true
    }

    func saveEditedTitle() {
        guard isFromLibrary, let id = clipID else { return }

        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Update in the shared store so Library grid reflects immediately
        updateClip(id: id) { clip in
            clip.name = trimmed
        }

        // Update video page title immediately
        clipName = trimmed
        isEditingTitle = false
    }

    // MARK: - Delete (library only)
    func confirmDelete() {
        guard isFromLibrary else { return }
        showDeleteConfirm = true
    }

    func deleteClip() {
        guard isFromLibrary, let id = clipID else { return }

        removeClip(id: id)
        navigateToLibrary = true
    }
}

