//
//  Exporter.swift
//  Pace
//
//  Created by Brandon Roehl on 2/12/23.
//

import Foundation
import Combine
import MusicKit

class PlaylistExporter: ObservableObject {
    
    // This offset is used to when calculating current progress
    // when we are waiting on song data to load
    private static let progressOffset = 0.7
    
    @Published private(set) var progress: Double = 0.0
    private var total: Int = 0
    private var amount: Int = 0
    
    @Published private(set) var currentStep: String = ""
    
    @MainActor
    private func incrementProgress(_ amount: Int = 1) {
        self.amount += amount
        self.progress = min((Double(self.amount) / Double(self.total)) * Self.progressOffset, 1.0)
    }
    
    @MainActor
    private func sendMessage(_ currentStep: String, progress: Double? = nil) {
        self.currentStep = currentStep
        if progress != nil {
            self.progress = progress!
        }
    }
    
    func export() async {
        let constructor = PlaylistConstructor.shared
        let tracks = await constructor.tracks
        self.total = tracks.count
        self.amount = 0
        await self.sendMessage("Loading track tempos...", progress: 0.0)
        
        await withTaskGroup(of: Void.self) { taskGroup in
            for pace in tracks {
                // Must be higher priority than tasks that fill this
                taskGroup.addTask(priority: .userInitiated) {
                    let _ = try? await pace.loadFuture?.value
                    await self.incrementProgress()
                }
            }
            await taskGroup.waitForAll()
        }
        
        await self.sendMessage("Scanning songs for ones that fit...")
        
        let matching = tracks.filter { pace in
                pace.tempo != nil && constructor.tempoRange.contains(pace.tempo!)
            }
            .map(\.track)
        
        await self.sendMessage("Searching for existing playlist...", progress: 0.8)
        
        do {
            var request = MusicLibraryRequest<Playlist>()
            request.filter(matching: \.name, equalTo: constructor.playlistTitle)
            let response = try await request.response()
            
            let description = "Tempo range of \(Int(round(constructor.tempoRange.lowerBound))) to \(Int(round(constructor.tempoRange.upperBound))) bpm"

            
            /// How to edit or create a playlist
            /// https://developer.apple.com/documentation/musickit/musiclibrary/edit(_:name:description:authordisplayname:items:)
            /// https://developer.apple.com/documentation/musickit/musiclibrary/createplaylist(name:description:authordisplayname:items:)
            if let playlist = response.items.first {
                await self.sendMessage("Editing existing playlist...", progress: 0.9)
                try await MusicLibrary.shared.edit(playlist, name: constructor.playlistTitle, description: description, items: matching)
                await self.sendMessage("Updated playlist\"\(constructor.playlistTitle)\"", progress: 1.0)
            } else {
                await self.sendMessage("Creating playlist \"\(constructor.playlistTitle)\"...", progress: 0.9)
                try await MusicLibrary.shared.createPlaylist(name: constructor.playlistTitle, description: description, items: matching)
                await self.sendMessage("Finalizing playlist \"\(constructor.playlistTitle)\"...", progress: 1.0)
            }
        } catch {
            await self.sendMessage("Failed to create playlist, Rolling back...", progress: 1.0)

            print("Failed to save playlist")
        }
    }
}
