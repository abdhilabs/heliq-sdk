# ``HeliqSDK``

A Swift SDK for Hyperliquid market data, exchange actions, raw protocol transport, and WebSocket subscriptions.

## Overview

`HeliqSDK` provides two layers:

- Typed convenience repositories for common market-data and exchange workflows.
- ``HyperliquidAPI`` raw transport for documented Info and Exchange requests not yet represented by a typed wrapper.

Create a ``HeliqClient`` before accessing its ``HeliqClient/info``, ``HeliqClient/exchange``, or ``HeliqClient/raw`` interfaces.

```swift
import HeliqSDK

let client = try HeliqClient.Builder()
  .environment(.testnet)
  .build()

let mids = try await client.info.getAllMids()
```

Read-only queries do not require a wallet. For signed actions, supply a ``WalletServiceProtocol``
with `.wallet(myWallet)` before building the client. Applications choose external custody or
the optional <doc:LocalWalletStorage>.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:MarketData>
- <doc:PlacingOrders>
- <doc:WebSocketSubscriptions>
- <doc:LoggingAndDiagnostics>
- <doc:ErrorHandling>
- <doc:LocalWalletStorage>

### Protocol coverage

- <doc:TypedAndRawTransport>
- ``HeliqClient``
- ``InfoRepository``
- ``ExchangeRepository``
- ``HyperliquidAPI``

### Contributor architecture

- <doc:Architecture>
- <doc:NetworkPipeline>
- <doc:SigningBoundary>
- <doc:Testing>
