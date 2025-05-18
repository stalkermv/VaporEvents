//
//  EventNameTransformer.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 06.05.2025.
//

import Foundation

/// Protocol for transforming event names
public protocol EventNameTransformer: Sendable {
    /// Transform an event name
    /// - Parameter name: The original event name
    /// - Returns: The transformed event name
    func transform(_ name: String) -> String
}

/// Default implementation that doesn't transform the name
public struct IdentityEventNameTransformer: EventNameTransformer {
    public init() {}
    
    public func transform(_ name: String) -> String {
        return name
    }
}

/// Transforms camelCase event names to dot-separated lowercase format
/// Example: "EventExampleName" -> "event.example.name"
public struct CamelCaseToDotSeparatedTransformer: EventNameTransformer {
    public init() {}
    
    public func transform(_ name: String) -> String {
        guard !name.isEmpty else { return name }
        
        // Convert camelCase to words
        var result = ""
        var previousChar: Character?
        
        for char in name {
            if let prev = previousChar, 
               prev.isLowercase && char.isUppercase {
                result.append(".")
            }
            result.append(char.lowercased())
            previousChar = char
        }
        
        return result
    }
}