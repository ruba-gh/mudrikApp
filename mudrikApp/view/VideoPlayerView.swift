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

                // =========================
                // ✅ HEADER
                // =========================
                if viewModel.isFromOCR {
                    HStack {
                        Spacer()
                        Text(viewModel.pageTitle)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.top, 20)
                } else {
                    HStack(spacing: 12) {
                        Spacer()

                        if viewModel.isEditingTitle {
                            TextField("", text: $viewModel.editedTitle)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 240)

                            Button {
                                viewModel.saveEditedTitle()
                            } label: {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 20, weight: .bold))
                            }
                        } else {
                            Text(viewModel.pageTitle)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)

                            Button {
                                viewModel.startEditingTitle()
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundColor(.orange)
                                    .font(.system(size: 18, weight: .semibold))
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 16)
                }

                // =========================
                // 🎥 VIDEO
                // =========================
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

                // =========================
                // ✅ OCR SAVE BUTTON (كما كان)
                // =========================
                if viewModel.isFromOCR {
                    Button(action: {
                        viewModel.onTapSaveButton()
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

                // =========================
                // ✅ DELETE BUTTON (للمحفوظ فقط)
                // =========================
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

            // =========================
            // ✅ CATEGORY POPUP (كما كان)
            // =========================
            if viewModel.showCategoryPopup {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()

                CategoryPopup(
                    categories: viewModel.categoriesForPopup,
                    onAddNewCategory: {
                        viewModel.addNewCategoryFlow()
                    },
                    onCategoryTap: { category in
                        viewModel.selectCategoryAndSave(category)
                    }
                )
            }

            // =========================
            // ✅ TEXTFIELD POPUP (كما كان)
            // =========================
            if viewModel.showSavePopup {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()

                TextFieldAlert(
                    kind: viewModel.popupKind,
                    text: $viewModel.inputText,
                    onCancel: {
                        viewModel.showSavePopup = false
                    },
                    onConfirm: {
                        viewModel.handleTextFieldConfirm()
                    }
                )
            }
        }
        // ✅ تأكيد الحذف
        .alert("هل تريد حذف الفيديو؟", isPresented: $viewModel.showDeleteConfirm) {
            Button("نعم", role: .destructive) {
                viewModel.deleteClip()
            }
            Button("إلغاء", role: .cancel) { }
        }
        // Show the system back button
        .navigationBarBackButtonHidden(false)
    }
}
