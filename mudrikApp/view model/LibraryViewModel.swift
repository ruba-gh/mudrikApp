import Foundation
import SwiftUI
import Combine

@MainActor
final class LibraryViewModel: ObservableObject {
    @Binding var allClips: [SavedClip]
    @Binding var categories: [String]

    @Published var selectedCategory: String
    @Published var searchText: String = ""

    init(allClips: Binding<[SavedClip]>, categories: Binding<[String]>) {
        self._allClips = allClips
        self._categories = categories
        let initialCategory = allClips.wrappedValue.last?.category ?? ""
        self.selectedCategory = initialCategory
        self._allClips = allClips
        self._categories = categories

        let storage = StorageManager()
        allClips.wrappedValue = storage.loadClips()
        categories.wrappedValue = storage.loadCategories().isEmpty ? categories.wrappedValue : storage.loadCategories()

        self.selectedCategory = allClips.wrappedValue.last?.category ?? ""

        
        
        
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
}
