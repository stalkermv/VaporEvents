# Events

A protocol-based event bus library for Swift applications, inspired by Vapor Queues.

## Features

- Protocol-based abstraction for event publishing and subscription
- Support for different event bus implementations (drivers)
- Easy mocking and testing with in-memory implementation
- Seamless integration with Vapor applications
- Type-safe event handling

## Installation

Add the dependency to your `Package.swift` file:

```swift
.package(url: "https://github.com/yourusername/Events.git", from: "1.0.0")
```

And then add the dependency to your target:
```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "Events", package: "Events")
    ]
)
```

## Usage

### Configuration
Register the event bus in your Vapor application:
```swift
import Vapor
import Events

app.events.use(InMemoryEventBus())
```

### Defining Events

Define your events by conforming to the Event protocol:

```swift
struct UserCreatedEvent: Event {
    struct Payload: Codable {
        let id: UUID
        let name: String
        let email: String
    }
    
    let payload: Payload
}
```

### Publishing Events

Publish events using the event bus:

```swift
let event = UserCreatedEvent(payload: .init(
    id: UUID(),
    name: "John Doe",
    email: "john@example.com"
))

try await app.events.publish(event)
```

### Subscribing to Events
Subscribe to events to handle them:

```swift
app.events.subscribe(UserCreatedEvent.self) { event in
    print("User created: \(event.payload.name)")
}
```

Available Drivers
- InMemoryEventBus: An in-memory implementation for testing and development.

## License
This project is licensed under the MIT License. See the LICENSE file for details.