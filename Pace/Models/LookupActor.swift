//
//  LookupActro.swift
//  Pace
//
//  Created by Brandon Roehl on 2/13/23.
//

import Foundation
import Combine

struct LookupItem: Decodable, Encodable, Equatable {
    // Smart quotes are fucking dumb remove unicode charecters that Spotify doesn't use
    private static var hashChars = /[^\x00-\x7F]|["'&]/
    
    var tempo: Double?
    
    var isrc: String?
    var artist: String
    var album: String?
    var title: String
    
    var description: String {
        if let isrc = isrc {
            return isrc
        }
        return title
    }
    
//    static func < (lhs: LookupItem, rhs: LookupItem) -> Bool {
//        if lhs.artist == rhs.artist {
//            if lhs.album == rhs.album {
//                if lhs.title == lhs.title {
//                    if lhs.isrc == nil {
//                        return false
//                    } else if rhs.isrc == nil {
//                        return true
//                    }
//                    return lhs.isrc! < rhs.isrc!
//                }
//                return lhs.title < lhs.title
//            } else if lhs.album == nil {
//                return false
//            }
//            return lhs.album! < rhs.album!
//        }
//        return lhs.artist < rhs.artist
//    }
    
    static func == (lhs: LookupItem, rhs: LookupItem) -> Bool {
        if lhs.isrc == rhs.isrc {
            return true
        }
        for (l, r) in [(lhs.artist, rhs.artist), (lhs.album, rhs.album), (lhs.title, rhs.title)] {
            if l?.replacing(Self.hashChars, with: "") != r?.replacing(Self.hashChars, with: "") {
                return false
            }
        }
        return true
    }
}

actor LookupActor {
    private init () {}
    static let shared = LookupActor()
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lookupURL = URL(string: "https://bpm.aws.roehl.rocks/v1/lookup")!
    private let session = {
        var config = URLSession.shared.configuration
        config.timeoutIntervalForRequest = 60 * 2
        return URLSession(configuration: config)
    }()
    
    func runLookup(_ items: [LookupItem]) async throws -> [LookupItem] {
        /// Build the request
        var request = URLRequest(url: self.lookupURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try self.encoder.encode(items)
#if DEBUG
        print(String(decoding: request.httpBody!, as: UTF8.self))
#endif
        
        let (out, response) = try await self.session.data(for: request)
#if DEBUG
        print(String(decoding: out, as: UTF8.self))
#endif
        if let httpResponse = response as? HTTPURLResponse {
            switch (httpResponse.statusCode / 100){
            case 3:
                /// Continue around and do this again
                throw URLError.init(URLError.timedOut)
            case 4, 5:
                throw URLError(URLError.Code(rawValue: httpResponse.statusCode))
            default:
                break
            }
        } else {
            throw URLError(URLError.Code.badURL)
        }
        
        return try self.decoder.decode([LookupItem].self, from: out)
    }
}
