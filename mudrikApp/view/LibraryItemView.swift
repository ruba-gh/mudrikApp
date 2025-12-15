import SwiftUI

struct LibraryItemView: View {
    @EnvironmentObject private var store: ClipsStore

    let clipID: UUID
    @Binding var navigateToLibrary: Bool

    private var clip: SavedClip? {
        store.clips.first(where: { $0.id == clipID })
    }

    var body: some View {
        if let clip {
            NavigationLink(
                destination: VideoPlayerView(
                    clipNameFromLibrary: clip.name,
                    clipID: clip.id,
                    allSavedClips: .constant([]),
                    categories: .constant([]),
                    navigateToLibrary: $navigateToLibrary
                )
            ) {
                VStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 90, height: 90)

                        Image(systemName: "video.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.orange)
                    }

                    Text(clip.name) // ✅ LIVE from store (instant rename update)
                        .font(.caption)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 90)
            }
        } else {
            EmptyView()
        }
    }
}
