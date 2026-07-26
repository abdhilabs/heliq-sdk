# HeliqSDK

A Swift SDK for Hyperliquid DEX, built with Swift 6.0 and async/await concurrency.

## Features

- **Clean Architecture**: Domain, Data, and Core layers for maintainable code
- **Swift 6 Concurrency**: Native async/await throughout the SDK
- **WebSocket Support**: Real-time market data and user event subscriptions
- **Type-Safe**: All entities conform to `Sendable` for Swift 6 data race safety
- **Partial Hyperliquid Coverage**: Core Info + Exchange + WS surfaces are implemented; advanced HL features are tracked as gaps (see below)

> **Coverage note:** README previously claimed “full” Hyperliquid coverage. That was inaccurate. See [Hyperliquid API Coverage](#hyperliquid-api-coverage) for the honest matrix.

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

### Info API (`POST /info`) — implemented

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

### Info API — **not yet implemented** (known gaps)

`openOrders`, `frontendOpenOrders`, `userFills` / `userFillsByTime` (official names), `historicalOrders`, `orderStatus`, `portfolio`, `userRole`, `userFees`, `referral`, `subAccounts`, `vaultDetails`, `userVaultEquities`, `userTwapSliceFills`, `maxBuilderFee`, `approvedBuilders`, `clearinghouseState`, `metaAndAssetCtxs`, `spotMetaAndAssetCtxs`, `predictedFundings`, staking/delegator queries, borrow/lend queries, and more.

### Exchange API (`POST /exchange`) — implemented

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

### Exchange API — **not yet implemented** (known gaps)

`withdraw3`, `spotSend`, `usdClassTransfer`, `updateLeverage` / `updateIsolatedMargin` (official names), `batchModify`, `twapOrder` / `twapCancel`, `approveAgent`, `approveBuilderFee`, `cDeposit` / `cWithdraw`, `tokenDelegate`, sub-account create/transfer, `sendAsset`, and more.

> **Wire-format caveat:** Several exchange action type strings and request body shapes in the SDK are simplified vs the official Hyperliquid Python SDK. Integration tests currently exercise “does not crash / surfaces API or decode error” rather than full golden-payload parity. Treat signed exchange calls as **beta** until payload parity is locked.

### WebSocket — implemented channels

`allMids`, `l2Book`, `trades`, `userEvents`, `userFills`, `candle`, `orderUpdates`, `userFundings`, `userNonFundingLedgerUpdates`, `webData2`, `bbo`, `activeAssetCtx`, `activeAssetData`

### WebSocket — **not yet implemented**

`notification`, `webData3`, `twapStates`, `clearinghouseState`, `openOrders`, `userTwapSliceFills`, `userTwapHistory`, `spotState`, `allDexsClearinghouseState`, `allDexsAssetCtxs`, `outcomeMetaUpdates`, `fastAssetCtxs`

Also: user-scoped channels currently do **not** attach a `user` address in `SubscriptionChannel.payload` — callers must supply it via low-level `WebSocketService.subscribe` if needed.

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
