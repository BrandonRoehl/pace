/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A cell that displays music track information.
*/

import Combine
import MusicKit
import SwiftUI

/// A  cell that displays music track data.
struct TrackCell: View {
    
    @ObservedObject private var playlistConstructor = PlaylistConstructor.shared
    @State private var contains: Bool = false

    // MARK: - Initialization
    
    init(_ track: Track) {
        self.track = track
        self.trackList = nil
        self.parentCollectionID = nil
        self.parentCollectionArtistName = nil
        self.shouldDisplayArtwork = true
    }
    
    init(_ track: Track, from artist: Artist) {
        self.track = track
        self.trackList = nil
        self.parentCollectionID = artist.id
        self.parentCollectionArtistName = artist.name
        self.shouldDisplayArtwork = true
    }
    
    init(_ track: Track, from album: Album) {
        self.track = track
        self.trackList = album.tracks
        self.parentCollectionID = album.id
        self.parentCollectionArtistName = album.artistName
        self.shouldDisplayArtwork = false
    }
    
    init(_ track: Track, from playlist: Playlist) {
        self.track = track
        self.trackList = playlist.tracks
        self.parentCollectionID = playlist.id
        self.parentCollectionArtistName = playlist.curatorName
        self.shouldDisplayArtwork = true
    }
    
    // MARK: - Properties
    
    let track: Track
    let trackList: MusicItemCollection<Track>?
    let parentCollectionID: MusicItemID?
    let parentCollectionArtistName: String?
    let shouldDisplayArtwork: Bool
    
    private var subtitle: String {
        var subtitle = ""
        if track.artistName != parentCollectionArtistName {
            subtitle = track.artistName
        }
        return subtitle
    }
    
    // MARK: - View
    
    var body: some View {
        HStack(alignment: .center) {
            MusicItemCell(
                artwork: self.shouldDisplayArtwork ? track.artwork : nil,
                artworkSize: self.shouldDisplayArtwork ? 40 : 0,
                title: track.title,
                subtitle: subtitle
            )
            .frame(minHeight: Self.minimumHeight)
            Spacer()
            Button(role: self.contains ? .destructive : nil, action: {
                if self.contains {
                    self.playlistConstructor.removeTrack(self.track)
                } else {
                    self.playlistConstructor.addTrack(self.track)
                }
            }) {
                Label("", systemImage: self.contains ? "minus" : "plus")
            }
            .foregroundColor(self.contains ? .red : .accentColor)
            .padding(.vertical, 5)
        }
        .onReceive(self.playlistConstructor.$tracks.debounce(for: .seconds(0.2), scheduler: RunLoop.main), perform: { (tracks: [TrackPace]) in
            self.contains = tracks.contains { (lhs: TrackPace) in
                lhs == self.track
            }
        })
        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
    }
    
    // MARK: - Constants
    
    private static let minimumHeight: CGFloat? = 50
    
}
