//
//  EventBus.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//

import Foundation
import NIOCore
import Vapor

/// Protocol that all event bus implementations must conform to
public protocol EventBus: Sendable {
    /// Publish an event to the event bus
    func publish<E: Event>(_ event: E, encoder: JSONEncoder, payload: E.Payload) async throws
    
    /// Subscribe to events of a specific type
    func subscribe<E: Event>(
        _ type: E.Type,
        decoder: JSONDecoder,
        handler: @escaping @Sendable (E.Payload) async throws -> Void
    ) async throws
    
    /// Unsubscribe from events of a specific type
    func unsubscribe<E: Event>(_ type: E.Type) async throws
    
    /// Shutdown the event bus
    func shutdown() async throws
}

public extension EventBus {
    func publish<E: Event>(_ event: E, encoder: JSONEncoder) async throws where E.Payload == E, E: Codable {
        try await self.publish(event, encoder: encoder, payload: event)
    }
}

public extension EventBus {
    func subscribe<H: EventHandler>(_ handler: H.Type, application: Application) async throws {
        try await subscribe(H.E.self, decoder: application.events.configuration.decoder) { payload in
            let context = H.Context(
                payload: payload,
                application: application
            )
            try await H.handle(context: context)
        }
    }
}
