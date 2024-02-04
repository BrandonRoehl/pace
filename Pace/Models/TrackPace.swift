//
//  TrackPace.swift
//  Pace
//
//  Created by Brandon Roehl on 2/11/23.
//

import Combine
import MusicKit
import SwiftUI

class TrackPace: ObservableObject, Equatable, Identifiable {
    private struct LookupError: Error {
        private let message: String
        public var localizedDescription: String { self.message }
        
        init(_ message: String) {
            self.message = message
        }
    }
    
    // MARK: - Static Properties
    
    private typealias Promise = (Result<Double, Error>) -> Void
    
    private static let database = DatabaseActor.shared
    private static let lookupActor = LookupActor.shared
    
    private static func scheduleLoad(pace: TrackPace, promise: @escaping Promise) {
        Self.scheduler.schedule((pace, promise))
    }
    
    private static let scheduler: BatchScheduler<(TrackPace, Promise)> = BatchScheduler(
        batchSize: 15,
        maxDelay: .seconds(1)
    ) { batch in
        var deepLookup = [(item: LookupItem, pace: TrackPace, promise: Promise)]()
        
        /// Lookup as many as we can that are in core data
        for (pace, promise) in batch {
            do {
                if let tempo = try await database.lookupTempo(id: pace.track.id) {
                    /// There is data in the cache
                    print("Found '\(pace.track.id)' in the cache")
                    promise(.success(tempo))
                } else {
                    /// Mark this song for lookup
                    deepLookup.append(
                        (
                            item: LookupItem(
                                isrc: try await pace.lookupISRC(),
                                artist: pace.track.artistName,
                                album: pace.track.albumTitle,
                                title: pace.track.title
                            ),
                            pace: pace,
                            promise: promise
                        )
                    )
                }
            } catch let err {
                promise(.failure(err))
            }
        }

        if deepLookup.isEmpty {
            return
        }

        /// Lookup in a batch and save them
        do {
            var result = try await lookupBPM(items: deepLookup.map(\.item))
            
            /// Save the results first
            // Walk left right and save the ones that do not exist
        lookupLoop:
            for (i, (l, pace, promise)) in deepLookup.enumerated() {
                for j in 0..<result.count {
                    let r = result[j]
                    if let tempo = r.tempo, r == l {
                        // we found the song
                        result.remove(at: j)
                        /// Create the new item
                        try await database.insert(id: pace.track.id, tempo: tempo)
                        /// Send success we will save these later
                        promise(.success(tempo))
                        continue lookupLoop
                    }
                }
                // we did not find the song
                promise(.failure(LookupError("Item \(l) not found in our database")))
            }
        } catch let err {
            for (_, _, promise) in deepLookup {
                promise(.failure(err))
            }
        }

        try? await database.save()
    }
    
    // MARK: - Instance Methods
    private static func lookupBPM(items: [LookupItem]) async throws -> [LookupItem] {
        print("Looking up '\(items)'")
        /// Let this loop around on timeouts and other errors that arn't our fault and try again a few times
        for i in 1...10 {
            do {
                return try await Self.lookupActor.runLookup(items)
            } catch URLError.timedOut {
                
            } catch let error {
                let error = error as NSError
                print(error)
                guard error.domain == NSURLErrorDomain, error.code == NSURLErrorTimedOut else {
                    throw error
                }
            }
            let r = min(i, 6)
            try await Task.sleep(for: .seconds(r*r))
        }
        throw LookupError("Ran out of retry attempts for looking up \(items)")
    }
    
    private func lookupISRC() async throws -> String? {
        var isrc = self.track.isrc
        
        /// We got lucky just return it
        if isrc != nil {
            return isrc!
        }
        
        /// Try a base extra info lookup and see if we can find it
        switch self.track {
        case .song(let song):
            isrc = try await song.with([.artistURL], preferredSource: .catalog).isrc
        case .musicVideo(let video):
            isrc = try await video.with([.artistURL], preferredSource: .catalog).isrc
        @unknown default:
            break
        }
        if isrc != nil {
            return isrc!
        }
        
        /// Do a long lookup of "Title by Artist" to see if you can find one
        let response = try await MusicCatalogSearchSuggestionsRequest(
            term: "\(self.track.title) by \(self.track.artistName)",
            includingTopResultsOfTypes: [
                Song.self,
                Album.self
            ]
        ).response()
    resultLoop:
        for topResult in response.topResults {
            switch topResult {
            case .song(let song):
                if song.title == self.track.title && song.artistName == self.track.artistName {
                    isrc = song.isrc
                    break resultLoop
                }
            default:
                continue resultLoop
            }
        }
        
        /// This song is getting skipped cause all three ways to lookup this information failed
        return isrc
    }
    
    // MARK: - Properties
    
    let track: Track
    
    @Published public private(set) var tempo: Double?
    @Published public private(set) var loading: Bool
    
    public private(set) var loadFuture: Future<Double, Error>?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(_ track: Track) {
        self.track = track
        self.tempo = nil
        self.loading = true
        let future = Future { [self] promise in
            Self.scheduleLoad(pace: self, promise: promise)
        }
        future.receive(on: RunLoop.main)
            .sink(receiveCompletion: { state in
                defer {
                    self.loading = false
                }
                switch state {
                case .failure(let err):
                    print("ERROR: Unresolved song '\(self.track.id)':'\(self.track.title)' \(err), \(err.localizedDescription)")
                case .finished:
                    break
                }
            }, receiveValue: { tempo in
                self.tempo = tempo
            })
            .store(in: &self.cancellables)
        self.loadFuture = future
    }
    
    // MARK: - Equatable
    
    static func == (lhs: TrackPace, rhs: TrackPace) -> Bool {
        return Self.trackEq(lhs.track, rhs.track)
    }
    
    static func == (lhs: TrackPace, rhs: Track) -> Bool {
        return Self.trackEq(lhs.track, rhs)
    }
    
    private static func trackEq(_ lhs: Track, _ rhs: Track) -> Bool {
        return lhs.id == rhs.id ||
        (
            lhs.title == rhs.title &&
            lhs.albumTitle == rhs.albumTitle &&
            lhs.artistName == rhs.artistName &&
            lhs.duration == rhs.duration
        )
    }
}
