# WebSocket subscriptions

Retain the service and subscribe when its state becomes `.connected`:

```swift
import Foundation

let ws = WebSocketService(url: URL(string: Constants.WebSocket.testnetURL)!)
await ws.setEventHandler { event in
    switch event {
    case .stateChanged(.connected):
        Task {
            do {
                try await ws.subscribe(HyperliquidWebSocketSubscription(type: .allMids))
            } catch {
                print("Subscription failed: \(error)")
            }
        }
    case .message(let data):
        print(String(decoding: data, as: UTF8.self))
    default:
        break
    }
}
await ws.connect()

// When the feature stops consuming updates:
// await ws.disconnect()
```

`WebSocketService` is an actor. Use `await` for its operations and explicitly hop
to `MainActor` before updating UI from its event handler. The connection handler
above also subscribes again after a successful reconnect.


Connection lifecycle and subscription activity are logged when ``LogLevel/verbose`` is enabled. See <doc:Architecture> for reconnection and routing responsibilities.
