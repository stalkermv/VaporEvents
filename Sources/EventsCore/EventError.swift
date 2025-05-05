//
//  EventError.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//

import Foundation

/// Errors that can be thrown by the event system
public enum EventError: Error {
    case publishFailed(Error)
    case subscribeFailed(Error)
    case unsubscribeFailed(Error)
    case connectionFailed(Error)
    case encodingFailed(Error)
    case decodingFailed(Error)
    case invalidConfiguration(String)
    case notConnected
    case timeout
    case unknown(Error)
}