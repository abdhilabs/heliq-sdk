# Market data

Use ``HeliqClient/info`` for typed market-data requests.

```swift
let mids = try await client.info.getAllMids()
let btcMid = mids.prices["BTC"]
```

The SDK decodes the live Hyperliquid `allMids` response as a flat symbol-to-price map. Prices are exposed by ``AllMids/prices``.

For documented Info request types without a typed wrapper, use ``HeliqClient/raw`` as described in <doc:TypedAndRawTransport>.
