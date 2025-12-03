//
//  LibraryItemView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 12/06/1447 AH.
//

import SwiftUI

// MARK: - 2. Library Item View (مربع الفيديو البرتقالي)
struct LibraryItemView: View {
    let clip: SavedClip
    @Binding var allSavedClips: [SavedClip]
    @Binding var categories: [String]
    
    var body: some View {
        NavigationLink(
            destination: VideoPlayerView(
                clipNameFromLibrary: clip.name,
                allSavedClips: $allSavedClips,
                categories: $categories,
                navigateToLibrary: .constant(false)
            )
        ) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "play.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.white)
                }
                
                Text(clip.name)
                    .font(.caption)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 80)
        }
    }
}
