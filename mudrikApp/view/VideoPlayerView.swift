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

    init(
        extractedText: String? = nil,
        clipNameFromLibrary: String? = nil,
        clipID: UUID? = nil, // ✅ الجديد
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
            navigateToLibrary: navigateToLibrary
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

            Color.white.ignoresSafeArea()

            VStack(spacing: 20) {

                // 🎥 VIDEO
                VStack {
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

                Spacer()

                // ✅ OCR SAVE BUTTON
                if viewModel.isFromOCR {
                    Button(action: {
                        presentClipNameAlert()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                            .padding(20)
                            .background(Color.orange)
                            .clipShape(Circle())
                    }
                    .padding(.bottom, 30)
                    .padding(.trailing, 30)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                // ✅ DELETE BUTTON (للمحفوظ فقط)
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
                    .padding(.bottom, 30)
                    .padding(.leading, 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .navigationTitle(viewModel.pageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.isFromLibrary {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isEditingTitle {
                        Button {
                            viewModel.saveEditedTitle()
                        } label: {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                        .accessibilityLabel("حفظ العنوان")
                    } else {
                        Button {
                            viewModel.startEditingTitle()
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.orange)
                        }
                        .accessibilityLabel("تعديل العنوان")
                    }
                }
            }
        }
        // ✅ حذف
        .alert("هل تريد حذف الفيديو؟", isPresented: $viewModel.showDeleteConfirm) {
            Button("نعم", role: .destructive) {
                viewModel.deleteClip()
            }
            Button("إلغاء", role: .cancel) { }
        }
        // System alert presenter
        .systemAlert(config: $alertConfig)
    }

    // MARK: - Alerts / Sheets (UIKit)

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
                    // After entering clip name, show category picker as a centered alert
                    viewModel.clipName = viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                    presentCategoryAlert()
                })
            ]
        )
    }

    private func presentCategoryAlert() {
        let categories = viewModel.categoriesForPopup

        var actions: [AlertAction] = []

        // 1) Put "Add new category" first
        actions.append(AlertAction("إضافة تصنيف جديد", style: .default, handler: {
            presentNewCategoryAlert()
        }))

        // 2) Then list existing categories
        actions.append(contentsOf: categories.map { cat in
            AlertAction(cat, style: .default, handler: {
                viewModel.selectCategoryAndSave(cat)
            })
        })

        // 3) Finally, Cancel
        actions.append(AlertAction("إلغاء", style: .cancel, handler: nil))

        alertConfig = AlertConfig(
            title: "اختر التصنيف",
            message: nil,
            preferredStyle: .alert, // centered on iPhone
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
                AlertAction("إلغاء", style: .cancel, handler: {
                    // Optionally return to category choices:
                    // presentCategoryAlert()
                }),
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
