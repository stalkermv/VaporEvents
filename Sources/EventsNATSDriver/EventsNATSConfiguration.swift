//
//  EventsNATSConfiguration.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 06.05.2025.
//

import Foundation
import EventsCore
import Vapor
import NATS

/// Configuration for the NATS event bus
public struct EventsNATSConfiguration: Sendable {
    /// The NATS client configuration
    public let natsConfiguration: NATSClientConfiguration
    
    /// Event name transformer
    public let eventNameTransformer: any EventNameTransformer
    
    /// Retry configuration
    public let maxRetries: Int
    public let retryDelay: TimeInterval
    
    /// Create a new NATS configuration
    /// - Parameters:
    ///   - natsConfiguration: The underlying NATS client configuration
    ///   - eventNameTransformer: Transformer for event names (default: CamelCaseToDotSeparatedTransformer)
    ///   - maxRetries: Maximum number of retries for operations
    ///   - retryDelay: Delay between retries in seconds
    public init(
        natsConfiguration: NATSClientConfiguration = NATSClientConfiguration(),
        eventNameTransformer: any EventNameTransformer = CamelCaseToDotSeparatedTransformer(),
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.natsConfiguration = natsConfiguration
        self.eventNameTransformer = eventNameTransformer
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
    
    /// Create a new NATS configuration with common parameters
    /// - Parameters:
    ///   - url: NATS server URL
    ///   - auth: Authentication mode
    ///   - reconnect: Whether to enable automatic reconnection
    ///   - maxReconnects: Maximum number of reconnection attempts
    ///   - reconnectWait: Time to wait between reconnection attempts
    ///   - eventNameTransformer: Transformer for event names
    ///   - maxRetries: Maximum number of retries for operations
    ///   - retryDelay: Delay between retries in seconds
    public init(
        url: String = "nats://localhost:4222",
        auth: NATSAuthMode = .none,
        reconnect: Bool = true,
        maxReconnects: Int = 10,
        reconnectWait: TimeInterval = 2.0,
        eventNameTransformer: any EventNameTransformer = CamelCaseToDotSeparatedTransformer(),
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0
    ) {
        self.natsConfiguration = NATSClientConfiguration(
            url: url,
            reconnect: reconnect,
            maxReconnects: maxReconnects,
            reconnectWait: reconnectWait,
            auth: auth
        )
        self.eventNameTransformer = eventNameTransformer
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
    }
}
