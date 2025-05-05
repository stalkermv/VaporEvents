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
    public let event: E
    
    /// The metadata
    public let metadata: EventMetadata
    
    /// Create a new event envelope
    public init(event: E, metadata: EventMetadata = EventMetadata()) {
        self.event = event
        self.metadata = metadata
    }
}