import SwiftUI

// MARK: - 3. Main Library View (MVVM)
struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel

    init(allClips: Binding<[SavedClip]>, categories: Binding<[String]>) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(allClips: allClips, categories: categories))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Categories row
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button(action: {
                                // Placeholder for adding categories in LibraryView
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.2))
                                    .glassEffect()
                                    .glassEffect(.regular.interactive())
                                    .clipShape(Circle())
                            }

                            ForEach(viewModel.categories, id: \.self) { category in
                                Button(action: {
                                    viewModel.selectCategory(category)
                                }) {
                                    Text(category)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(viewModel.selectedCategory == category ? .white : .black)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 15)
                                        .background(
                                            viewModel.selectedCategory == category
                                            ? Color.orange
                                            : Color.gray.opacity(0.2)
                                        )
                                        .cornerRadius(20)
                                        .glassEffect()
                                        .glassEffect(.regular.interactive())
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }

                    // Grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 20)], spacing: 20) {
                            ForEach(viewModel.filteredClips) { clip in
                                LibraryItemView(clip: clip, allSavedClips: $viewModel.allClips, categories: $viewModel.categories)
                            }
                        }
                        .padding()
                    }

                    Spacer()

                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search", text: $viewModel.searchText)
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(25)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                }
            }
            .navigationTitle("المكتبة")
            .navigationBarTitleDisplayMode(.inline)
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
