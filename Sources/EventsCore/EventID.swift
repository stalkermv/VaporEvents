//
//  EventID.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//

import Foundation

/// A unique identifier for an event
public struct EventID: Codable, Hashable, Sendable, CustomStringConvertible {
    /// The underlying UUID
    public let id: UUID
    
    /// Create a new event ID
    public init() {
        self.id = UUID()
    }
    
    /// Create an event ID from a UUID
    public init(_ id: UUID) {
        self.id = id
    }
    
    /// Create an event ID from a string
    public init?(_ string: String) {
        guard let uuid = UUID(uuidString: string) else {
            return nil
        }
        self.id = uuid
    }
    
    public var description: String {
        id.uuidString
    }
}

/// Metadata for an event
public struct EventMetadata: Codable, Sendable {
    /// The ID of the event
    public let id: EventID
    
    /// The timestamp when the event was created
    public let timestamp: Date
    
    /// Additional headers
    public var headers: [String: String]
    
    /// Create new event metadata
    public init(id: EventID = EventID(), timestamp: Date = Date(), headers: [String: String] = [:]) {
        self.id = id
        self.timestamp = timestamp
        self.headers = headers
    }
}