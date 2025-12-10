//
//  SavedClip.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 12/06/1447 AH.
//
//
//import Foundation
//
//struct SavedClip: Identifiable, Hashable {
//    let id = UUID()
//    var name: String
//    var category: String
//}


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
