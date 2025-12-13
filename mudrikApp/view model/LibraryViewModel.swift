import Foundation
import SwiftUI
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Binding var allClips: [SavedClip]
    @Binding var categories: [String]

    @Published var selectedCategory: String
    @Published var searchText: String = ""

    // Popups for category management
    @Published var showTextFieldAlert: Bool = false
    @Published var textFieldKind: PopupKind = .categoryName
    @Published var textFieldValue: String = ""
    @Published var showDeleteConfirm: Bool = false

    // New: pending category name for delete via context menu
    @Published var pendingDeleteCategory: String? = nil
    @Published var showPendingDeleteConfirm: Bool = false

    // Constants
    let defaultCategory = "المكتبة"

    init(allClips: Binding<[SavedClip]>, categories: Binding<[String]>) {
        self._allClips = allClips
        self._categories = categories

        // Do NOT reload from disk here — ClipsStore loads once and publishes changes.
        // Ensure default category exists
        if !categories.wrappedValue.contains(defaultCategory) {
            categories.wrappedValue.insert(defaultCategory, at: 0)
        }

        // Initial selection: last clip’s category or default
        let initialCategory = allClips.wrappedValue.last?.category ?? defaultCategory
        self.selectedCategory = initialCategory
    }

    var filteredClips: [SavedClip] {
        let clipsByCategory = allClips.filter { clip in
            selectedCategory.isEmpty || clip.category == selectedCategory
        }

        if searchText.isEmpty {
            return clipsByCategory
        } else {
            return clipsByCategory.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

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
        categories.append(name)
        persistCategories()
        // Switch to it
        selectedCategory = name
        showTextFieldAlert = false
    }

    func beginRenameSelectedCategory() {
        guard canRenameOrDelete(selectedCategory) else { return }
        textFieldKind = .categoryName
        textFieldValue = selectedCategory
        showTextFieldAlert = true
    }

    func confirmRenameSelectedCategory() {
        let newName = textFieldValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let oldName = selectedCategory
        guard canRenameOrDelete(oldName) else { return }
        guard validateRename(from: oldName, to: newName) else { return }
        renameCategory(from: oldName, to: newName)
        showTextFieldAlert = false
    }

    func beginDeleteSelectedCategory() {
        guard canRenameOrDelete(selectedCategory) else { return }
        showDeleteConfirm = true
    }

    func confirmDeleteSelectedCategory() {
        deleteCategory(name: selectedCategory, reassignTo: defaultCategory)
        showDeleteConfirm = false
    }

    // New: begin/confirm delete for a specific category (from context menu)
    func beginDelete(category name: String) {
        guard canRenameOrDelete(name) else { return }
        pendingDeleteCategory = name
        showPendingDeleteConfirm = true
    }

    func confirmDeletePendingCategory() {
        guard let name = pendingDeleteCategory else { return }
        deleteCategory(name: name, reassignTo: defaultCategory)
        // Clear pending state
        pendingDeleteCategory = nil
        showPendingDeleteConfirm = false
    }

    // MARK: - Internal helpers

    private func renameCategory(from oldName: String, to newName: String) {
        // Update categories array
        if let idx = categories.firstIndex(of: oldName) {
            categories[idx] = newName
        } else {
            return
        }

        // Update clips
        for i in allClips.indices {
            if allClips[i].category == oldName {
                allClips[i].category = newName
            }
        }

        // Update selection
        if selectedCategory == oldName {
            selectedCategory = newName
        }

        persistAll()
    }

    private func deleteCategory(name: String, reassignTo fallback: String) {
        // Ensure fallback exists
        if !categories.contains(fallback) {
            categories.insert(fallback, at: 0)
        }

        // Reassign clips
        for i in allClips.indices {
            if allClips[i].category == name {
                allClips[i].category = fallback
            }
        }

        // Remove category
        categories.removeAll { $0 == name }

        // Update selection if needed
        if selectedCategory == name {
            selectedCategory = fallback
        }

        persistAll()
    }

    private func validateNewCategoryName(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        guard !categories.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) else { return false }
        return true
    }

    private func validateRename(from old: String, to new: String) -> Bool {
        guard !new.isEmpty else { return false }
        guard old != new else { return false }
        guard !categories.contains(where: { $0.caseInsensitiveCompare(new) == .orderedSame }) else { return false }
        return true
    }

    // Was `private`; make it internal so LibraryView can call it
    func canRenameOrDelete(_ name: String) -> Bool {
        // Protect the default category
        return name != defaultCategory
    }

    private func persistCategories() {
        StorageManager().saveCategories(categories)
    }

    private func persistAll() {
        StorageManager().saveCategories(categories)
        StorageManager().saveClips(allClips)
    }
}
