# Getting started

## Install

Add the Swift package at `https://github.com/abdhilabs/heliq-sdk.git`, select version `1.0.0` or later, and link the `HeliqSDK` product. The SDK requires Swift 6.1 or later and supports iOS 16 and macOS 13 or later.

## Create a client

Create an independent client for your selected environment. Read-only queries do not require a wallet.

```swift
import HeliqSDK

let client = try HeliqClient.Builder()
  .environment(.testnet)
  .build()

let mids = try await client.info.getAllMids()
```

``HeliqClient/Builder`` defaults to ``HeliqEnvironment/mainnet`` and ``LogLevel/disabled``. Each client retains its own environment and wallet. Logging is global; the most recently built client sets its level.

## Add signing for trading

Create a type that conforms to ``WalletServiceProtocol``. Its `address` is the account address. Implement `signL1` and `signUserSigned` for trading, or use the native `WalletService(keyManager:)`. Private-key custody remains the application's responsibility.

```swift
let tradingClient = try HeliqClient.Builder()
  .environment(.testnet)
  .wallet(myWallet)
  .build()
```

Signed exchange calls fail explicitly when no wallet is configured.

## Choose an environment

Use ``HeliqEnvironment/mainnet`` for production, ``HeliqEnvironment/testnet`` for testnet, and ``HeliqEnvironment/local`` only when your application provides a compatible local endpoint.

## Next steps

- Fetch prices with <doc:MarketData>.
- Use typed account and trading workflows with <doc:PlacingOrders>.
- Use <doc:TypedAndRawTransport> when a typed convenience wrapper is unavailable.
