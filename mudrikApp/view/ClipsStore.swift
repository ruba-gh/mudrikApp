import Foundation
import Combine

@MainActor
final class ClipsStore: ObservableObject {
    @Published var clips: [SavedClip]
    @Published var categories: [String]

    private let storage = StorageManager()
    private let defaultCategory = "المكتبة"

    init() {
        // Load once; no conditional assignment that blocks updates
        let loadedClips = storage.loadClips()
        let loadedCategories = storage.loadCategories()

        // Ensure default category exists
        var cats = loadedCategories
        if !cats.contains(defaultCategory) {
            cats.insert(defaultCategory, at: 0)
        }

        self.clips = loadedClips
        self.categories = cats

        // Persist categories once if we inserted default
        storage.saveCategories(self.categories)
    }

    // MARK: - Clips mutations

    func addClip(name: String, category: String, videoFileName: String) {
        ensureCategoryExists(category)
        let newClip = SavedClip(name: name, category: category, videoFileName: videoFileName)
        clips.append(newClip)
        persistClips()
    }

    func updateClipTitle(id: UUID, newTitle: String) {
        guard let idx = clips.firstIndex(where: { $0.id == id }) else { return }
        clips[idx].name = newTitle
        persistClips()
    }

    func deleteClip(id: UUID) {
        clips.removeAll { $0.id == id }
        persistClips()
    }

    // MARK: - Categories mutations

    func ensureCategoryExists(_ category: String) {
        if !categories.contains(category) {
            categories.append(category)
            persistCategories()
        }
    }

    func addCategory(_ name: String) {
        guard !name.isEmpty else { return }
        if !categories.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            categories.append(name)
            persistCategories()
        }
    }

    func renameCategory(from old: String, to new: String) {
        guard !new.isEmpty, old != new else { return }
        guard let idx = categories.firstIndex(of: old) else { return }
        guard !categories.contains(where: { $0.caseInsensitiveCompare(new) == .orderedSame }) else { return }

        categories[idx] = new
        for i in clips.indices {
            if clips[i].category == old {
                clips[i].category = new
            }
        }
        persistAll()
    }

    func deleteCategory(_ name: String, reassignTo fallback: String = "المكتبة") {
        // Ensure fallback exists
        ensureCategoryExists(fallback)

        // Reassign clips
        for i in clips.indices {
            if clips[i].category == name {
                clips[i].category = fallback
            }
        }

        categories.removeAll { $0 == name }
        persistAll()
    }

    // MARK: - Persistence

    private func persistClips() {
        storage.saveClips(clips)
    }

    private func persistCategories() {
        storage.saveCategories(categories)
    }

    private func persistAll() {
        persistCategories()
        persistClips()
    }
    func persistAllPublic() { // rename however you like
        storage.saveCategories(categories)
        storage.saveClips(clips)
    }
    func persistCategoriesPublic() {
        storage.saveCategories(categories)
    }
}
