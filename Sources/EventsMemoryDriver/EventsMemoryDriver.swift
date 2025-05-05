import Foundation
import NIOCore
import Logging
import EventsCore
import Vapor

/// An in-memory implementation of EventBus for testing
public actor EventsMemoryDriver: EventBus {
    /// The logger
    private let logger: Logger
    
    /// The handlers for each event type
    private var handlers: [String: [(Any) async throws -> Void]] = [:]
    
    /// Create a new in-memory event bus
    public init(logger: Logger = Logger(label: "events.inmemory")) {
        self.logger = logger
    }
    
    /// Publish an event
    public func publish<E: Event>(_ event: E) async throws {
        logger.debug("Publishing event: \(E.name)")
        
        guard let handlers = handlers[E.name] else {
            logger.debug("No handlers for event: \(E.name)")
            return
        }
        
        for handler in handlers {
            try await handler(event)
        }
    }
    
    /// Subscribe to events
    public func subscribe<E: Event>(
        _ type: E.Type,
        handler: @escaping @Sendable (E) async throws -> Void
    ) async throws {
        logger.debug("Subscribing to event: \(E.name)")
        
        if handlers[E.name] == nil {
            handlers[E.name] = []
        }
        
        handlers[E.name]?.append { (event: Any) async throws in
            guard let typedEvent = event as? E else { return }
            try await handler(typedEvent)
        }
    }
    
    /// Unsubscribe from events
    public func unsubscribe<E: Event>(_ type: E.Type) async throws {
        logger.debug("Unsubscribing from event: \(E.name)")
        handlers[E.name] = nil
    }
    
    /// Shutdown the event bus
    public func shutdown() async throws {
        logger.debug("Shutting down in-memory event bus")
        handlers.removeAll()
    }
}

extension Application.Events.Provider {
    public static var inMemory: Self {
        .init { app in
            app.events.use(custom: EventsMemoryDriver())
        }
    }
}
