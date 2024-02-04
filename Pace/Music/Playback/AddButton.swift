/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A SwiftUI view that implements the play button.
*/

import MusicKit
import SwiftUI

/// A view that toggles playback for a given music item.
struct AddButton: View {
    
    // MARK: - Initialization
    
    init(tracks: MusicItemCollection<Track>) {
        self.tracks = tracks
    }
    
    // MARK: - Properties
    
    private var tracks: MusicItemCollection<Track>
    
    @ObservedObject private var playlistConstructor = PlaylistConstructor.shared
    
    // Contains all of these tracks in the playlist constructor
    @State private var contains: Bool = false
    
    // MARK: - View
    
    var body: some View {
        Button(action: self.contains ? self.removeAllTracks : self.addAllTracks) {
            HStack {
                if self.contains {
                    Image(systemName: "minus")
                        .foregroundColor(.white)
                    Text("Remove all")
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                    Text("Add all")
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: 200)
        }
        .buttonStyle(self.contains ? .removeButtonStyle : .addButtonStyle)
        .onReceive(self.playlistConstructor.$tracks.debounce(for: .seconds(0.2), scheduler: RunLoop.main), perform: { (tracks: [TrackPace]) in
            self.contains = self.tracks.allSatisfy { (rhs: Track) in
                tracks.contains { (lhs: TrackPace) in
                    lhs == rhs
                }
            }
        })
    }
    
    private func addAllTracks() {
        self.playlistConstructor.addTrack(all: self.tracks)
    }
    
    private func removeAllTracks() {
        self.playlistConstructor.removeTrack(all: self.tracks)
    }
}
