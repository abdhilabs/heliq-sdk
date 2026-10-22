# HeliqSDK

A Swift SDK for Hyperliquid market data, trading, account balances, and WebSocket
subscriptions on iOS and macOS. Uses Swift 6.1 and async/await.

[API documentation](https://abdhilabs.github.io/heliq-sdk/documentation/heliqsdk/) ·
[Sample app](Docs/DEMO_GUIDE.md) ·
[Typed Perps coverage](Docs/PERPS_API_COVERAGE.md) ·
[Changelog](CHANGELOG.md)

- **Market data and accounts:** prices, order books, candles, positions, fills, and mode-aware balances.
- **Trading:** typed orders, cancellations, transfers, leverage, margin, and advanced Perps actions.
- **Live updates:** WebSocket market feeds and account events with configurable reconnection.
- **Raw transport:** Info, Exchange, and WebSocket requests for workflows beyond the convenience APIs.
- **Wallet integration:** application-owned signing through `WalletServiceProtocol`, with a native signer available.

## Requirements

- Swift 6.1 or later; Xcode 16.3 or later.
- iOS 16 or macOS 13 and later for the SDK.
- iOS 16 or later for the sample app.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/abdhilabs/heliq-sdk.git", from: "1.0.0")
]
```

Add its library product to your target's dependencies:

```swift
.product(name: "HeliqSDK", package: "heliq-sdk")
```

In Xcode, choose **File → Add Package Dependencies**, enter
`https://github.com/abdhilabs/heliq-sdk.git`, select version `1.0.0` or later, and add
**HeliqSDK** to your app target. Commit `Package.resolved` in consuming apps to
keep dependency resolution reproducible.

## Quick start

### Read market data

Create an independent client. Read-only queries do not require a wallet:

```swift
import HeliqSDK

let client = try HeliqClient.Builder()
    .environment(.testnet)
    .build()

let mids = try await client.info.getAllMids()
print(mids.prices)

// Supply a real account address for account-specific queries.
let userState = try await client.info.getUserState(address: userAddress)
print(userState.assetPositions)
```

Use `.mainnet` for production or `.testnet` for testing. Each client retains its
own environment and wallet configuration.

### Place an order

Supply your application's `myWalletService`, which conforms to
`WalletServiceProtocol`, or use `WalletService(keyManager:)`. The wallet must
implement `signL1` and `signUserSigned` for the actions you submit. For optional
local custody, see [Keychain wallet storage and its security limitations](Sources/HeliqSDK/HeliqSDK.docc/LocalWalletStorage.md).
Applications still choose their wallet provider and recovery policy.

```swift
let tradingClient = try HeliqClient.Builder()
    .environment(.testnet)
    .wallet(myWalletService)
    .build()

let order = OrderRequest(
    asset: 0,
    side: .buy,
    orderType: .limit,
    size: 0.001,
    price: 50000.0
)

let response = try await tradingClient.exchange.placeOrder(order)
print(response.status)
```

Signed exchange calls fail if the client has no wallet. Resolve asset IDs and
precision from metadata for your selected market; the values above are examples.
See [Balances and typed Perps APIs](#balances-and-typed-perps-apis) for
metadata-based coin selection and Decimal order parameters.

### Subscribe to live data

Retain the service and subscribe when its state becomes `.connected`:

```swift
import Foundation

let ws = WebSocketService(url: URL(string: Constants.WebSocket.testnetURL)!)
await ws.setEventHandler { event in
    switch event {
    case .stateChanged(.connected):
        Task {
            do {
                try await ws.subscribe(HyperliquidWebSocketSubscription(type: .allMids))
            } catch {
                print("Subscription failed: \(error)")
            }
        }
    case .message(let data):
        print(String(decoding: data, as: UTF8.self))
    default:
        break
    }
}
await ws.connect()

// When the feature stops consuming updates:
// await ws.disconnect()
```

`WebSocketService` is an actor. Use `await` for its operations and explicitly hop
to `MainActor` before updating UI from its event handler. The connection handler
above also subscribes again after a successful reconnect.

## Documentation and sample app

| Resource | Use it for |
|---|---|
| [Published documentation](https://abdhilabs.github.io/heliq-sdk/documentation/heliqsdk/) | SDK guides and API reference |
| [Documentation index](Docs/README.md) | Local guides and DocC sources |
| [Sample app guide](Docs/DEMO_GUIDE.md) | Overview, Perpetuals, API Explorer, and Settings workflows |
| [Testnet wallet setup](Docs/TESTNET_WALLET.md) | Configuring the sample's testnet wallet |
| [Typed Perps coverage](Docs/PERPS_API_COVERAGE.md) | Supported queries, actions, and protocol behavior |

To generate the Xcode project for the SDK and sample app, install
[XcodeGen](https://github.com/yonaskolb/XcodeGen), then run:

```bash
xcodegen generate --spec project.yml
open HeliqSDK.xcodeproj
```

Select the **HeliqSDKDemo** scheme and an iOS simulator to run the sample.

## Balances and typed Perps APIs

The following examples use `client` for reads and the wallet-backed `tradingClient`
for signed actions. Supply the account `address` you want to query.

```swift
let balances = try await client.info.getBalances(address: address)
let capacity = try await client.info.getActiveAssetData(address: address, coin: "BTC")
let metadata = try await client.info.perps(.meta(dex: "xyz"))

if balances.abstraction.supportsClassTransfer {
  _ = try await tradingClient.exchange.usdClassTransfer(amount: Decimal(1), toPerp: true)
}

let result = try await tradingClient.exchange.executePerps(.orders([
  .init(market: .coin("BTC"), side: .buy, size: Decimal(string: "0.001")!,
    price: Decimal(50000), kind: .limit(.alo))
]))
```

`getBalances(address:)` reads global Spot balances and validator Perps. Use
`getBalances(address:dexes:)` for explicit HIP-3 DEXs. Shared collateral is counted
only in Spot; missing or inapplicable availability values stay optional. Unheld,
available-after-maintenance, withdrawable, and coin-specific trading capacity are
separate values. The SDK does not derive withdrawal capacity from account value.

New typed APIs use Decimal, metadata-based market IDs/precision, and exact integer
transport. They include TP/SL grouping, batch modification/cancellation, isolated
margin, market closes, TWAP, trailing stops, agent/subaccount operations, immutable
multisig preparation/signing/recovery, and current HIP-3 deployment actions.
Existing APIs remain available; new custom-repository requirements default to explicit
unsupported errors. Wallet adapters can implement contextual `signL1Payload` for
vaults, expiry, and multisig arrays.

The demo's **Perpetuals** workspace selects markets from metadata and provides
trading and position controls. **Overview** displays mode-aware balances.
Administrative/deployment APIs are demonstrated through SDK tests rather than UI forms.

See [typed Perps coverage](Docs/PERPS_API_COVERAGE.md)
and [Perps and balances documentation](Sources/HeliqSDK/HeliqSDK.docc/PerpsAndBalances.md).

## Hyperliquid API Coverage

Protocol references:

- [Info endpoint](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint)
- [Exchange endpoint](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint)
- [WebSocket subscriptions](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions)

### Full-surface raw transport (`POST /info`, `POST /exchange`, WebSocket)

Use raw transport for requests beyond the typed convenience repositories. Supply
request/action fields in `parameters`; responses decode as `JSONValue`, preserving
fields that are not represented in SDK models.

These examples use `client` from Quick start and a connected `WebSocketService`
named `ws`. Supply your own action fields, nonce, signature, and expiry for raw
exchange requests.

```swift
// Any documented Info request type, including openOrders, portfolio, staking,
// vault, HIP-3, and borrow/lend requests.
let result = try await client.raw.info(.init(
    type: .openOrders,
    parameters: ["user": .string("0x...")]
))

// Raw Exchange actions accept signatures from the native signer or an external wallet.
let action = HyperliquidExchangeAction(type: .twapOrder, parameters: [
    "twap": .object([/* official action fields */])
])
let response = try await client.raw.exchange(.init(
    action: action, nonce: nonce, signature: signature, expiresAfter: expiry
))

// Any documented WebSocket feed, preserving user, coin, dex, and optional fields.
let subscription = HyperliquidWebSocketSubscription(
    type: .openOrders,
    parameters: ["user": .string("0x..."), "dex": .string("xyz")]
)
try await ws.subscribe(subscription)
```

### Info API (`POST /info`) — typed convenience methods

| SDK method | Request `type` |
|---|---|
| `getUserState` | `clearinghouseState` |
| `getSpotUserState` | `spotClearinghouseState` |
| `getAllMids` | `allMids` |
| `getAssetCtxs` | `metaAndAssetCtxs` |
| `getSpotAssetCtxs` | `spotMetaAndAssetCtxs` |
| `getCandleSnapshot` | `candleSnapshot` |
| `getL2Book` | `l2Book` |
| `queryOrderByOid` | `orderStatus` |
| `queryOrderByCloid` | `orderStatus` |
| `queryFills` | `userFills` |
| `queryUserFundings` | `userFunding` |
| `getMeta` | `meta` |
| `getSpotMeta` | `spotMeta` |
| `getTime` | `l2Book` (BTC snapshot timestamp) |
| `fetchBuilderFee` | `maxBuilderFee` |

### Info API — raw transport coverage

All official Info request types are available through `HyperliquidInfoType` and `.custom(String)`. This includes open orders, frontend orders, fills/time-range queries, rate limits, order status, historical/TWAP data, subaccounts, staking/delegation, portfolio/fees/referral, metadata/context variants, vault data, HIP-3, builder approvals, and borrow/lend state.

### Exchange API (`POST /exchange`) — typed convenience methods

| SDK method | Action `type` |
|---|---|
| `placeOrder` | `order` |
| `bulkOrders` | `order` |
| `cancelOrder` | `cancel` |
| `cancelByCloid` | `cancelByCloid` |
| `cancelAll` | `openOrders` query then `cancel` |
| `modifyOrder` | `batchModify` |
| `modifyByCloid` | `batchModify` |
| `setLeverage` | `updateLeverage` |
| `setMarginMode` | `updateLeverage` |
| `transfer` | `usdSend` or `spotSend` |
| `sendToAddress` | `usdSend` or `spotSend` |
| `spotTransfer` | `spotSend` |
| `vaultTransfer` | `vaultTransfer` |
| `updateBuilder(builderAddress:maxFeeRate:)` | `approveBuilderFee` |
| `scheduleCancel` | `scheduleCancel` |
| `setReferrer` | `setReferrer` |
| `convertToMultiSigUser(authorizedUsers:threshold:)` | `convertToMultiSigUser` |
| `usdSend` | `usdSend` |

Typed actions call the wallet's `signL1` or `signUserSigned` implementation and send
`{action, nonce, signature}`. `WalletService(keyManager:)` implements both with the
native signer. Legacy wallets implementing only `sign(message:)` must add these
protocol methods; they now fail explicitly instead of submitting unsigned requests.

Market orders are IOC limit orders using current mids, 5% slippage, and official
price rounding; supply `OrderRequest.price` to set an explicit bound. Modification
queries the existing open order and preserves its side, reduce-only flag, trigger,
and time in force in the submitted request. Hyperliquid can override a non-executable
Gtc modification to Alo. Client-ID modifications resolve the current open order
when historical lookup still returns its canceled predecessor.
Leverage/margin changes preserve the other setting.

For transfers, `asset: 0` means perpetual USDC; other values are spot token indices.
`spotTransfer` always uses a `spotMeta.tokens` index (including 0 for spot USDC),
not an order market index. `transfer.fromAddress` must equal the signing wallet.
Unified accounts and portfolio-margin accounts use `sendAsset` for these transfers;
standard accounts retain the legacy `usdSend` and `spotSend` actions.
Vault amounts are USDC units and are encoded as integer micro-USDC. Referrers are
referral codes. Builder approval requires an explicit fee percentage; multisig
conversion requires explicit signer addresses and threshold. The old parameterless
forms throw a validation error rather than inventing account permissions.

Order/cancel responses preserve per-item failures; single-order submissions throw
on rejection. Check every bulk response and cancellation result before reporting
success. Exchange mutations are never automatically retried.

### Exchange API — raw transport coverage

All official signed Exchange actions are available through `HyperliquidExchangeActionType` and `.custom(String)`, including withdrawals, spot sends, USDC-class transfers, leverage/margin updates, batch modifications, TWAP, agent/builder approvals, vault/sub-account actions, delegation, Core deposits/withdrawals, multi-sig, and request-weight reservation.

> **Signing:** `Signer` supports recursive canonical-MessagePack L1 `Agent` signatures and caller-schema user-signed EIP-712 envelopes. Official golden vectors cover L1 dummy on mainnet/testnet, nested L1 orders, USD transfer, and bridge withdrawal. Further user-signed schemas remain caller-supplied until upstream fixtures exist. `HyperliquidExchangeEnvelope` accepts caller-provided `SignatureTypes` for hardware wallets, contract wallets, and externally managed keys; the SDK never serializes or transmits a private key.

### WebSocket — typed convenience channels

`allMids`, `l2Book`, `trades`, `userEvents`, `userFills`, `candle`, `orderUpdates`, `userFundings`, `userNonFundingLedgerUpdates`, `webData2`, `bbo`, `activeAssetCtx`, `activeAssetData`

### WebSocket — raw transport coverage

All official subscriptions, including `notification`, `webData3`, `twapStates`, `clearinghouseState`, `openOrders`, user TWAP feeds, `spotState`, all-DEX state/context, outcome metadata, and compressed `fastAssetCtxs`, are available through `HyperliquidWebSocketSubscription`. `FastAssetCtxDecoder` decodes the documented raw-DEFLATE payload into typed sparse asset-context updates. User-scoped fields are carried explicitly in `parameters`.

## Typed user data

The `client.info` user-state, spot-balance, fill, funding, and order-query methods use
Hyperliquid's official Info endpoints. Order queries accept an explicit `address`:

```swift
let orders = try await client.info.queryOrderByOid(orderId: "123", address: userAddress)
```

Calls without an address use the client's configured wallet and throw
`ValidationError.missingRequiredField(field: "address")` when no wallet exists.
Unknown orders return an empty array.

`UserState.marginMode` and `leverage` are optional summaries of matching position
settings; they are nil for empty or mixed portfolios. Each `AssetPosition` exposes
its own settings. `entryPrice` is optional, and `realizedPnl` is nil for
clearinghouse responses because that endpoint does not supply realized PnL.
Consumers upgrading from the previous model must unwrap these optional values.
Custom `InfoRepository` implementations must implement the explicit-address order
query overloads.

Metadata methods map official market definitions to SDK asset IDs. Perpetual
`MetaAsset.weiDecimals` is nil because perpetual metadata has no token precision;
spot precision comes from each market's base token. `BuilderFee.feeBps` is now a
`Double` to preserve the API's 0.1-bps increments. Builder-fee queries accept an
explicit `address` or use the configured wallet, just like order queries.

## Diagnostics logging

Logging uses Apple OSLog and is disabled by default. Set a level on the builder:

```swift
let diagnosticClient = try HeliqClient.Builder()
    .environment(.testnet)
    .logging(.verbose)
    .build()
```

| Level | Output |
|---|---|
| `.disabled` | No logs (default) |
| `.debug` | Errors and recoverable warnings, including retries and rate limits |
| `.verbose` | Debug output plus lifecycle and timing traces |
| `[.error, .info]` | A custom combination of levels |

Logging configuration is shared: the most recently built client sets the active
level. At `.verbose`, non-2xx response bodies are logged up to 16 KB with a
truncation marker. Request bodies and successful response bodies are never logged.

## Architecture

`HeliqClient` exposes typed `info` and `exchange` repositories plus `raw` transport.
Use cases orchestrate repository operations; repository implementations use
`APIClient` for URLSession HTTP requests. WebSocket transport lives in
`WebSocketService`.

See the [architecture guide](Sources/HeliqSDK/HeliqSDK.docc/Architecture.md)
for dependency injection, signing, and network boundaries.

## Development and testing

Run SDK unit tests without live exchange calls:

```bash
swift test --configuration release --no-parallel --filter HeliqSDKTests
```

Generate the Xcode project with `xcodegen generate --spec project.yml` before
running simulator suites. Replace `iPhone Air` with a simulator installed in your
Xcode version:

```bash
# SDK unit tests
xcodebuild test -project HeliqSDK.xcodeproj -scheme HeliqSDK \
  -destination 'platform=iOS Simulator,name=iPhone Air'

# Live testnet integration tests (configure the test wallet first)
xcodebuild test -project HeliqSDK.xcodeproj -scheme HeliqSDKIntegrationTests \
  -destination 'platform=iOS Simulator,name=iPhone Air'

# Demo app and UI tests
xcodebuild test -project HeliqSDK.xcodeproj -scheme HeliqSDKDemo \
  -destination 'platform=iOS Simulator,name=iPhone Air'
```

| Suite | Target | Coverage |
|---|---|---|
| Unit | `HeliqSDKTests` | Models, repositories with mocks, use cases, networking, and protocol fixtures |
| Integration | `HeliqSDKIntegrationTests` | Live testnet Info, Exchange, and WebSocket calls |
| Demo | `HeliqSDKDemoTests` / `HeliqSDKDemoUITests` | Sample app behavior and navigation |

### GitHub Actions

- **CI:** lints workflows, runs SDK unit tests with coverage, and builds iOS SDK/demo test bundles. It does not run funded or live integration tests.
- **Documentation:** audits public-symbol documentation, builds DocC, and deploys GitHub Pages from `master`. Pull requests validate without deploying.
- **Release:** validates version tags (`v*`) before creating a draft release.

SDK tests and documentation use `macos-15` with Xcode 16.4. iOS/demo builds use
`macos-26` with Xcode 26.6 to avoid a Swift 6.1 compiler crash in LightweightCharts.
Linting, the documentation audit, and deployment use `ubuntu-latest`.

The repository's **Settings → Pages → Build and deployment → Source** must be
**GitHub Actions**. The published site root redirects to
`/heliq-sdk/documentation/heliqsdk/`, the DocC module page.

Workflow path filters skip unaffected builds. If you configure required status
checks, account for skipped workflows, which can leave those checks pending.

## License

Licensed under the [MIT License](LICENSE).
