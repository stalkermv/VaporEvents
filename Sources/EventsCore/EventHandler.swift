import Foundation
import Vapor

/// Protocol for event handlers, similar to Vapor Queues.
public protocol EventHandler: Sendable {
    typealias Context = EventHandlerContext<E>
    
    associatedtype E: Event
    static func handle(context: Context) async throws
}

public struct EventHandlerContext<E: Event>: Sendable {
    public let payload: E.Payload
    public let application: Application
    
    public init(payload: E.Payload, application: Application) {
        self.payload = payload
        self.application = application
    }
}

