//
//  EventBusFactory.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//

import Foundation
import Vapor
//
///// Protocol for creating event bus instances
//public protocol EventBusFactory: Sendable {
//    /// The type of event bus this factory creates
//    associatedtype Bus: EventBus
//    
//    /// Create a new event bus
//    func makeEventBus(for app: Application) throws -> Bus
//}
//
//extension EventBusFactory {
//    /// Create a provider for this factory
//    public func makeProvider() -> Application.Events.Provider {
//        .init { app in
//            do {
//                app.events.use(custom: try self.makeEventBus(for: app))
//            } catch {
//                app.logger.error("Failed to create event bus: \(error)")
//                fatalError("Failed to create event bus: \(error)")
//            }
//        }
//    }
//}
