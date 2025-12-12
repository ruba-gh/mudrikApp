


import Foundation

struct SavedClip: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var videoFileName: String   // Ex: "avatarr.mp4"

    init(id: UUID = UUID(), name: String, category: String, videoFileName: String = "avatarr.mp4") {
        self.id = id
        self.name = name
        self.category = category
        self.videoFileName = videoFileName
    }
}





//
//
//struct SavedClip: Identifiable, Codable, Hashable {
//    let id: UUID
//    var name: String
//    var category: String
//    var videoFileName: String
//
//    init(
//        id: UUID = UUID(),
//        name: String,
//        category: String,
//        videoFileName: String = "avatarr.mp4"
//    ) {
//        self.id = id
//        self.name = name
//        self.category = category
//        self.videoFileName = videoFileName
//    }
//}

