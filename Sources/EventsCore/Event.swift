//
//  Event.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//

import Foundation

/// Protocol that all events must conform to
public protocol Event: Sendable {
    /// The name of the event, used for routing
    static var name: String { get }
    
    /// The payload type of the event
    associatedtype Payload: Codable & Sendable = Self
}

/// Default implementation for Event name
public extension Event {
    static var name: String {
        String(describing: Self.self)
    }
}
