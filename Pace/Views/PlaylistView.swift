//
//  HomeView.swift
//  Pace
//
//  Created by Brandon Roehl on 2/3/23.
//

import SwiftUI
import MusicKit

struct PlaylistView: View {
    @StateObject private var playlistConstructor = PlaylistConstructor.shared
    
    @FocusState private var editingBpm: Bool
    
    @State private var presentClear = false
    @State private var isConfirming: Bool = false
    @State private var playlistNames: [String]? = nil
    
    enum SheetMode: Identifiable {
        var id: Self {
            return self
        }
        
        case export
        case add
    }
    
    @State private var sheetMode: SheetMode? = nil
    
    var body: some View {
        NavigationStack {
            List {
                settingsSection
                saveButton
                Section(header: Text("Advertisement")) {
                    NativeContentView(adUnitID: "ca-app-pub-5741801169601651/4562233368")
                        .listRowInsets(EdgeInsets())
                }
                playlistSection
            }
            .listStyle(.insetGrouped)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { self.sheetMode = .add }) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .destructive, action: {
                        if self.playlistConstructor.totalCount > 0 {
                            self.presentClear = true
                        }
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                }
            }
            .task(self.loadPlaylistNames)
            .sheet(item: self.$sheetMode) { mode in
                switch mode {
                case .export:
                    ExportView()
                case .add:
                    MusicView()
                }
            }
            .confirmationDialog(
                "A playlist with this name already exists",
                isPresented: self.$isConfirming,
                titleVisibility: .visible
            ) {
                Button("Overwrite", role: .destructive, action: {
                    self.sheetMode = .export
                })
            }
            .confirmationDialog("Are you sure?", isPresented: $presentClear) {
                Button("Clear all items", role: .destructive, action: self.clearItems)
            }
            .navigationTitle("Pace")
        }
    }
    
    var settingsSection: some View {
        Section(header: Text("Playlist Settings")) {
            HStack {
                Text("Title")
                Spacer()
                TextField("Playlist Title", text: self.$playlistConstructor.playlistTitle)
                    .submitLabel(.done)
                // .textFieldStyle(.roundedBorder)
            }
            HStack {
                Text("Tempo")
                Spacer()
                TextField("bpm", value: self.$playlistConstructor.tempo, format: .number)
                    .keyboardType(.numberPad)
                    .focused(self.$editingBpm)
                
                Stepper(value: self.$playlistConstructor.tempo, onEditingChanged: { _ in
                    if self.editingBpm {
                        self.editingBpm = false
                    }
                }) {}
            }
            Stepper("Fit tolerance \(self.playlistConstructor.fit)%", value: self.$playlistConstructor.fit, in: 1...100)
        }
    }
    
    var saveButton: some View {
        let disabled = (
            self.playlistConstructor.playlistTitle.isEmpty ||
            self.playlistConstructor.totalCount == 0 ||
            self.playlistNames == nil
        )
        return Section(footer: footerBuilder) {
            Button(action: self.confirmExport) {
                Label("Begin Playlist Creation", systemImage: "square.and.arrow.down")
                    .foregroundColor(.white)
            }
            .tint(.accentColor)
            .disabled(disabled)
        }
        .listRowBackground(disabled ? Color.gray : Color.accentColor)
    }
    
    private var footerBuilder: some View {
        let hasTitle = !self.playlistConstructor.playlistTitle.isEmpty
        let hasTracks = self.playlistConstructor.totalCount > 0
        
        return VStack(alignment: .leading){
            if hasTracks && hasTitle {
                let totalCount = self.playlistConstructor.totalCount
                let tempoRange = self.playlistConstructor.tempoRange
                let matchingCount = self.playlistConstructor.matchingCount
                Text("Tempo range of \(Int(round(tempoRange.lowerBound))) to \(Int(round(tempoRange.upperBound))) bpm")
                Text("Of \(totalCount) songs \(matchingCount) songs fit")
            }
            if !hasTitle {
                Text("A title is required for your playlist").foregroundColor(.red)
            }
            if !hasTracks {
                Text("Cannot build a playlist without songs").foregroundColor(.red)

            }
        }
    }
    
    var playlistSection: some View {
        Section {
            ForEach(playlistConstructor.tracks) { pace in
                PaceCell(pace: pace)
            }
            .onDelete { offsets in
                withAnimation {
                    self.playlistConstructor.tracks.remove(atOffsets: offsets)
                }
            }
            .onMove { fromOffsets, toOffset in
                withAnimation {
                    self.playlistConstructor.tracks.move(fromOffsets: fromOffsets, toOffset: toOffset)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12))
        }
    }
    
    private func clearItems() {
        withAnimation {
            self.playlistConstructor.tracks = []
        }
    }
    
    private func confirmExport() {
        if self.playlistNames!.contains(
            self.playlistConstructor.playlistTitle
        ) {
            self.isConfirming = true
        } else {
            self.sheetMode = .export
        }
    }
    
    @Sendable
    private func loadPlaylistNames() async {
        let request = MusicLibraryRequest<Playlist>()
        let response = try? await request.response()
        self.setPlaylistNames(response?.items.map(\.name) ?? [])
    }
    
    @MainActor
    private func setPlaylistNames(_ items: [String]) {
        self.playlistNames = items
    }
}


struct PlaylistView_Previews: PreviewProvider {
    static var previews: some View {
        PlaylistView()
    }
}
