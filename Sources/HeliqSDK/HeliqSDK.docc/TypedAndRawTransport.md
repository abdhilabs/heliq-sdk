# Typed and raw transport

The SDK has distinct typed and raw layers.

## Typed convenience layer

``InfoRepository`` and ``ExchangeRepository`` provide stable Swift models for implemented workflows. Prefer these interfaces when they expose the request you need.

## Raw transport layer

``HyperliquidAPI`` accepts official request/action parameters and returns lossless ``JSONValue`` responses. It is the extension point for documented protocol features that do not have a typed convenience wrapper.

```swift
let response = try await HeliqSDK.shared.raw.info(
  .init(type: .openOrders, parameters: ["user": .string("0x...")])
)
```

Raw transport parity does not mean every request has a dedicated typed model. See <doc:Architecture> for the contributor boundary that keeps this distinction explicit.
