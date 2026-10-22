# Perps and available balances

Use mode-aware balances instead of treating a unified account's separate Perps
account value as its spendable funds.

```swift
let balances = try await sdk.info.getBalances(address: address)
let capacity = try await sdk.info.getActiveAssetData(address: address, coin: "BTC")
let buyCapacity = capacity.availableToBuy

// Select HIP-3 DEXs explicitly; the default balance read covers validator Perps.
let selected = try await sdk.info.getBalances(address: address, dexes: ["", "xyz"])
```

Spot token balances distinguish total, held, unheld, and server-supplied
available-after-maintenance amounts. Withdrawable values remain optional. Unheld
funds and available-after-maintenance are not interchangeable with withdrawable
funds or a coin's buy/sell trading capacity.

Unified and portfolio-margin accounts share Spot collateral. Their Perps monetary
summaries are omitted to prevent double counting; position data remains available.
Default/unknown modes are retained without guessing their collateral semantics.
Balances across different collateral tokens are never summed into a fabricated USD total.

## Transfers

```swift
if balances.abstraction.supportsClassTransfer {
  _ = try await sdk.exchange.usdClassTransfer(amount: Decimal(1), toPerp: true)
  _ = try await sdk.exchange.usdClassTransfer(amount: Decimal(1), toPerp: false)
}

_ = try await sdk.exchange.sendAsset(
  destination: recipient, source: .spot, destinationLedger: .perps(dex: "xyz"),
  token: tokenNameAndID, amount: Decimal(1))
```

Class transfers apply to explicit standard accounts and never change abstraction
mode automatically. Shared or unresolved modes produce a validation error.
`sendAsset` validates token metadata, token precision, and DEX collateral compatibility.
Margin adjustment amounts use the selected DEX's collateral units; class transfers
move USDC between Spot and validator Perps.

## Typed trading and queries

```swift
let metadata = try await sdk.info.perps(.meta(dex: "xyz"))
let funding = try await sdk.info.perps(.predictedFunding())

let result = try await sdk.exchange.executePerps(.orders([
  .init(market: .coin("BTC"), side: .buy,
    size: Decimal(string: "0.001")!, price: Decimal(50000), kind: .limit(.alo))
]))
```

Use exact metadata coin names, including HIP-3 prefixes. Numeric asset IDs remain
supported. New monetary inputs use Decimal and serialize as protocol decimal
strings; legacy Double APIs retain their existing behavior.

`PerpsAction` covers complete order replacements, batch operations, TP/SL grouping,
leverage, isolated margin, market closes, TWAP, trailing stops, and shared trading
account operations. `PerpsDeployAction` exposes current HIP-3 deployment variants.
User-signed actions reject unsupported vault/expiry contexts. L1 context is passed
into both hashing and the request envelope.

Inspect every order/cancellation status, including partial rejections. Single
modification returns the server acknowledgement without inventing a replacement ID.
The `alwaysPlace` flag is opt-in and can place an order even if cancellation failed;
it is encoded at batch level. False `alwaysPlace` and `fast` flags are omitted.
Mutations are never automatically retried.

## Multisig

```swift
let payload = try await leaderSDK.exchange.preparePerpsMultisig(
  action: action, user: multisigAddress, leader: leaderAddress, nonce: nonce,
  context: .init())
let first = try await firstSignerSDK.exchange.signPerpsMultisig(payload)
let second = try await secondSignerSDK.exchange.signPerpsMultisig(payload)
let result = try await leaderSDK.exchange.executeMultisig(
  .init(payload: payload, signatures: [first, second]))
```

Prepare once: prices and position sizes are resolved before signatures are
collected. Every signer uses that same immutable payload and network. Conversion
and restoration are explicit actions; the SDK never chooses signers or grants
permissions automatically.

## WebSocket

```swift
let topic = PerpsSubscription<PerpsActiveAssetData>.activeAsset(user: address, coin: "BTC")
try router.registerPerpsHandler(for: topic) { result in
  // Handle typed data or decoding errors; hop to MainActor before updating UI.
}
try await subscriptions.subscribe(to: topic)
// Later:
try await subscriptions.unsubscribe(from: topic)
router.unregisterPerpsHandler(for: topic)
```

Typed handlers receive full envelopes and preserve the existing raw-payload handler
behavior. Coin/user/DEX/interval identity is used to route events. Feeds that omit
source identity cannot safely share one typed router across multiple source
subscriptions; registration rejects ambiguous combinations. Fast contexts retain
partial-update semantics and are limited to 4 MiB after decompression.

See the repository's `Docs/PERPS_API_COVERAGE.md` for the complete operation inventory,
fixtures, and privileged-operation limits, and `Docs/TESTNET_WALLET.md` for live test setup.
