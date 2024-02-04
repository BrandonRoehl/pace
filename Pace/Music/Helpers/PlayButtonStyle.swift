/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A button style the play button uses.
*/

import SwiftUI

// MARK: - Play button style

/// A custom button style that encapsulates all the common modifiers for prominent buttons in the user interface.
struct PlayButtonStyle: ButtonStyle {
    
    private let color: Color
    
    init(_ color: Color) {
        self.color = color
    }
    
    /// Applies relevant modifiers for this button style.
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.title3.bold())
            .foregroundColor(.accentColor)
            .padding(Self.paddingEdges, Self.paddingLength)
            .background(self.color.cornerRadius(Self.backgroundCornerRadius))
    }
    
    // MARK: - Constants
    
    private static let backgroundCornerRadius: CGFloat = 8
    private static let paddingEdges: Edge.Set = .all
    private static let paddingLength: CGFloat? = nil
    
}

// MARK: - Button style extension

/// An extension that provides a convenience method to apply the prominent button style using idiomatic syntax.
extension ButtonStyle where Self == PlayButtonStyle {
    
    /// A button style that encapsulates all the common modifiers
    /// for prominent buttons shown in the user interface.
    static var addButtonStyle: PlayButtonStyle {
        PlayButtonStyle(.accentColor)
    }
    
    /// A button style that encapsulates all the common modifiers
    /// for prominent buttons shown in the user interface.
    static var removeButtonStyle: PlayButtonStyle {
        PlayButtonStyle(.red)
    }
}
