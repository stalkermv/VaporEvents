# VaporEvents

A robust event-driven architecture library for Vapor applications with support for multiple drivers including in-memory and NATS.

## Features

- 🎯 **Type-safe events** with Swift generics
- 🚀 **Multiple drivers**: In-memory and NATS support
- 🔄 **Event handlers** similar to Vapor Queues
- 🏗️ **Clean architecture** with driver abstraction
- 🔧 **Easy configuration** and Vapor integration
- 📦 **ServiceLifecycle** integration for proper startup/shutdown
- Easy mocking and testing with in-memory implementation
- Seamless integration with Vapor applications
- Type-safe event handling

## Installation

Add VaporEvents to your Package.swift:

```swift
dependencies: [
    .package(url: "https://github.com/stalkermv/VaporEvents.git", from: "1.0.0")
]
```

Then add the products to your target:

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Events", package: "VaporEvents"),
        .product(name: "EventsMemoryDriver", package: "VaporEvents"),
        .product(name: "EventsNATSDriver", package: "VaporEvents"), // Optional
    ]
)
```

## Quick Start

### 1. Define Events

```swift
import Events

struct UserCreatedEvent: Event, Codable {
    let userId: UUID
    let email: String
    let createdAt: Date
}
```

### 2. Create Event Handlers

```swift
import Events
import Vapor

struct UserCreatedEventHandler: EventHandler {
    typealias E = UserCreatedEvent
    
    static func handle(context: Context) async throws {
        let user = context.payload
        
        // Send welcome email
        try await context.application.mail.send(
            to: user.email,
            subject: "Welcome!",
            body: "Welcome to our platform!"
        )
        
        // Log the event
        context.application.logger.info("User \(user.userId) created at \(user.createdAt)")
    }
}
```

### 3. Configure the Event Bus

#### In-Memory Driver (for development/testing)

```swift
import Vapor
import Events
import EventsMemoryDriver

func configure(_ app: Application) throws {
    // Configure in-memory event bus
    app.events.use(.inMemory)
}
```

#### NATS Driver (for production)

```swift
import Vapor
import Events
import EventsNATSDriver
import NATS

func configure(_ app: Application) throws {
    // Basic NATS configuration
    app.events.use(.nats())
    
    // Or with custom configuration
    let natsConfig = EventsNATSConfiguration(
        natsConfiguration: NATSClientConfiguration(
            auth: .userPassword(user: "app", password: "secret")
        ),
        maxRetries: 5,
        retryDelay: 2.0
    )
    app.events.use(.nats(configuration: natsConfig))
}
```

### 4. Subscribe to Events

```swift
import Vapor
import Events

func routes(_ app: Application) throws {
    // Subscribe using event handler
    try await app.events.subscribe(UserCreatedEventHandler.self)
    
    // Or subscribe with a closure
    try await app.events.subscribe(UserCreatedEvent.self) { payload in
        print("User created: \(payload.email)")
    }
}
```

### 5. Publish Events

```swift
import Vapor

func routes(_ app: Application) throws {
    app.post("users") { req async throws -> HTTPStatus in
        let userInput = try req.content.decode(CreateUserRequest.self)
        
        // Create user logic here...
        let userId = UUID()
        
        // Publish event
        let event = UserCreatedEvent(
            userId: userId,
            email: userInput.email,
            createdAt: Date()
        )
        
        try await req.application.events.publish(event)
        
        return .created
    }
}
```

## Advanced Usage

### Custom Event Names

Events use their type name by default, but you can customize it:

```swift
struct UserCreatedEvent: Event, Codable {
    static let name = "user.created"  // Custom name
    
    let userId: UUID
    let email: String
}
```

### Event Name Transformation

NATS driver supports automatic event name transformation:

```swift
// Transform CamelCase to dot.separated
let transformer = CamelCaseToDotSeparatedTransformer()
// UserCreatedEvent -> user.created.event

let config = EventsNATSConfiguration(
    eventNameTransformer: transformer
)
```

### NATS Authentication

```swift
// Username/Password
let config = EventsNATSConfiguration(
    natsConfiguration: NATSClientConfiguration(
        auth: .userPassword(user: "app", password: "secret")
    )
)

// JWT Token
let config = EventsNATSConfiguration(
    natsConfiguration: NATSClientConfiguration(
        auth: .token("your-jwt-token")
    )
)

// JWT with credentials file
let config = EventsNATSConfiguration(
    natsConfiguration: NATSClientConfiguration(
        auth: .jwtCredsFile(file: "/path/to/creds.file")
    )
)
```

### Error Handling

```swift
do {
    try await app.events.publish(event)
} catch EventError.publishFailed(let error) {
    app.logger.error("Failed to publish event: \(error)")
} catch {
    app.logger.error("Unexpected error: \(error)")
}
```

### Lifecycle Management

The event bus automatically integrates with Vapor's lifecycle:

```swift
// Manual shutdown (if needed)
func shutdown(_ app: Application) async throws {
    try await app.events.driver.shutdown()
}
```

## Architecture

VaporEvents follows a clean architecture pattern:

```
┌─────────────────┐    ┌──────────────────┐
│   Application   │    │   Event Handler  │
│                 │    │                  │
│  events.publish │    │  handle(context) │
│  events.subscribe │    │                 │
└─────────┬───────┘    └──────────────────┘
          │
          ▼
┌─────────────────┐
│   Events Core   │
│                 │
│   EventBus      │
│   Event         │
│   EventHandler  │
└─────────┬───────┘
          │
          ▼
┌─────────────────┐    ┌──────────────────┐
│  Memory Driver  │    │   NATS Driver    │
│                 │    │                  │
│  In-memory      │    │  SwiftNATSClient │
│  Event storage  │    │  Distributed     │
└─────────────────┘    └──────────────────┘
```

## Testing

For testing, use the in-memory driver:

```swift
import Testing
import Vapor
import Events
import EventsMemoryDriver

@Test
func testEventPublishing() async throws {
    let app = try await Application.make(.testing)
    app.events.use(.inMemory)
    
    var receivedEvent: UserCreatedEvent?
    
    try await app.events.subscribe(UserCreatedEvent.self) { payload in
        receivedEvent = payload
    }
    
    let event = UserCreatedEvent(
        userId: UUID(),
        email: "test@example.com",
        createdAt: Date()
    )
    
    try await app.events.publish(event)
    
    // Verify event was received
    #expect(receivedEvent?.email == "test@example.com")
    
    try await app.asyncShutdown()
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License.
This project is licensed under the MIT License. See the LICENSE file for details.
