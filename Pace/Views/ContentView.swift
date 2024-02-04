//
//  ContentView.swift
//  Pace
//
//  Created by Brandon Roehl on 1/26/23.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        PlaylistView()
            // Display the welcome view when appropriate.
            .welcomeSheet()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
