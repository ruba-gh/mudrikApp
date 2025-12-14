import SwiftUI

struct LibraryItemView: View {
    @StateObject private var viewModel: LibraryItemViewModel

    @Binding var navigateToLibrary: Bool

    init(clip: SavedClip, navigateToLibrary: Binding<Bool>) {
        _viewModel = StateObject(wrappedValue: LibraryItemViewModel(clip: clip))
        self._navigateToLibrary = navigateToLibrary
    }

    var body: some View {
        NavigationLink(
            destination: VideoPlayerView(
                clipNameFromLibrary: viewModel.clip.name,
                clipID: viewModel.clip.id,
                allSavedClips: .constant([]),      // ✅ will be passed from parent store in LibraryView
                categories: .constant([]),         // ✅ will be passed from parent store in LibraryView
                navigateToLibrary: $navigateToLibrary
            )
        ) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: viewModel.cornerRadius)
                        .fill(viewModel.backgroundColor)
                        .frame(width: viewModel.tileSize.width, height: viewModel.tileSize.height)

                    Image(systemName: viewModel.iconName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: viewModel.iconSize.width, height: viewModel.iconSize.height)
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
