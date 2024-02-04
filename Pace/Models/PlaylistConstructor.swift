/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A data model object that holds recently played songs.
*/

import Combine
import MusicKit
import Foundation

/// A data model object that fetches the user's recently played music items.
/// This object also offers a convenient way to observe recently played music items.
class PlaylistConstructor: ObservableObject {
    // MARK: - Properties
    
    static let shared = PlaylistConstructor()
    
    /// A collection of recently played items.
    @MainActor @Published var tracks: [TrackPace] = []
    
    @Published var playlistTitle: String = ""
    @Published var tempo: Int = 120
    @Published var fit: Int = 25
    
    @Published private(set) var tempoRange: ClosedRange<Double> = 0...200
    @Published private(set) var totalCount: Int = 0
    @Published private(set) var matchingCount: Int = 0

    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.$tempo.combineLatest(self.$fit)
            .map { tempo, fit in
                let fitPercent = (Double(fit) / 100)
                let lowEnd = Double(tempo) * (1.0 - fitPercent)
                let highEnd = Double(tempo) * (1.0 + fitPercent)
                return lowEnd...highEnd
            }
            .assign(to: \.tempoRange, on: self)
            .store(in: &self.cancellables)
        self.$tracks
            .map(\.count)
            .assign(to: \.totalCount, on: self)
            .store(in: &self.cancellables)
        self.$tracks.combineLatest(self.$tempoRange)
            .debounce(for: .seconds(0.2), scheduler: RunLoop.main)
            .map { tracks, tempoRange in
                tracks.map(\.tempo).filter { tempo in
                    tempo != nil && tempoRange.contains(tempo!)
                }
                .count
            }
            .assign(to: \.matchingCount, on: self)
            .store(in: &self.cancellables)
    }
    
    @MainActor private func contains(_ rhs: Track) -> Bool {
        return self.tracks.contains { lhs in
            lhs == rhs
        }
    }

    @MainActor
    func addTrack(_ item: Track) {
        // This will need to fill BPM data on the fly
        if !self.contains(item) {
            self.tracks.append(TrackPace(item))
        }
    }
    
    func addTrack(all items: MusicItemCollection<Track>) {
        // This is not calling add track cause these will need to fill BPM data on the fly
        Task.detached(priority: .background) { [self] in
            for item in items {
                await self.addTrack(item)
            }
        }
    }

    @MainActor
    func removeTrack(_ item: Track) {
        if let index = self.tracks.firstIndex(where: { lhs in
            lhs == item
        }) {
            self.tracks.remove(at: index)
        }
    }
    
    func removeTrack(all items: MusicItemCollection<Track>) {
        Task.detached(priority: .background) { [self] in
            for item in items {
                await removeTrack(item)
            }
        }
    }
}
