import SwiftUI

// MARK: - 3. Main Library View
struct LibraryView: View {
    @Binding var allClips: [SavedClip]
    @Binding var categories: [String]
    
    @State private var selectedCategory: String
    @State private var searchText: String = ""
    
    init(allClips: Binding<[SavedClip]>, categories: Binding<[String]>) {
        self._allClips = allClips
        self._categories = categories
        
        let initialCategory = allClips.wrappedValue.last?.category ?? ""
        self._selectedCategory = State(initialValue: initialCategory)
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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack(alignment: .top) {
                        Button(action: {
                            // TODO: Back action (dismiss or pop)
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(10)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .padding(.leading, 10)
                        
                        Spacer()
                        
                        Button(action: {
                            // "All clips" or forward action if you want
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(10)
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3)
                        }
                        .padding(.trailing, 10)
                    }
                    .padding(.top, 10)
                    
                    // Categories row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button(action: {
                                // TODO: Add new category
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                            
                            ForEach(categories, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    Text(category)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(selectedCategory == category ? .white : .black)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 15)
                                        .background(
                                            selectedCategory == category
                                            ? Color.orange
                                            : Color.gray.opacity(0.2)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 20)], spacing: 20) {
                            ForEach(filteredClips) { clip in
                                LibraryItemView(clip: clip, allSavedClips: $allClips, categories: $categories)
                            }
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: $searchText)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(25)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
                .navigationBarHidden(true)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var clips: [SavedClip] = [
            SavedClip(name: "مقطع 1", category: "قصص"),
            SavedClip(name: "مقطع 2", category: "مقابلات"),
            SavedClip(name: "مقطع 3", category: "قصص")
        ]
        @State private var cats: [String] = ["قصص", "مقابلات"]
        
        var body: some View {
            LibraryView(allClips: $clips, categories: $cats)
        }
    }
    return PreviewWrapper()
}
