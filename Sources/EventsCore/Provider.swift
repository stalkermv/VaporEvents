//
//  EventsProvider.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 05.05.2025.
//
import Vapor

// Extensions for common provider patterns
extension Application.Events {
    /// Register an event bus factory with the application
    public func use<Factory: EventBusFactory>(_ factory: Factory) throws {
        self.use(factory.makeProvider())
    }
}
