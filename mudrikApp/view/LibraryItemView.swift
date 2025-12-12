//
//  LibraryItemView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 12/06/1447 AH.

////
//import SwiftUI
//
//// MARK: - Library Item View (MVVM)
//struct LibraryItemView: View {
//    @StateObject private var viewModel: LibraryItemViewModel
//
//    // These remain as bindings because navigation destination needs them
//    @Binding var allSavedClips: [SavedClip]
//    @Binding var categories: [String]
//
//    init(clip: SavedClip, allSavedClips: Binding<[SavedClip]>, categories: Binding<[String]>) {
//        _viewModel = StateObject(wrappedValue: LibraryItemViewModel(clip: clip))
//        self._allSavedClips = allSavedClips
//        self._categories = categories
//    }
//    
//
//    var body: some View {
//        NavigationLink(
//            destination: VideoPlayerView(
//                clipNameFromLibrary: viewModel.title,
//                allSavedClips: $allSavedClips,
//                categories: $categories,
//                navigateToLibrary: .constant(false)
//            )
//        ) {
//            VStack(spacing: 8) {
//                ZStack {
//                    RoundedRectangle(cornerRadius: viewModel.cornerRadius)
//                        .fill(viewModel.backgroundColor)
//                        .frame(width: viewModel.tileSize.width, height: viewModel.tileSize.height)
//
//                    Image(systemName: viewModel.iconName)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: viewModel.iconSize.width, height: viewModel.iconSize.height)
//                        .foregroundColor(viewModel.iconColor)
//                }
//
//                Text(viewModel.title)
//                    .font(.caption)
//                    .foregroundColor(viewModel.titleColor)
//                    .multilineTextAlignment(.center)
//            }
//            .frame(width: viewModel.tileSize.width)
//        }
//    }
//}
//////
//////
//////
import SwiftUI

// MARK: - Library Item View (MVVM)
struct LibraryItemView: View {
    @StateObject private var viewModel: LibraryItemViewModel

    // Bindings مطلوبة للتنقل والتعديل
    @Binding var allSavedClips: [SavedClip]
    @Binding var categories: [String]

    init(
        clip: SavedClip,
        allSavedClips: Binding<[SavedClip]>,
        categories: Binding<[String]>
    ) {
        _viewModel = StateObject(wrappedValue: LibraryItemViewModel(clip: clip))
        self._allSavedClips = allSavedClips
        self._categories = categories
    }

    var body: some View {
        NavigationLink(
            destination: VideoPlayerView(
                // ⚠️ الترتيب هنا مهم جدًا
                clipNameFromLibrary: viewModel.clip.name,
                clipID: viewModel.clip.id,
                allSavedClips: $allSavedClips,
                categories: $categories,
                navigateToLibrary: .constant(false)
            )
        ) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: viewModel.cornerRadius)
                        .fill(viewModel.backgroundColor)
                        .frame(
                            width: viewModel.tileSize.width,
                            height: viewModel.tileSize.height
                        )

                    Image(systemName: viewModel.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: viewModel.iconSize.width,
                            height: viewModel.iconSize.height
                        )
                        .foregroundColor(viewModel.iconColor)
                }

                Text(viewModel.clip.name)
                    .font(.caption)
                    .foregroundColor(viewModel.titleColor)
                    .multilineTextAlignment(.center)
            }
            .frame(width: viewModel.tileSize.width)
        }
    }
}

