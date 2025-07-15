import Testing
import Foundation
import Vapor
import NATS
@testable import Events
@testable import EventsCore
@testable import EventsMemoryDriver
@testable import EventsNATSDriver

// Test event
struct TestEvent: Event, Codable {
    static let name = "test.event"
    let message: String
    let timestamp: Date
}

// Test event handler
struct TestEventHandler: EventHandler {
    typealias E = TestEvent
    
    static func handle(context: Context) async throws {
        print("Handled event: \(context.payload.message) at \(context.payload.timestamp)")
    }
}

@Test("Memory Driver Basic Test")
func testMemoryDriver() async throws {
    let app = try await Application.make(.testing)
    
    // Configure in-memory driver
    app.events.use(.inMemory)
    
    let receivedEventBox = ActorBox<TestEvent?>(nil)
    
    // Subscribe to events
    try await app.events.subscribe(TestEvent.self) { payload in
        await receivedEventBox.setValue(payload)
    }
    
    // Publish an event
    let testEvent = TestEvent(message: "Hello World", timestamp: Date())
    try await app.events.publish(testEvent)
    
    // Give the event time to be processed
    try await Task.sleep(for: .milliseconds(100))
    
    // Verify the event was received
    let receivedEvent = await receivedEventBox.getValue()
    #expect(receivedEvent != nil)
    #expect(receivedEvent?.message == "Hello World")
    
    try await app.asyncShutdown()
}

@Test("Event Handler Registration")
func testEventHandlerRegistration() async throws {
    let app = try await Application.make(.testing)
    
    // Configure in-memory driver
    app.events.use(.inMemory)
    
    // Subscribe using handler type
    try await app.events.subscribe(TestEventHandler.self)
    
    // Publish an event
    let testEvent = TestEvent(message: "Handler Test", timestamp: Date())
    try await app.events.publish(testEvent)
    
    // Give the event time to be processed
    try await Task.sleep(for: .milliseconds(100))
    
    try await app.asyncShutdown()
}

@Test("NATS Configuration")
func testNATSConfiguration() async throws {
    // Test basic configuration
    let config1 = EventsNATSConfiguration()
    #expect(config1.maxRetries == 3)
    #expect(config1.retryDelay == 1.0)
    
    // Test configuration with auth
    let config2 = EventsNATSConfiguration(
        url: "nats://test:4222",
        auth: .userPassword(user: "test", password: "test"),
        maxRetries: 5,
        retryDelay: 2.0
    )
    #expect(config2.maxRetries == 5)
    #expect(config2.retryDelay == 2.0)
}

@Test("Event Name Transformation")
func testEventNameTransformation() async throws {
    let transformer = CamelCaseToDotSeparatedTransformer()
    
    #expect(transformer.transform("TestEvent") == "test.event")
    #expect(transformer.transform("UserCreatedEvent") == "user.created.event")
    #expect(transformer.transform("HTMLParserEvent") == "html.parser.event")
}

// Helper actor for thread-safe value storage
actor ActorBox<T> {
    private var value: T
    
    init(_ initialValue: T) {
        self.value = initialValue
    }
    
    func setValue(_ newValue: T) {
        self.value = newValue
    }
    
    func getValue() -> T {
        return value
    }
}
