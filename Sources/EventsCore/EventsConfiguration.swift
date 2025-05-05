//
//  EventConfiguration.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//

import Foundation

/// Configuration for the event bus
public struct EventsConfiguration: Sendable {
    /// The connection string
    public var connectionString: String
    
    /// The maximum number of retries
    public var maxRetries: Int
    
    /// The retry delay in seconds
    public var retryDelay: TimeInterval
    
    /// Whether to use TLS
    public var useTLS: Bool
    
    /// Create a new events configuration
    public init(
        connectionString: String,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        useTLS: Bool = false
    ) {
        self.connectionString = connectionString
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.useTLS = useTLS
    }
}
