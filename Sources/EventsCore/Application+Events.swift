import Foundation
import Logging
import Vapor
import NIO
import NIOConcurrencyHelpers

extension Application {
    /// The application-global ``Events`` accessor.
    public var events: Events {
        .init(application: self)
    }
    
    /// Contains global configuration for events and provides methods for registering event handlers and retrieving event buses.
    public struct Events {
        /// A provider for an ``Events`` driver.
        public struct Provider {
            let run: @Sendable (Application) -> ()
            
            public init(_ run: @escaping @Sendable (Application) -> ()) {
                self.run = run
            }
        }
        
        final class Storage: Sendable {
            private struct Box: Sendable {
                var configuration: EventsConfiguration
                var driver: (any EventBus)?
            }
            private let box: NIOLockedValueBox<Box>
            
            public var configuration: EventsConfiguration {
                get { self.box.withLockedValue { $0.configuration } }
                set { self.box.withLockedValue { $0.configuration = newValue } }
            }
            
            var driver: (any EventBus)? {
                get { self.box.withLockedValue { $0.driver } }
                set { self.box.withLockedValue { $0.driver = newValue } }
            }
            
            public init(_ application: Application) {
                self.box = .init(.init(
                    configuration: .init(connectionString: ""),
                    driver: nil
                ))
            }
        }
        
        struct Key: StorageKey {
            typealias Value = Storage
        }
        
        struct Lifecycle: LifecycleHandler {
            func shutdown(_ application: Application) {
                Task {
                    try? await application.events.storage.driver?.shutdown()
                }
            }
        }
        
        /// The ``EventsConfiguration`` object.
        public var configuration: EventsConfiguration {
            get { self.storage.configuration }
            nonmutating set { self.storage.configuration = newValue }
        }
        
        /// The selected ``EventBus``.
        public var driver: any EventBus {
            guard let driver = self.storage.driver else {
                fatalError("No Events driver configured. Configure with app.events.use(...)")
            }
            return driver
        }
        
        var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            return self.application.storage[Key.self]!
        }
        
        private func initialize() {
            self.application.storage[Key.self] = .init(self.application)
            self.application.lifecycle.use(Lifecycle())
        }
        
        public let application: Application
        
        /// Publish an event to the event bus
        public func publish<E: Event>(_ event: E) async throws {
            try await self.driver.publish(event)
        }
        
        /// Subscribe to events of a specific type
        public func subscribe<E: Event>(
            _ type: E.Type,
            handler: @escaping @Sendable (E) async throws -> Void
        ) async throws {
            try await self.driver.subscribe(type, handler: handler)
        }
        
        /// Unsubscribe from events of a specific type
        public func unsubscribe<E: Event>(_ type: E.Type) async throws {
            try await self.driver.unsubscribe(type)
        }
        
        /// Choose which provider to use.
        public func use(_ provider: Provider) {
            provider.run(self.application)
        }
        
        /// Configure a driver.
        public func use(custom driver: any EventBus) {
            self.storage.driver = driver
        }
    }
}
