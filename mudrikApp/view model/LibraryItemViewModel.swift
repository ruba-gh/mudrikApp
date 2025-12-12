//import Foundation
//import SwiftUI
//import Combine
//
//final class LibraryItemViewModel: ObservableObject {
//    // Input model
//    @Published private(set) var clip: SavedClip
//
//    // UI constants for this cell
//    let tileSize: CGSize = CGSize(width: 80, height: 80)
//    let cornerRadius: CGFloat = 10
//    let iconSize: CGSize = CGSize(width: 30, height: 30)
//    let backgroundColor: Color = .orange
//    let iconName: String = "play.fill"
//    let iconColor: Color = .white
//    let titleColor: Color = .black
//
//    init(clip: SavedClip) {
//        self.clip = clip
//    }
//
//    var title: String {
//        clip.name
//    }
//}



import Foundation
import SwiftUI
import Combine

final class LibraryItemViewModel: ObservableObject {
    @Published private(set) var clip: SavedClip

    let tileSize: CGSize = CGSize(width: 80, height: 80)
    let cornerRadius: CGFloat = 10
    let iconSize: CGSize = CGSize(width: 30, height: 30)
    let backgroundColor: Color = .orange
    let iconName: String = "play.fill"
    let iconColor: Color = .white
    let titleColor: Color = .black

    init(clip: SavedClip) {
        self.clip = clip
    }

    var title: String { clip.name }
}
