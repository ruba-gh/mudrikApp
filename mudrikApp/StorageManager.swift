//
//  StorageManager.swift
//  mudrikApp
//
//  Created by wasan jayid althagafi on 18/06/1447 AH.
//
//
//import Foundation
//
//final class StorageManager {
//    static let shared = StorageManager()
//    private init() {}
//
//    private let clipsKey = "mudrik_saved_clips"
//    private let categoriesKey = "mudrik_saved_categories"
//
//    // MARK: - Clips
//
//    func saveClips(_ clips: [SavedClip]) {
//        do {
//            let data = try JSONEncoder().encode(clips)
//            UserDefaults.standard.set(data, forKey: clipsKey)
//        } catch {
//            print("❌ Failed to save clips:", error)
//        }
//    }
//
//    func loadClips() -> [SavedClip] {
//        guard let data = UserDefaults.standard.data(forKey: clipsKey) else {
//            return []
//        }
//        do {
//            return try JSONDecoder().decode([SavedClip].self, from: data)
//        } catch {
//            print("❌ Failed to load clips:", error)
//            return []
//        }
//    }
//
//    // MARK: - Categories
//
//    func saveCategories(_ categories: [String]) {
//        UserDefaults.standard.set(categories, forKey: categoriesKey)
//    }
//
//    func loadCategories(defaults: [String]) -> [String] {
//        if let stored = UserDefaults.standard.stringArray(forKey: categoriesKey),
//           !stored.isEmpty {
//            return stored
//        }
//        return defaults
//    }
//}


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
