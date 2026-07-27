# Getting started

## Initialize the SDK

Create a type that conforms to ``WalletServiceProtocol``. Its `address` is the account address and its `sign(message:)` implementation must delegate to a secure signing implementation owned by your application.

```swift
HeliqSDK.shared.initialize { builder in
  builder
    .environment(.mainnet)
    .wallet(myWallet)
    .logging(.disabled)
}
```

``Builder`` defaults to ``HeliqEnvironment/mainnet`` and ``LogLevel/disabled``. It requires a wallet. Every later call to ``HeliqSDK/initialize(configure:)`` replaces the active container and logging configuration.

## Choose an environment

Use ``HeliqEnvironment/mainnet`` for production, ``HeliqEnvironment/testnet`` for testnet, and ``HeliqEnvironment/local`` only when your application provides a compatible local endpoint.

## Next steps

- Fetch prices with <doc:MarketData>.
- Use typed account and trading workflows with <doc:PlacingOrders>.
- Use <doc:TypedAndRawTransport> when a typed convenience wrapper is unavailable.
