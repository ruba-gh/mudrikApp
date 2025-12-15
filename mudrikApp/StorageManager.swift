//

//

import Foundation

final class StorageManager {
    
    private let clipsKey = "savedClips_key"
    private let categoriesKey = "categories_key"

    // MARK: - Save Clips
    func saveClips(_ clips: [SavedClip]) {
        if let encoded = try? JSONEncoder().encode(clips) {
            UserDefaults.standard.set(encoded, forKey: clipsKey)
        }
    }

    // MARK: - Load Clips
    func loadClips() -> [SavedClip] {
        guard let data = UserDefaults.standard.data(forKey: clipsKey),
              let decoded = try? JSONDecoder().decode([SavedClip].self, from: data)
        else { return [] }
        return decoded
    }

    // MARK: - Save Categories
    func saveCategories(_ categories: [String]) {
        UserDefaults.standard.set(categories, forKey: categoriesKey)
    }

    // MARK: - Load Categories
    func loadCategories() -> [String] {
        UserDefaults.standard.array(forKey: categoriesKey) as? [String] ?? []
    }
}
