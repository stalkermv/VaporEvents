//
//  EventBus.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//

import Foundation
import NIOCore

/// Protocol that all event bus implementations must conform to
public protocol EventBus: Sendable {
    /// Publish an event to the event bus
    func publish<E: Event>(_ event: E) async throws
    
    /// Subscribe to events of a specific type
    func subscribe<E: Event>(
        _ type: E.Type,
        handler: @escaping @Sendable (E) async throws -> Void
    ) async throws
    
    /// Unsubscribe from events of a specific type
    func unsubscribe<E: Event>(_ type: E.Type) async throws
    
    /// Shutdown the event bus
    func shutdown() async throws
}