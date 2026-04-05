# HeliqSDK

A Swift SDK for Hyperliquid DEX, built with Swift 6.0 and async/await concurrency.

## Features

- **Clean Architecture**: Domain, Data, and Core layers for maintainable code
- **Swift 6 Concurrency**: Native async/await throughout the SDK
- **WebSocket Support**: Real-time market data and user event subscriptions
- **Comprehensive API Coverage**: Full support for Hyperliquid Info and Exchange APIs
- **Type-Safe**: All entities conform to `Sendable` for Swift 6 data race safety

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-org/HeliqSDK.git", from: "1.0.0")
]
```

### Xcode

1. File > Add Package Dependencies
2. Enter: `https://github.com/your-org/HeliqSDK.git`
3. Select version and add to your project

## Quick Start

### Initialize the SDK

```swift
import HeliqSDK

// In your AppDelegate or main entry point
func application(_ application: UIApplication, 
    didFinishLaunchingWithOptions...) -> Bool {
    
    HeliqSDK.shared.initialize { builder in
        builder.environment(.mainnet)  // or .testnet, .local
        builder.wallet(myWalletService)
    }
    
    return true
}
```

### Fetch Market Data

```swift
// Read-only operations (no wallet required)
let allMids = try await HeliqSDK.shared.info.getAllMids()
print(allMids.prices)

// Get user state (requires wallet)
let userState = try await HeliqSDK.shared.info.getUserState(address: "0x...")
print(userState.positions)
```

### Place an Order

```swift
let order = OrderRequest(
    asset: 0,
    side: .buy,
    orderType: .limit,
    size: 1.0,
    price: 50000.0
)

let response = try await HeliqSDK.shared.exchange.placeOrder(order)
print(response.status)
```

### WebSocket Subscriptions

```swift
// Subscribe to real-time data
try await HeliqSDK.shared.webSocket.subscribe(to: .allMids)
try await HeliqSDK.shared.webSocket.subscribe(to: .l2Book(coin: "BTC"))

// Listen for updates
HeliqSDK.shared.webSocket.onMessage { data in
    // Handle WebSocket message
}
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    UseCase                          │
│         (Business Logic Orchestration)              │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              Repository Protocol                   │
│              (Abstraction Layer)                    │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│            Repository Implementation               │
│            (Data Access Logic)                     │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   APIClient                         │
│              (URLSession HTTP)                      │
└─────────────────────────────────────────────────────┘
```

## Requirements

- Swift 6.0
- Xcode 16.0+
- iOS 16.0+ / macOS 13.0+

## License

MIT