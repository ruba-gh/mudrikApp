import SwiftUI
import Foundation
import SwiftUI
import Combine

@MainActor

    final class LibraryViewModel: ObservableObject {

        @Published var selectedCategory = "المكتبة"
        @Published var searchText = ""

        // UI state
        @Published var showTextFieldAlert = false
        @Published var textFieldValue = ""
        @Published var showDeleteConfirm = false

        @Published var pendingDeleteCategory: String?
        @Published var showPendingDeleteConfirm = false

        // Add missing kind for TextFieldAlert
        @Published var textFieldKind: PopupKind = .categoryName

    let defaultCategory = "المكتبة"

    private unowned let store: ClipsStore

    init(store: ClipsStore) {
        self.store = store

        // Ensure default exists
        if !store.categories.contains(defaultCategory) {
            store.categories.insert(defaultCategory, at: 0)
        }

        self.selectedCategory = store.clips.last?.category ?? defaultCategory
    }

    var filteredClips: [SavedClip] {
        let clipsByCategory = store.clips.filter { clip in
            selectedCategory.isEmpty || clip.category == selectedCategory
        }

        if searchText.isEmpty {
            return clipsByCategory
        } else {
            return clipsByCategory.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var categories: [String] { store.categories }

    func selectCategory(_ category: String) {
        selectedCategory = category
    }

    // MARK: - Category Management

    func beginAddCategory() {
        textFieldKind = .categoryName
        textFieldValue = ""
        showTextFieldAlert = true
    }

    func confirmAddCategory() {
        let name = textFieldValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard validateNewCategoryName(name) else { return }

        store.categories.append(name)
        persistCategories()

        selectedCategory = name
        showTextFieldAlert = false
    }

    func beginDelete(category name: String) {
        guard canRenameOrDelete(name) else { return }
        pendingDeleteCategory = name
        showPendingDeleteConfirm = true
    }

    func confirmDeletePendingCategory() {
        guard let name = pendingDeleteCategory else { return }
        deleteCategory(name: name, reassignTo: defaultCategory)
        pendingDeleteCategory = nil
        showPendingDeleteConfirm = false
    }

    func confirmDeleteSelectedCategory() {
        deleteCategory(name: selectedCategory, reassignTo: defaultCategory)
        showDeleteConfirm = false
    }

    func beginDeleteSelectedCategory() {
        guard canRenameOrDelete(selectedCategory) else { return }
        showDeleteConfirm = true
    }

    func canRenameOrDelete(_ name: String) -> Bool {
        name != defaultCategory
    }

    // MARK: - Helpers

    private func deleteCategory(name: String, reassignTo fallback: String) {
        if !store.categories.contains(fallback) {
            store.categories.insert(fallback, at: 0)
        }

        // Reassign clips
        for i in store.clips.indices {
            if store.clips[i].category == name {
                store.clips[i].category = fallback
            }
        }

        // Remove category
        store.categories.removeAll { $0 == name }

        if selectedCategory == name {
            selectedCategory = fallback
        }

        persistAll()
    }

    private func validateNewCategoryName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        guard !store.categories.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else { return false }
        return true
    }

    private func persistCategories() {
        StorageManager().saveCategories(store.categories)
    }

    private func persistAll() {
        StorageManager().saveCategories(store.categories)
        StorageManager().saveClips(store.clips)
    }
}
