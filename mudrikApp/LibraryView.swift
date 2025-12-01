//
//  LibraryView.swift
//  mudrikApp
//
//  Created by Ruba Alghamdi on 10/06/1447 AH.
//

import SwiftUI

struct LibraryView: View {
  
    let category: String?
    init(category: String? = nil) {
        self.category = category
        }
    
    var body: some View {
        
        
        Text("Library for: \(category)")
                    .font(.title)
            
        }
    }

#Preview {
    LibraryView()
}

