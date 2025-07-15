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
import NATS

/// A NATS implementation of EventBus using SwiftNATSClient
public actor EventsNATSDriver {
    /// The logger
    private let logger: Logger
    
    /// The NATS client
    private let natsClient: NATSClient
    
    /// The configuration
    private let configuration: EventsNATSConfiguration
    
    /// Active subscriptions
    private var subscriptions: [String: Task<Void, Error>] = [:]
    
    /// Task group for managing NATS client lifecycle and operations
    private var mainTask: Task<Void, Error>?
    
    /// Whether the driver has been started
    private var isStarted: Bool = false
    
    /// Create a new NATS event bus
    public init(
        configuration: EventsNATSConfiguration,
        logger: Logger = Logger(label: "events.nats")
    ) {
        self.logger = logger
        self.configuration = configuration
        self.natsClient = NATSClient(
            configuration: configuration.natsConfiguration,
            logger: logger
        )
    }
    
    /// Start the NATS client once using task group pattern
    private func startClientIfNeeded() async throws {
        guard !isStarted else { return }
        
        logger.debug("Starting NATS client with task group")
        
        // Start the main task that manages NATS client lifecycle
        mainTask = Task { [self] in
            try await withThrowingTaskGroup(of: Void.self) { group in
                // Run NATS client
                group.addTask {
                    try await self.natsClient.run()
                }
                
                // Keep the group alive until cancelled
                for try await _ in group {
                    // This will run until the group is cancelled
                }
            }
        }
        
        isStarted = true
        logger.info("NATS client started successfully")
    }
    
    /// Wait for the client to be ready
    private func waitForConnection() async throws {
        // Give the client a moment to establish connection if just started
        if isStarted {
            try await Task.sleep(for: .milliseconds(1000))
        }
    }
    
    /// Perform an operation with retry logic
    private func withRetry<T: Sendable>(
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...configuration.maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                logger.warning("Operation failed (attempt \(attempt)/\(configuration.maxRetries)): \(error)")
                
                if attempt < configuration.maxRetries {
                    try await Task.sleep(for: .seconds(configuration.retryDelay))
                }
            }
        }
        
        throw lastError ?? EventError.operationFailed("All retry attempts exhausted")
    }
}

extension EventsNATSDriver: EventBus {
    
    /// Publish an event
    public func publish<E: Event>(_ event: E, encoder: JSONEncoder, payload: E.Payload) async throws {
        try await startClientIfNeeded()
        try await waitForConnection()
        
        try await withRetry { [self] in
            // Transform the event name
            let transformedName = self.configuration.eventNameTransformer.transform(E.name)
            self.logger.debug("Publishing event: \(E.name) as \(transformedName)")
            
            // Encode the event payload
            let data = try encoder.encode(payload)
            
            // Publish to NATS
            try await self.natsClient.publish(subject: transformedName, data: data)
            
            self.logger.debug("Successfully published event: \(transformedName)")
        }
    }
    
    /// Subscribe to events
    public func subscribe<E: Event>(
        _ type: E.Type,
        decoder: JSONDecoder,
        handler: @escaping @Sendable (E.Payload) async throws -> Void
    ) async throws {
        try await startClientIfNeeded()
        try await waitForConnection()
        
        // Transform the event name
        let transformedName = configuration.eventNameTransformer.transform(E.name)
        logger.debug("Subscribing to event: \(E.name) as \(transformedName)")
        
        // Check if already subscribed
        guard subscriptions[transformedName] == nil else {
            logger.debug("Already subscribed to: \(transformedName)")
            return
        }
        
        // Create subscription
        let subscription = natsClient.subscribe(subject: transformedName)
        
        // Start processing messages
        let subscriptionTask = Task { [weak self] in
            for try await message in subscription {
                do {
                    self?.logger.debug("Received message on subject: \(message.subject)")
                    
                    // Decode the event payload
                    let eventPayload = try decoder.decode(E.Payload.self, from: message.data)
                    
                    // Call the handler
                    try await handler(eventPayload)
                    
                    self?.logger.debug("Successfully processed message for: \(transformedName)")
                } catch {
                    self?.logger.error("Error processing message for \(transformedName): \(error)")
                    // Continue processing other messages
                }
            }
        }
        
        // Store the subscription task
        subscriptions[transformedName] = subscriptionTask
        
        logger.info("Successfully subscribed to: \(transformedName)")
    }
    
    /// Unsubscribe from events
    public func unsubscribe<E: Event>(_ type: E.Type) async throws {
        // Transform the event name
        let transformedName = configuration.eventNameTransformer.transform(E.name)
        logger.debug("Unsubscribing from event: \(E.name) as \(transformedName)")
        
        // Cancel the subscription task if it exists
        if let subscriptionTask = subscriptions[transformedName] {
            subscriptionTask.cancel()
            subscriptions.removeValue(forKey: transformedName)
            logger.info("Successfully unsubscribed from: \(transformedName)")
        } else {
            logger.debug("No active subscription found for: \(transformedName)")
        }
    }
    
    /// Shutdown the event bus
    public func shutdown() async throws {
        logger.debug("Shutting down NATS event bus")
        
        // Cancel all subscription tasks
        for (subject, task) in subscriptions {
            logger.debug("Cancelling subscription for: \(subject)")
            task.cancel()
        }
        subscriptions.removeAll()
        
        // Shutdown the NATS client
        if let mainTask = mainTask {
            logger.debug("Shutting down NATS client")
            mainTask.cancel()
            
            // Wait for the main task to complete
            do {
                try await mainTask.value
            } catch is CancellationError {
                // Expected when shutting down
                logger.debug("NATS client task cancelled successfully")
            } catch {
                logger.error("Error during NATS client shutdown: \(error)")
            }
        }
        
        isStarted = false
        logger.info("NATS event bus shutdown complete")
    }
}
