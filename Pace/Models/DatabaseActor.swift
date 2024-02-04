//
//  DatabaseActor.swift
//  Pace
//
//  Created by Brandon Roehl on 2/13/23.
//

import Combine
import CoreData
import MusicKit

actor DatabaseActor {
    private init () {}
    static let shared = DatabaseActor()
    
    @MainActor private let moc = PersistenceController.shared.container.viewContext
    
    func lookupTempo(id: MusicItemID) throws -> Double? {
        let request = TempoCache.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id.rawValue)
        let result: TempoCache? = try self.moc.fetch(request).first
        return result?.tempo?.doubleValue
    }
    
    func insert(id: MusicItemID, tempo: Double) throws {
        let newItem = TempoCache(context: self.moc)
        newItem.tempo = NSDecimalNumber(floatLiteral: tempo)
        newItem.id = id.rawValue
    }
    
    func save() throws {
        if moc.hasChanges {
            try moc.save()
        }
    }
}
