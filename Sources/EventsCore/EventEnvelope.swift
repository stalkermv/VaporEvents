//
//  EventEnvelope.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//
import Foundation

/// An envelope that wraps an event with metadata
public struct EventEnvelope<E: Event>: Codable, Sendable {
    /// The event
    public let payload: E.Payload
    
    /// The metadata
    public let metadata: EventMetadata
    
    /// Create a new event envelope
    public init(payload: E.Payload, metadata: EventMetadata = EventMetadata()) {
        self.payload = payload
        self.metadata = metadata
    }
}
