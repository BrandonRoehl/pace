//
//  PaceCell.swift
//  Pace
//
//  Created by Brandon Roehl on 2/11/23.
//

import MusicKit
import SwiftUI

/// A view that displays information about a music item.
struct PaceCell: View {
    
    // MARK: - Properties
    @StateObject private var playlistConstructor = PlaylistConstructor.shared

    @StateObject var pace: TrackPace
    
    // MARK: - Constants
    public static let rowHeight = artworkSize + 24
    
    private static let artworkSize = 60.0
    private static let artworkCornerRadius = 6.0
    private static let subtitleVerticalOffset = 0.0
    
    private static let gaugeGradient = Gradient(colors: [.blue, .green, .yellow, .orange, .red])
    private static let gaugeRange = 60.0...180.0

    
    // MARK: - View
    
    var body: some View {
        HStack {
            if let itemArtwork = self.pace.track.artwork {
                imageContainer(for: itemArtwork)
                    .frame(width: Self.artworkSize, height: Self.artworkSize)
            }
            VStack(alignment: .leading) {
                Text(self.pace.track.title)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                if let subtitle = pace.track.artistName, !subtitle.isEmpty {
                    Text(subtitle)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                        .padding(.top, (-2.0 + Self.subtitleVerticalOffset))
                }
            }.padding(.leading, 12)
            Spacer()
            let gaugeValue = min(max(self.pace.tempo ?? 0, Self.gaugeRange.lowerBound), Self.gaugeRange.upperBound)
            Gauge(value: gaugeValue, in: Self.gaugeRange) {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            } currentValueLabel: {
                if self.pace.loading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.primary)
                } else if let bpm = self.pace.tempo {
                    Text("\(Int(round(bpm)))")
                        .foregroundColor(colorForBPM(gaugeValue))
                } else {
                    Text("?")
                        .foregroundColor(Self.gaugeGradient.stops.first?.color ?? .primary)
                }
            } minimumValueLabel: {
                Text("\(Int(Self.gaugeRange.lowerBound))")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Self.gaugeGradient.stops.first?.color ?? .primary)
            } maximumValueLabel: {
                Text("\(Int(Self.gaugeRange.upperBound))")
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(Self.gaugeGradient.stops.last?.color ?? .primary)
            }
            .tint(Self.gaugeGradient)
            .gaugeStyle(.accessoryCircular)
            .frame(width: Self.artworkSize, height: Self.artworkSize)
        }
        .frame(height: Self.rowHeight)
        .opacity(self.pace.loading || self.playlistConstructor.tempoRange.contains(self.pace.tempo ?? 0) ? 1.0 : 0.25)
    }
    
    private func colorForBPM(_ bpm: Double) -> Color {
        let stops = Self.gaugeGradient.stops
        let index = Int(round(
            ((bpm-Self.gaugeRange.lowerBound)/(Self.gaugeRange.upperBound-Self.gaugeRange.lowerBound)) * Double(stops.count - 1)
        ))
        return stops[index].color
    }
    
    private func imageContainer(for artwork: Artwork) -> some View {
        VStack(alignment: .center) {
            ArtworkImage(artwork, width: Self.artworkSize, height: Self.artworkSize)
                .cornerRadius(Self.artworkCornerRadius)
        }
    }
}


//struct PaceCell_Previews: PreviewProvider {
//    static var previews: some View {
//        PaceCell(pace: TrackPace(Song))
//    }
//}
