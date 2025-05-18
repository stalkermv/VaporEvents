//
//  EventsNATSDriver.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 06.05.2025.
//

import Foundation
import NIOCore
import Logging
import EventsCore
import Vapor
import Nats

/// A NATS implementation of EventBus
public actor EventsNATSDriver {
    /// The logger
    private let logger: Logger
    
    /// The NATS client
    private let nats: NatsClient
    
    /// The configuration
    private let configuration: EventsNATSConfiguration
    
    /// The subscriptions
    private var subscriptions: [String: NatsSubscription] = [:]
    
    /// Connection state
    private var isConnected: Bool {
        nats.connectedUrl != nil
    }
    
    /// Create a new NATS event bus
    public init(
        configuration: EventsNATSConfiguration,
        logger: Logger = Logger(label: "events.nats")
    ) {
        self.logger = logger
        self.configuration = configuration
        
        // Configure NATS client options
        var options = NatsClientOptions()
            .url(configuration.url)
        
        // Apply authentication if provided
        if let credentials = configuration.credentials {
            switch credentials {
            case .userPass(let username, let password):
                options = options.usernameAndPassword(username, password)
            case .jwt(let jwt, let nkey):
                options = options.nkey(nkey)
            case .token(let token):
                options = options.token(token)
            }
        }
        
        // Apply TLS configuration if provided
        if let tlsConfig = configuration.tlsConfiguration {
            options = options.requireTls()
        }
        
        // Build the client
        self.nats = options.build()
        
        Task {
            await registerEventHandlers()
        }
    }
    
    /// Connect to the NATS server
    public func connect() async throws {
        if !isConnected {
            try await self.nats.connect()
        }
    }
    
    /// Ensure connection is established before performing operations
    private func ensureConnected() async throws {
        if !isConnected {
            try await connect()
        }
    }
    
    private func registerEventHandlers() {
        // Set up event handlers
        self.nats.on(.connected) { [weak self] _ in
            self?.logger.info("Connected to NATS server")
        }
        
        self.nats.on(.disconnected) { [weak self] _ in
            self?.logger.warning("Disconnected from NATS server")
        }
        
        self.nats.on(.error) { [weak self] event in
            if case let .error(error) = event {
                self?.logger.error("NATS error: \(error)")
            }
        }
    }
}

extension EventsNATSDriver: EventBus {
    
    /// Publish an event
    public func publish<E: Event>(_ event: E) async throws {
        try await ensureConnected()
        
        // Transform the event name
        let transformedName = configuration.eventNameTransformer.transform(E.name)
        logger.debug("Publishing event: \(E.name) as \(transformedName)")
        
        // Encode the event
        let data = try JSONEncoder().encode(event)
        
        // Create headers if needed
        var headers = NatsHeaderMap()
        headers.append(try NatsHeaderName("event-type"), NatsHeaderValue(E.name))
        
        // Publish to NATS with transformed name
        try await nats.publish(data, subject: transformedName, headers: headers)
    }
    
    /// Subscribe to events
    public func subscribe<E: Event>(
        _ type: E.Type,
        handler: @escaping @Sendable (E) async throws -> Void
    ) async throws {
        try await ensureConnected()
        
        // Transform the event name
        let transformedName = configuration.eventNameTransformer.transform(E.name)
        logger.debug("Subscribing to event: \(E.name) as \(transformedName)")
        
        guard subscriptions[transformedName] == nil else {
            return
        }
        
        // Create subscription if it doesn't exist
        let subscription = try await nats.subscribe(subject: transformedName)
        
        // Start processing messages
        Task {
            for try await message in subscription {
                do {
                    guard let payload = message.payload else {
                        logger.warning("Received message without payload for \(transformedName)")
                        continue
                    }
                    
                    // Decode the event
                    let event = try JSONDecoder().decode(E.self, from: payload)
                    
                    // Call the handler
                    try await handler(event)
                } catch {
                    logger.error("Error processing message for \(transformedName): \(error)")
                }
            }
        }
        
        // Store the subscription
        subscriptions[transformedName] = subscription
    }
    
    /// Unsubscribe from events
    public func unsubscribe<E: Event>(_ type: E.Type) async throws {
        // Transform the event name
        let transformedName = configuration.eventNameTransformer.transform(E.name)
        logger.debug("Unsubscribing from event: \(E.name) as \(transformedName)")
        
        // Get the subscription
        if let subscription = subscriptions[transformedName] {
            // Unsubscribe
            try await subscription.unsubscribe()
            
            // Remove from subscriptions
            subscriptions.removeValue(forKey: transformedName)
        }
    }
    
    /// Shutdown the event bus
    public func shutdown() async throws {
        logger.debug("Shutting down NATS event bus")
        
        // Unsubscribe from all subscriptions
        for (_, subscription) in subscriptions {
            try? await subscription.unsubscribe()
        }
        
        // Clear subscriptions
        subscriptions.removeAll()
        
        // Disconnect from NATS
        if isConnected {
            try await nats.close()
        }
    }
}

extension NatsSubscription: @unchecked @retroactive Sendable { }
extension NatsMessage: @unchecked @retroactive Sendable { }
extension NatsClient: @unchecked @retroactive Sendable { }
