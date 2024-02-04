/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A view that allows music searches.
*/

import MusicKit
import SwiftUI

/// The top-level tab view when searching for music.
struct MusicView: View {
    
    // MARK: - Properties
    
    @State var tabIndex = 0
    
    // MARK: - View
    
    var body: some View {
        TabView {
            LibraryView()
                .tabItem {
                    Text("Library")
                    Image(systemName: "music.note.house")
                }
            SearchView()
                .tabItem {
                    Text("Search")
                    Image(systemName: "magnifyingglass")
                }
        }
    }
}

