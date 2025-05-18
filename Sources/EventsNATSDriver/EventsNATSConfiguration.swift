//
//  EventsNATSConfiguration.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 06.05.2025.
//

import Foundation
import EventsCore
import Vapor

/// Configuration for the NATS event bus
public struct EventsNATSConfiguration: Sendable {
    /// The URL of the NATS server
    public let url: URL
    
    /// Authentication credentials
    public let credentials: Credentials?
    
    /// TLS configuration
    public let tlsConfiguration: TLSConfiguration?
    
    /// Event name transformer
    public let eventNameTransformer: any EventNameTransformer
    
    /// Authentication credentials for NATS
    public enum Credentials: Sendable {
        /// Username and password authentication
        case userPass(username: String, password: String)
        
        /// JWT authentication
        case jwt(jwt: String, nkey: String)
        
        /// Token authentication
        case token(String)
    }
    
    /// Create a new NATS configuration
    /// - Parameters:
    ///   - url: The URL of the NATS server
    ///   - credentials: Authentication credentials
    ///   - tlsConfiguration: TLS configuration
    ///   - eventNameTransformer: Transformer for event names (default: CamelCaseToDotSeparatedTransformer)
    public init(
        url: URL = URL(string: "nats://localhost:4222")!,
        credentials: Credentials? = nil,
        tlsConfiguration: TLSConfiguration? = nil,
        eventNameTransformer: any EventNameTransformer = CamelCaseToDotSeparatedTransformer()
    ) {
        self.url = url
        self.credentials = credentials
        self.tlsConfiguration = tlsConfiguration
        self.eventNameTransformer = eventNameTransformer
    }
}
