import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: ClipsStore
    @StateObject private var viewModel: LibraryViewModel

    @State private var navigateToLibrary = false

    // Explicit init that injects the environment store into the view model
    init(store: ClipsStore) {
        _viewModel = StateObject(wrappedValue: LibraryViewModel(store: store))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("التصنيفات")
                        .font(.headline)
                        .foregroundColor(.black)
                    Spacer()
                    Button {
                        viewModel.beginAddCategory()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)

                // Categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(store.categories, id: \.self) { category in
                            Button {
                                viewModel.selectCategory(category)
                            } label: {
                                Text(category)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(viewModel.selectedCategory == category ? .white : .black)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 15)
                                    .background(viewModel.selectedCategory == category ? Color.orange : Color.gray.opacity(0.2))
                                    .cornerRadius(20)
                            }
                            .contextMenu {
                                if viewModel.canRenameOrDelete(category) {
                                    Button(role: .destructive) {
                                        viewModel.beginDelete(category: category)
                                    } label: {
                                        Label("حذف التصنيف", systemImage: "trash")
                                    }
                                } else {
                                    Label("التصنيف الافتراضي", systemImage: "lock.fill")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                }

                // Grid
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 80), spacing: 20)],
                        spacing: 20
                    ) {
                        ForEach(viewModel.filteredClips) { clip in
                            LibraryItemView(
                                clip: clip,
                                navigateToLibrary: $navigateToLibrary
                            )
                        }
                    }
                    .padding()
                }

                Spacer()

                // Search
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

            // Add Category popup
            if viewModel.showTextFieldAlert {
                Color.black.opacity(0.45).ignoresSafeArea()

                TextFieldAlert(
                    kind: viewModel.textFieldKind,
                    text: $viewModel.textFieldValue,
                    onCancel: { viewModel.showTextFieldAlert = false },
                    onConfirm: { viewModel.confirmAddCategory() }
                )
            }
        }
        .navigationTitle("المكتبة")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .alert("حذف التصنيف؟", isPresented: $viewModel.showDeleteConfirm) {
            Button("نعم", role: .destructive) { viewModel.confirmDeleteSelectedCategory() }
            Button("إلغاء", role: .cancel) { }
        }
        .alert("حذف التصنيف؟", isPresented: $viewModel.showPendingDeleteConfirm) {
            Button("نعم", role: .destructive) { viewModel.confirmDeletePendingCategory() }
            Button("إلغاء", role: .cancel) { }
        } message: {
            if let name = viewModel.pendingDeleteCategory {
                Text("سيتم نقل المقاطع إلى '\(viewModel.defaultCategory)' ثم حذف '\(name)'.")
            } else {
                Text("سيتم نقل المقاطع إلى '\(viewModel.defaultCategory)'.")
            }
        }
    }
}
