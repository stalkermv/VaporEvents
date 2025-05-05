//
//  Request+Events.swift
//  Events
//
//  Created by Valeriy Malishevskyi on 06.05.2025.
//

import Vapor

// MARK: - Request Extension
extension Request {
    public var events: Application.Events {
        application.events
    }
}
