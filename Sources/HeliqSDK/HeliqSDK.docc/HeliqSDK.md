# ``HeliqSDK``

A Swift SDK for Hyperliquid market data, exchange actions, raw protocol transport, and WebSocket subscriptions.

## Overview

`HeliqSDK` provides two layers:

- Typed convenience repositories for common market-data and exchange workflows.
- ``HyperliquidAPI`` raw transport for documented Info and Exchange requests not yet represented by a typed wrapper.

Initialize the shared SDK once before accessing ``HeliqSDK/info``, ``HeliqSDK/exchange``, or ``HeliqSDK/raw``.

```swift
HeliqSDK.shared.initialize { builder in
  builder
    .environment(.mainnet)
    .wallet(myWallet)
    .logging(.verbose)
}
```

> Important: A wallet is required during initialization. Keep private keys outside the SDK; implement ``WalletServiceProtocol`` using your own secure signer.

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:MarketData>
- <doc:PlacingOrders>
- <doc:WebSocketSubscriptions>
- <doc:LoggingAndDiagnostics>
- <doc:ErrorHandling>

### Protocol coverage

- <doc:TypedAndRawTransport>
- ``HeliqSDK``
- ``InfoRepository``
- ``ExchangeRepository``
- ``HyperliquidAPI``

### Contributor architecture

- <doc:Architecture>
- <doc:NetworkPipeline>
- <doc:SigningBoundary>
- <doc:Testing>
