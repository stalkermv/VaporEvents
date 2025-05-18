//
//  EventsNATSFactory.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 06.05.2025.
//

import Foundation
import EventsCore
import Vapor

extension Application.Events.Provider {
    /// Create a NATS provider with the given configuration
    /// - Parameter configuration: The configuration
    /// - Returns: A provider for the NATS event bus
    public static func nats(
        configuration: EventsNATSConfiguration = .init(),
        logger: Logger? = nil
    ) -> Self {
        .init { application in
            let driver = EventsNATSDriver(
                configuration: configuration,
                logger: logger ?? application.logger
            )
            
            // Store the driver
            application.events.use(custom: driver)
            
            // Connect in the background
            Task {
                do {
                    try await driver.connect()
                } catch {
                    application.logger.error("Failed to connect to NATS: \(error)")
                }
            }
        }
    }
}
