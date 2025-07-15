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
        
        // Convert camelCase to words, handling consecutive uppercase letters
        var result = ""
        let characters = Array(name)
        
        for (index, char) in characters.enumerated() {
            let isFirst = index == 0
            let isLast = index == characters.count - 1
            let previousChar = isFirst ? nil : characters[index - 1]
            let nextChar = isLast ? nil : characters[index + 1]
            
            // Add dot before uppercase letter in these cases:
            // 1. Previous char is lowercase and current is uppercase (standard camelCase)
            // 2. Previous char is uppercase, current is uppercase, and next is lowercase (end of acronym)
            if !isFirst {
                let shouldAddDot: Bool
                if let prev = previousChar {
                    if prev.isLowercase && char.isUppercase {
                        // Standard camelCase transition: htmlParser -> html.Parser
                        shouldAddDot = true
                    } else if prev.isUppercase && char.isUppercase, let next = nextChar, next.isLowercase {
                        // End of acronym: HTMLParser -> HTML.Parser
                        shouldAddDot = true
                    } else {
                        shouldAddDot = false
                    }
                } else {
                    shouldAddDot = false
                }
                
                if shouldAddDot {
                    result.append(".")
                }
            }
            
            result.append(char.lowercased())
        }
        
        return result
    }
}