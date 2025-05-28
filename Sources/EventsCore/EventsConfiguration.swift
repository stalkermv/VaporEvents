//
//  EventConfiguration.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//

import Foundation
import Vapor

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
    
    public var encoder: JSONEncoder
    public var decoder: JSONDecoder
    
    /// Create a new events configuration
    public init(
        connectionString: String,
        maxRetries: Int = 3,
        retryDelay: TimeInterval = 1.0,
        useTLS: Bool = false,
        encoder: JSONEncoder? = nil,
        decoder: JSONDecoder? = nil
    ) {
        
        self.connectionString = connectionString
        self.maxRetries = maxRetries
        self.retryDelay = retryDelay
        self.useTLS = useTLS
        self.encoder = encoder ?? JSONEncoder.defaultEncoder
        self.decoder = decoder ?? JSONDecoder.defaultDecoder
    }
}

extension JSONEncoder {
    static var defaultEncoder: JSONEncoder {
        let contentEncoder = try? ContentConfiguration.global.requireEncoder(for: .json)
        let encoder = (contentEncoder as? JSONEncoder)
        return encoder ?? JSONEncoder()
    }
}

extension JSONDecoder {
    static var defaultDecoder: JSONDecoder {
        let contentDecoder = try? ContentConfiguration.global.requireDecoder(for: .json)
        let decoder = (contentDecoder as? JSONDecoder)
        return decoder ?? JSONDecoder()
    }
}
