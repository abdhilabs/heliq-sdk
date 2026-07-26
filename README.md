# HeliqSDK

A Swift SDK for Hyperliquid DEX, built with Swift 6.0 and async/await concurrency.

## Features

- **Clean Architecture**: Domain, Data, and Core layers for maintainable code
- **Swift 6 Concurrency**: Native async/await throughout the SDK
- **WebSocket Support**: Real-time market data and user event subscriptions
- **Type-Safe**: All entities conform to `Sendable` for Swift 6 data race safety
- **Full Hyperliquid Transport Coverage**: Official Info (`/info`), Exchange (`/exchange`), WebSocket subscriptions, WebSocket `post` requests, exact unsubscribe payloads, and normal inbound `channel`/`data` events are supported through the lossless `raw` / `HyperliquidWebSocketSubscription` APIs. Core convenience repositories remain additive typed wrappers.

> **Coverage note:** HeliqSDK provides core typed convenience repositories plus a full lossless transport layer. Hyperliquid responses evolve frequently, so advanced responses return `JSONValue` rather than lossy SDK models.

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/your-org/HeliqSDK.git", from: "1.0.0")
]
```

### Xcode

1. File > Add Package Dependencies
2. Enter the repository URL
3. Select version and add to your project

## Quick Start

### Initialize the SDK

```swift
import HeliqSDK

HeliqSDK.shared.initialize { builder in
    builder.environment(.mainnet)  // or .testnet, .local
    builder.wallet(myWalletService)
}
```

### Fetch Market Data

```swift
let allMids = try await HeliqSDK.shared.info.getAllMids()
print(allMids.prices)

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
// Low-level WebSocketService
let ws = WebSocketService(url: URL(string: Constants.WebSocket.mainnetURL)!)
ws.connect()
try ws.subscribe(channel: "allMids")
try ws.subscribe(channel: "l2Book", payload: ["coin": "BTC"])
```

## Hyperliquid API Coverage

Validated against official docs:
- [Info endpoint](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint)
- [Exchange endpoint](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint)
- [WebSocket subscriptions](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions)

### Full-surface raw transport (`POST /info`, `POST /exchange`, WebSocket)

The `InfoRepository` and `ExchangeRepository` APIs below are typed convenience wrappers. For full Hyperliquid surface parity, use the lossless transport. Every documented request/action field is supplied in `parameters` and responses decode as `JSONValue`, so new server response fields are never discarded.

```swift
// Any documented Info request type, including openOrders, portfolio, staking,
// vault, HIP-3, and borrow/lend requests.
let result = try await HeliqSDK.shared.raw.info(.init(
    type: .openOrders,
    parameters: ["user": .string("0x...")]
))

// Signed Exchange actions. Sign EIP-712 action externally until native signer is available.
let action = HyperliquidExchangeAction(type: .twapOrder, parameters: [
    "twap": .object([/* official action fields */])
])
let response = try await HeliqSDK.shared.raw.exchange(.init(
    action: action, nonce: nonce, signature: signature, expiresAfter: expiry
))

// Any documented WebSocket feed, preserving user, coin, dex, and optional fields.
let subscription = HyperliquidWebSocketSubscription(
    type: .openOrders,
    parameters: ["user": .string("0x..."), "dex": .string("xyz")]
)
try ws.subscribe(subscription)
```

### Typed convenience APIs

### Info API (`POST /info`) — typed convenience methods

| SDK method | Request `type` |
|---|---|
| `getUserState` | `userState` |
| `getSpotUserState` | `spotUserState` |
| `getAllMids` | `allMids` |
| `getAssetCtxs` | `assetCtxs` |
| `getSpotAssetCtxs` | `spotAssetCtxs` |
| `getCandleSnapshot` | `candleSnapshot` |
| `getL2Book` | `l2Book` |
| `queryOrderByOid` | `queryOrderByOid` |
| `queryOrderByCloid` | `queryOrderByCloid` |
| `queryFills` | `queryFills` |
| `queryUserFundings` | `queryUserFundings` |
| `getMeta` | `meta` |
| `getSpotMeta` | `spotMeta` |
| `getTime` | `getTime` |
| `fetchBuilderFee` | `fetchBuilderFee` |

### Info API — raw transport coverage

All official Info request types are available through `HyperliquidInfoType` and `.custom(String)`. This includes open orders, frontend orders, fills/time-range queries, rate limits, order status, historical/TWAP data, subaccounts, staking/delegation, portfolio/fees/referral, metadata/context variants, vault data, HIP-3, builder approvals, and borrow/lend state.

### Exchange API (`POST /exchange`) — typed convenience methods

| SDK method | Action `type` |
|---|---|
| `placeOrder` | `order` |
| `bulkOrders` | `bulkOrders` |
| `cancelOrder` | `cancel` |
| `cancelByCloid` | `cancelByCloid` |
| `cancelAll` | `cancelAll` |
| `modifyOrder` | `modify` |
| `modifyByCloid` | `modifyByCloid` |
| `setLeverage` | `setLeverage` |
| `setMarginMode` | `setMarginMode` |
| `transfer` | `transfer` |
| `sendToAddress` | `sendToAddress` |
| `spotTransfer` | `spotTransfer` |
| `vaultTransfer` | `vaultTransfer` |
| `updateBuilder` | `updateBuilder` |
| `scheduleCancel` | `scheduleCancel` |
| `setReferrer` | `setReferrer` |
| `convertToMultiSigUser` | `convertToMultiSig` |
| `usdSend` | `usdSend` |

### Exchange API — raw transport coverage

All official signed Exchange actions are available through `HyperliquidExchangeActionType` and `.custom(String)`, including withdrawals, spot sends, USDC-class transfers, leverage/margin updates, batch modifications, TWAP, agent/builder approvals, vault/sub-account actions, delegation, Core deposits/withdrawals, multi-sig, and request-weight reservation.

> **Signing:** `Signer` supports canonical-MessagePack L1 `Agent` signatures and caller-schema user-signed EIP-712 envelopes. Official golden vectors cover L1 mainnet/testnet and the USD-transfer user-signed schema; each further typed user-signed schema requires its own fixture before it is claimed verified. `HyperliquidExchangeEnvelope` still accepts caller-provided `SignatureTypes` for hardware wallets, contract wallets, and externally managed keys; the SDK never serializes or transmits a private key.

### WebSocket — typed convenience channels

`allMids`, `l2Book`, `trades`, `userEvents`, `userFills`, `candle`, `orderUpdates`, `userFundings`, `userNonFundingLedgerUpdates`, `webData2`, `bbo`, `activeAssetCtx`, `activeAssetData`

### WebSocket — raw transport coverage

All official subscriptions, including `notification`, `webData3`, `twapStates`, `clearinghouseState`, `openOrders`, user TWAP feeds, `spotState`, all-DEX state/context, outcome metadata, and compressed `fastAssetCtxs`, are available through `HyperliquidWebSocketSubscription`. `FastAssetCtxDecoder` decodes the documented raw-DEFLATE payload into typed sparse asset-context updates. User-scoped fields are carried explicitly in `parameters`.

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    UseCase                          │
│         (Business Logic Orchestration)              │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              Repository Protocol                   │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│            Repository Implementation               │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   APIClient                         │
│              (URLSession HTTP)                      │
└─────────────────────────────────────────────────────┘
```

## Testing

| Suite | Target | What it covers |
|---|---|---|
| Unit | `HeliqSDKTests` | Entities, errors, repos (mocked), use cases, network helpers, feature-coverage matrix |
| Integration | `HeliqSDKIntegrationTests` | Live testnet Info / Exchange / WebSocket for every implemented method |
| UI | `HeliqSDKDemoUITests` | Demo app navigation + feature screens |

```bash
# Unit (CI)
xcodebuild test -project HeliqSDK.xcodeproj -scheme HeliqSDK -destination 'platform=iOS Simulator,name=iPhone Air'

# Integration (local / testnet)
xcodebuild test -project HeliqSDK.xcodeproj -scheme HeliqSDKIntegrationTests -destination 'platform=iOS Simulator,name=iPhone Air'

# UI (demo)
xcodebuild test -project HeliqSDK.xcodeproj -scheme HeliqSDKDemo -destination 'platform=iOS Simulator,name=iPhone Air'
```

See [TEST_PLAN.md](./TEST_PLAN.md) and [PLAN.md](./PLAN.md) for details.

## Requirements

- Swift 6.0
- Xcode 16.0+
- iOS 16.0+ / macOS 13.0+ (SPM); demo app targets iOS 17.0+

## License

MIT
