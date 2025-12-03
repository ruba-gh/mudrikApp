//
//  SavedClip.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 12/06/1447 AH.
//

import Foundation

struct SavedClip: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var category: String
}
