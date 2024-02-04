//
//  ProcessingView.swift
//  Pace
//
//  Created by Brandon Roehl on 2/10/23.
//

import SwiftUI

struct ExportView: View {
    @StateObject private var playlistExporter = PlaylistExporter()

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var showingAlert = false

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    ProgressView(value: self.playlistExporter.progress) {
                        Text("\(Int(self.playlistExporter.progress * 100))% progress...")
                    }
                    .progressViewStyle(.linear)
                    Text(self.playlistExporter.currentStep)
                }
                .padding(.all, 30)
//                BannerView(adUnitID: "ca-app-pub-5741801169601651/4094463530")
                BannerAd(adUnitID: "ca-app-pub-5741801169601651/4094463530")
            }
            .navigationTitle("Exporting")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ProgressView()
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel, action: {
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                    }
                    .foregroundColor(.red)
                }
            }
        }
        .interactiveDismissDisabled()
        .navigationBarBackButtonHidden(true)
        .task(savePlaylist)
    }
    
    @Sendable
    private func savePlaylist() async {
        await withTaskGroup(of: Void.self) { taskGroup in
            // Must be higher priority than tasks that fill this
            taskGroup.addTask(priority: .userInitiated) {
                await self.playlistExporter.export()
            }
            taskGroup.addTask {
                try? await Task.sleep(for: .seconds(5))
            }
            await taskGroup.waitForAll()
        }
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct ExportView_Previews: PreviewProvider {
    static var previews: some View {
        ExportView()
    }
}
