/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that displays the contents of the music library.
*/

import MusicKit
import SwiftUI

/// A view the displays the playlists from the user's music library.
/// This view also displays the results from a library search.
struct LibraryView: View {
    
    // MARK: - Properties
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @StateObject private var searchViewModel = LibrarySearchViewModel()

    // MARK: - View
    
    var body: some View {
        VStack {
            navigationView
                .task( self.searchViewModel.loadPlaylistsAndRecentlyPlayed
                )
        }
    }
    
    private var navigationView: some View {
        NavigationView {
            navigationPrimaryView
                .navigationTitle("Library")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(role: .cancel, action: {
                            self.presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Done")
                        }
                    }
                }
        }
        .searchable(text: $searchViewModel.searchTerm)
    }
    
    private var navigationPrimaryView: some View {
        VStack(alignment: .leading) {
            libraryPlaylists
                .resignKeyboardOnDragGesture()
        }
    }
    
    @ViewBuilder
    private var librarySearchView: some View {
        if let searchResponse = searchViewModel.searchResponse {
            List {
                if !searchResponse.songs.isEmpty {
                    Section(header: Text("Songs").fontWeight(.semibold)) {
                        ForEach(searchResponse.songs) { song in
                            TrackCell(.song(song))
                        }
                    }
                }
                if !searchResponse.musicVideos.isEmpty {
                    Section(header: Text("Music Videos").fontWeight(.semibold)) {
                        ForEach(searchResponse.musicVideos) { musicVideo in
                            TrackCell(.musicVideo(musicVideo))
                        }
                    }
                }
                if !searchResponse.albums.isEmpty {
                    Section(header: Text("Albums").fontWeight(.semibold)) {
                        ForEach(searchResponse.albums) { album in
                            AlbumCell(album)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
    
    @ViewBuilder
    private var libraryPlaylists: some View {
        if searchViewModel.searchResponse != nil {
            self.librarySearchView
        } else {
            List {
                Section(header: Text("RecentlyPlayed").fontWeight(.semibold)) {
                    ForEach(self.searchViewModel.recentlyPlayed) { recentlyPlayedItem in
                        RecentlyPlayedCell(recentlyPlayedItem)
                    }
                }
//                Section(header: Text("ADs").fontWeight(.semibold)) {
//                    BannerAd(adUnitId: "ca-app-pub-5741801169601651/7785462381", maxHeight: 120)
//                        .listRowInsets(EdgeInsets())
//                        .listRowSeparator(.hidden)
//                        .listRowBackground(Color.clear)
//                        .padding(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
//                }
                Section(header: Text("Library Playlists").fontWeight(.semibold)) {
                    ForEach(self.searchViewModel.libraryPlaylists) { playlist in
                        PlaylistCell(playlist, isLibrary: true)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}
