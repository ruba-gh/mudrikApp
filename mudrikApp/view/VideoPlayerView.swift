//
//  VideoPlayerView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 12/06/1447 AH.
//

import SwiftUI
import AVKit

// MARK: - VideoPlayerView (صفحة الفيديو الرئيسية, MVVM)
struct VideoPlayerView: View {
    @StateObject private var viewModel: VideoPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: ClipsStore

    // UIKit alerts
    @State private var alertConfig: AlertConfig? = nil

    // Focus for inline editing
    @FocusState private var titleFieldFocused: Bool

    init(
        extractedText: String? = nil,
        clipNameFromLibrary: String? = nil,
        clipID: UUID? = nil,
        allSavedClips: Binding<[SavedClip]>,
        categories: Binding<[String]>,
        navigateToLibrary: Binding<Bool>
    ) {
        _viewModel = StateObject(wrappedValue: VideoPlayerViewModel(
            extractedText: extractedText,
            clipNameFromLibrary: clipNameFromLibrary,
            clipID: clipID,
            allSavedClips: allSavedClips,
            categories: categories,
            navigateToLibrary: navigateToLibrary,
            store: nil
        ))
    }

    var body: some View {
        ZStack {
            // Hidden NavigationLink to LibraryView
            NavigationLink(
                destination: LibraryView(store: store),
                isActive: $viewModel.navigateToLibrary
            ) {
                EmptyView()
            }
            .hidden()

            // Main page layout
            VStack(spacing: 20) {
                Spacer().frame(height: 18)
                // 🎥 VIDEO
                VStack(spacing: 20){
                    if let videoURL = Bundle.main.url(forResource: "avatarr", withExtension: "mp4") {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .frame(height: 350)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.orange, lineWidth: 2)
                            )
                    } else {
                        Text("فشل تحميل الفيديو: avatarr.mp4 غير موجود")
                            .foregroundColor(.red)
                            .frame(height: 350)
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)

                // ✅ pushes the content so it doesn't feel stuck to the top
                Spacer(minLength: 0)
            }
            // ✅ makes the VStack fill the screen (fixes “camped at top”)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }

        // ✅ Bottom actions pinned to bottom safely (not fighting with layout)
        .safeAreaInset(edge: .bottom) {
            HStack {
                // ✅ DELETE BUTTON (library only) - bottom left
                if viewModel.isFromLibrary {
                    Button {
                        viewModel.confirmDelete()
                    } label: {
                        Image(systemName: "trash")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                            .foregroundColor(.white)
                            .padding(22)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                }

                Spacer()

                // ✅ OCR SAVE BUTTON (OCR only) - bottom right
                if viewModel.isFromOCR {
                    Button {
                        presentClipNameAlert()
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 30)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .background(.clear)
        }

        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            // Title / Editor
            ToolbarItem(placement: .principal) {
                if viewModel.isFromLibrary && viewModel.isEditingTitle {
                    TextField("اسم المقطع", text: $viewModel.editedTitle, onCommit: {
                        viewModel.saveEditedTitle()
                    })
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 240)
                    .submitLabel(.done)
                    .focused($titleFieldFocused)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            titleFieldFocused = true
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        Text(viewModel.pageTitle)
                            .font(.headline)
                        if viewModel.isFromOCR {
                            Text("")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }

            

            // Edit / Save
            if viewModel.isFromLibrary {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditingTitle {
                        Button {
                            viewModel.saveEditedTitle()
                            titleFieldFocused = false
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    } else {
                        Button {
                            viewModel.startEditingTitle()
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            // ✅ HOME BUTTON (NO animation)
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    ContentView()
                        .environmentObject(store)
                } label: {
                    Image(systemName: "house.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                        .frame(width: 38, height: 38)
                        
                }
                .accessibilityLabel("الصفحة الرئيسية")
            }
        }
        

        .alert("هل تريد حذف الفيديو؟", isPresented: $viewModel.showDeleteConfirm) {
            Button("نعم", role: .destructive) {
                viewModel.deleteClip()
            }
            Button("إلغاء", role: .cancel) { }
        }

        .systemAlert(config: $alertConfig)

        .onAppear {
            viewModel.injectStoreIfNeeded(store)
        }
    }

    // MARK: - Alerts

    private func presentClipNameAlert() {
        viewModel.popupKind = .clipName
        viewModel.inputText = ""

        alertConfig = AlertConfig(
            title: "اسم المقطع",
            message: nil,
            preferredStyle: .alert,
            textFields: [
                AlertTextFieldConfig(
                    placeholder: "اكتب اسم المقطع",
                    text: $viewModel.inputText,
                    isSecure: false,
                    keyboardType: .default,
                    textContentType: .name
                )
            ],
            actions: [
                AlertAction("إلغاء", style: .cancel, handler: nil),
                AlertAction("التالي", style: .default, handler: {
                    viewModel.clipName = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    presentCategoryAlert()
                })
            ]
        )
    }

    private func presentCategoryAlert() {
        let categories = viewModel.categoriesForPopup
        var actions: [AlertAction] = []

        actions.append(AlertAction("إضافة تصنيف جديد", style: .default, handler: {
            presentNewCategoryAlert()
        }))

        actions.append(contentsOf: categories.map { cat in
            AlertAction(cat, style: .default, handler: {
                viewModel.selectCategoryAndSave(cat)
            })
        })

        actions.append(AlertAction("إلغاء", style: .cancel, handler: nil))

        alertConfig = AlertConfig(
            title: "اختر التصنيف",
            message: nil,
            preferredStyle: .alert,
            textFields: [],
            actions: actions
        )
    }

    private func presentNewCategoryAlert() {
        viewModel.popupKind = .categoryName
        viewModel.inputText = ""

        alertConfig = AlertConfig(
            title: "اسم التصنيف",
            message: nil,
            preferredStyle: .alert,
            textFields: [
                AlertTextFieldConfig(
                    placeholder: "اكتب اسم التصنيف",
                    text: $viewModel.inputText,
                    isSecure: false,
                    keyboardType: .default,
                    textContentType: .name
                )
            ],
            actions: [
                AlertAction("إلغاء", style: .cancel, handler: nil),
                AlertAction("حفظ", style: .default, handler: {
                    let trimmed = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if !viewModel.categories.contains(trimmed) {
                        viewModel.categories.append(trimmed)
                        StorageManager().saveCategories(viewModel.categories)
                    }
                    viewModel.selectCategoryAndSave(trimmed)
                })
            ]
        )
    }
}
