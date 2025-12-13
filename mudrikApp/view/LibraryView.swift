import SwiftUI

struct LibraryView: View {
    @StateObject private var viewModel: LibraryViewModel
    @Environment(\.dismiss) private var dismiss

    init(allClips: Binding<[SavedClip]>, categories: Binding<[String]>) {
        _viewModel = StateObject(
            wrappedValue: LibraryViewModel(
                allClips: allClips,
                categories: categories
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.white.ignoresSafeArea()

                VStack(spacing: 0) {

                    // التصنيفات
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(viewModel.categories, id: \.self) { category in
                                Button {
                                    viewModel.selectCategory(category)
                                } label: {
                                    Text(category)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(
                                            viewModel.selectedCategory == category
                                            ? .white
                                            : .black
                                        )
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 15)
                                        .background(
                                            viewModel.selectedCategory == category
                                            ? Color.orange
                                            : Color.gray.opacity(0.2)
                                        )
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                    }

                    // الشبكة
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 80), spacing: 20)],
                            spacing: 20
                        ) {
                            ForEach(viewModel.filteredClips) { clip in
                                LibraryItemView(
                                    clip: clip,
                                    allSavedClips: $viewModel.allClips,
                                    categories: $viewModel.categories
                                )
                            }
                        }
                        .padding()
                    }

                    Spacer()

                    // البحث
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        // Always go back to ContentView
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.backward")
                            Text("الرئيسية")
                        }
                        .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}
