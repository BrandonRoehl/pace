/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model class that holds music library search data.
*/

import Combine
import MusicKit
import SwiftUI

/// An object that performs a library search request when given a search term and holds the results.
class LibrarySearchViewModel: ObservableObject {
    
    // MARK: - Initialization
    
    init() {
        searchTermObserver = $searchTerm
            .sink(receiveValue: librarySearch)
    }
    
    // MARK: - Properties
    
    @Published var searchTerm = ""
    
    @Published private(set) var searchResponse: MusicLibrarySearchResponse?
    @Published private(set) var isDisplayingSuggestedPlaylists = false
    
    @Published private(set) var libraryPlaylists: MusicItemCollection<Playlist> = []
    @Published private(set) var recentlyPlayed: MusicItemCollection<RecentlyPlayedMusicItem> = []

    
    private var searchTermObserver: AnyCancellable?
    
    // MARK: - Methods
    
    /// Creates and performs a music library search when the search term changes.
    func librarySearch(for searchTerm: String) {
        if searchTerm.isEmpty {
            isDisplayingSuggestedPlaylists = true
            searchResponse = nil
        } else {
            Task {
                let librarySearchRequest = MusicLibrarySearchRequest(
                    term: searchTerm,
                    types: [
                        Song.self,
                        MusicVideo.self,
                        Album.self
                    ]
                )
                do {
                    let librarySearchResponse = try await librarySearchRequest.response()
                    await self.update(with: librarySearchResponse, for: searchTerm)
                } catch {
                    print("Failed to load library search results due to error: \(error).")
                }
            }
        }
    }
    
    /// Safely updates the `searchResponse` on the main thread.
    @MainActor
    func update(with libraryResponse: MusicLibrarySearchResponse, for searchTerm: String) {
        if self.searchTerm == searchTerm {
            self.searchResponse = libraryResponse
        }
    }
    
    @MainActor
    func update(playlists libraryPlaylists: MusicItemCollection<Playlist>) {
        self.libraryPlaylists = libraryPlaylists
    }
    
    @MainActor
    func update(recentlyPlayed: MusicItemCollection<RecentlyPlayedMusicItem>) {
        self.recentlyPlayed = recentlyPlayed
    }
    
    /// Load Playlists from the users Library
    @Sendable
    func loadPlaylistsAndRecentlyPlayed() async {
        await withTaskGroup(of: Void.self) { taskGroup in
            taskGroup.addTask(priority: .userInitiated) {
                let recentlyPlayedRequest = MusicRecentlyPlayedContainerRequest()
                let recentlyPlayedResponse = try? await recentlyPlayedRequest.response()
                if let recents = recentlyPlayedResponse?.items {
                    await self.update(recentlyPlayed: recents)
                }
            }
            taskGroup.addTask(priority: .userInitiated) {
                let request = MusicLibraryRequest<Playlist>()
                let response = try? await request.response()
                if let playlists = response?.items {
                    await self.update(playlists: playlists)
                }
            }
            await taskGroup.waitForAll()
        }
    }
}
