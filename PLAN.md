# HeliqSDK - Project Plan

## 1. Overview

| Item | Details |
|------|---------|
| **Project Name** | HeliqSDK |
| **Type** | Swift SDK for Hyperliquid DEX |
| **Languages** | Swift 6.0 |
| **Xcode Version** | Xcode 16.0+ (required for Swift 6.0) |
| **Platforms** | iOS 16.0+, macOS 13.0+ (Catalyst) |
| **Architecture** | Clean Architecture + Moya-style networking |
| **Environments** | MAINNET, TESTNET, LOCAL |

---

## 2. Project Structure

```
HeliiqSDK/
├── Sources/HeliiqSDK/
│   ├── App/
│   │   ├── HeliqSDK.swift             # Main entry point (shared, builder)
│   │   └── DIContainer.swift          # DI container
│   ├── Core/
│   │   ├── Constants.swift             # API URLs (MAINNET, TESTNET, LOCAL)
│   │   ├── Error/
│   │   │   ├── HeliqError.swift         # Main error enum (Network, API, Signing, Validation)
│   │   │   ├── NetworkError.swift       # Connectivity, timeouts
│   │   │   ├── APIError.swift          # Rate limits, server errors
│   │   │   ├── SigningError.swift      # Invalid key, signature failures
│   │   │   └── ValidationError.swift   # Malformed data
│   │   ├── Encoding/
│   │   │   ├── MessagePackCoder.swift # JSON stub (MsgPack placeholder)
│   │   │   └── JSONCoder.swift        # JSON encoding/decoding
│   │   ├── Network/
│   │   │   ├── RetryPolicy.swift      # 3 retries, exponential backoff
│   │   │   ├── APIResponse.swift      # Unified response wrapper
│   │   │   ├── APIRouter.swift        # Moya-style endpoints
│   │   │   ├── APIClient.swift         # URLSession HTTP client
│   │   │   ├── NetworkInterceptor.swift
│   │   │   └── RateLimitHandler.swift # Token bucket (actor-based)
│   │   └── Extensions/
│   │       ├── Data+Extensions.swift
│   │       ├── String+Extensions.swift
│   │       └── Logger.swift             # OSLog-based structured logging
│   ├── Data/
│   │   ├── Network/
│   │   │   ├── WebSocketService.swift     # Starscream WebSocket wrapper
│   │   │   ├── WebSocketMessageParser.swift
│   │   │   ├── WebSocketMessageRouter.swift
│   │   │   ├── WebSocketDataParser.swift  # Parses WS data to domain entities
│   │   │   ├── WebSocketReconnectionHandler.swift
│   │   │   ├── WebSocketHealthMonitor.swift
│   │   │   ├── SubscriptionManager.swift
│   │   │   └── Plugins/
│   │   │       └── LoggingPlugin.swift
│   │   ├── Repositories/
│   │   │   ├── InfoRepositoryImpl.swift    # Info API implementation
│   │   │   └── ExchangeRepositoryImpl.swift # Exchange API implementation
│   │   └── Cache/
│   │       └── AssetMetaCache.swift       # Actor-based coin↔asset mapping
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── Asset/
│   │   │   │   ├── AssetContext.swift
│   │   │   │   ├── AssetInfo.swift
│   │   │   │   └── CoinAssetMapping.swift
│   │   │   ├── Order/
│   │   │   │   ├── OrderRequest.swift
│   │   │   │   ├── OrderType.swift (OrderSide, OrderType, TriggerParams, TriggerOrderType)
│   │   │   │   ├── Fill.swift
│   │   │   │   └── Cloid.swift
│   │   │   ├── User/
│   │   │   │   ├── UserState.swift (with AssetPosition, MarginMode)
│   │   │   │   └── AgentAbstraction.swift
│   │   │   ├── Market/
│   │   │   │   ├── L2Book.swift (with L2Level)
│   │   │   │   ├── AllMids.swift
│   │   │   │   └── Candle.swift
│   │   │   ├── Signing/
│   │   │   │   ├── SignatureTypes.swift
│   │   │   │   └── SignedMessage.swift
│   │   │   ├── MultiSig/
│   │   │   │   └── MultiSigEnvelope.swift
│   │   │   ├── Vault/
│   │   │   │   └── VaultTransfer.swift
│   │   │   ├── Spot/
│   │   │   │   ├── SpotOrder.swift
│   │   │   │   └── SpotAssetContext.swift
│   │   │   └── Meta/
│   │   │       ├── Meta.swift (with MetaAsset, SpotAssetConfig, TokenConfig)
│   │   │       └── BuilderInfo.swift
│   │   ├── Repositories/
│   │   │   ├── InfoRepository.swift    # Protocol + SpotUserState, Order, UserFunding, BuilderFee
│   │   │   └── ExchangeRepository.swift # Protocol + all response types
│   │   └── UseCases/
│   │       ├── Info/
│   │       │   ├── GetUserStateUseCase.swift
│   │       │   ├── GetSpotUserStateUseCase.swift
│   │       │   ├── GetAllMidsUseCase.swift
│   │       │   ├── GetAssetCtxsUseCase.swift
│   │       │   ├── GetSpotAssetCtxsUseCase.swift
│   │       │   ├── GetCandleSnapshotUseCase.swift
│   │       │   ├── GetL2BookUseCase.swift
│   │       │   ├── QueryOrderByOidUseCase.swift
│   │       │   ├── QueryOrderByCloidUseCase.swift
│   │       │   ├── QueryFillsUseCase.swift
│   │       │   ├── QueryUserFundingsUseCase.swift
│   │       │   ├── GetMetaUseCase.swift
│   │       │   ├── GetSpotMetaUseCase.swift
│   │       │   ├── GetTimeUseCase.swift
│   │       │   └── FetchBuilderFeeUseCase.swift
│   │       └── Exchange/
│   │           ├── PlaceOrderUseCase.swift
│   │           ├── BulkOrdersUseCase.swift
│   │           ├── CancelOrderUseCase.swift
│   │           ├── CancelByCloidUseCase.swift
│   │           ├── CancelAllUseCase.swift
│   │           ├── ModifyOrderUseCase.swift
│   │           ├── ModifyByCloidUseCase.swift
│   │           ├── SetLeverageUseCase.swift
│   │           ├── SetMarginModeUseCase.swift
│   │           ├── TransferUseCase.swift
│   │           ├── SendToAddressUseCase.swift
│   │           ├── SpotTransferUseCase.swift
│   │           ├── VaultTransferUseCase.swift
│   │           ├── UpdateBuilderUseCase.swift
│   │           ├── ScheduleCancelUseCase.swift
│   │           ├── SetReferrerUseCase.swift
│   │           ├── ConvertToMultiSigUseCase.swift
│   │           └── UsdSendUseCase.swift
│   └── Services/
│       ├── Signer.swift               # EIP-712 signing (stub for web3swift)
│       ├── WalletService.swift        # Wallet management
│       ├── KeyManager.swift           # Key management (raw key, Keychain, agent)
│       └── TransactionBuilder.swift   # Build unsigned transactions
├── Tests/HeliqSDKTests/
│   ├── Entities/
│   │   ├── ConstantsTests.swift
│   │   └── OrderTypeTests.swift
│   ├── Network/
│   │   └── APIRouterTests.swift
│   ├── Mocking/
│   │   └── MockAPIClient.swift
│   └── Signing/
│       └── SigningTests.swift
├── Examples/HeliqSDKDemo/
│   ├── App/
│   │   └── HeliqSDKDemoApp.swift
│   ├── Features/
│   │   ├── Info/InfoView.swift
│   │   ├── Trading/TradingView.swift
│   │   ├── WebSocket/WebSocketView.swift
│   │   ├── Wallet/WalletView.swift
│   │   └── Settings/SettingsView.swift
│   └── Resources/
│       └── Assets.xcassets/
├── .github/workflows/
│   ├── ci.yml            # Build + Test
│   ├── coverage.yml      # Code coverage
│   └── release.yml       # GitHub Release
├── project.yml            # XcodeGen configuration
├── Package.swift          # SPM dependencies
├── .gitignore
└── README.md
```

---

## 3. Dependencies (SPM)

| Package | Version | Purpose |
|---------|---------|---------|
| `web3swift` | latest | EIP-712 signing (wrapped by Signer.swift) |
| `Starscream` | latest | WebSocket client |
| `MessagePack` | self-contained | Self-implemented MsgPack encoder/decoder for WebSocket (external package had issues) |

---

## 4. Hyperliquid API Parity Tracker

> **Last reconciled:** 2026-07-27 against the official Hyperliquid Info, Exchange, WebSocket subscriptions, and WebSocket post-request documentation.
>
> **Definition of parity:** Every official request/action/subscription is representable through a lossless raw transport. The original repository/use-case methods remain a typed convenience subset.

| Surface | Status | Implementation | Verification |
|---------|--------|----------------|--------------|
| `POST /info` | ✅ Full transport parity | `HyperliquidInfoType`, `HyperliquidInfoRequest`, `HeliqSDK.shared.raw.info` | Official registry tests + live testnet raw request |
| `POST /exchange` | ✅ Full transport parity | `HyperliquidExchangeActionType`, action/envelope transport | Unit encoding tests; requires caller-provided EIP-712 signature |
| WebSocket subscriptions | ✅ Full transport parity | `HyperliquidWebSocketSubscription`, exact subscribe/unsubscribe payloads | Official registry + payload-preservation tests |
| WebSocket inbound events | ✅ | Official `channel` / `data` messages route to handlers | Regression test |
| WebSocket HTTP-equivalent posts | ✅ | `HyperliquidWebSocketPostRequest` and `WebSocketService.post` | Envelope encoding tests |
| Typed convenience methods | ⚠️ Core subset | `InfoRepository`, `ExchangeRepository`, use cases | Existing unit/integration tests |

### 4.1 Raw transport usage

Use `HeliqSDK.shared.raw` for every documented Hyperliquid Info or Exchange shape that does not have a typed convenience method. It accepts `JSONValue` parameters and returns `JSONValue`, preserving server fields without lossy model decoding.

### 4.2 Remaining implementation work

| Priority | Item | Status | Tracking boundary |
|----------|------|--------|-------------------|
| P0 | Native L1 and user-signed EIP-712 signing | 🟡 Partial | `Signer.signL1` is golden-tested for official dummy mainnet/testnet and nested L1 order vectors. `Signer.signUserSigned` is golden-tested for USD transfer and bridge withdrawal. Additional user-signed schemas remain caller-supplied until upstream fixtures exist. |
| P0 | Golden signed-action payload fixtures | 🟡 Focused coverage | Official L1 dummy/order, USD-transfer, and bridge-withdraw fixtures lock canonical MessagePack plus both upstream user-signed schemas. Typed Exchange action fixtures remain endpoint-specific future work. |
| P1 | Correct typed Info request/response mappings | ✅ Core corrections | Official payload/DTO coverage now includes nested `candleSnapshot.req`, `userFills`/`userFillsByTime`, `orderStatus` by oid or cloid, open orders, and side-preserving L2 books. |
| P1 | Typed convenience wrappers for remaining official API | ⬜ Demand-driven | Raw transport is complete; current wrappers expose open orders, L2 book, fills, order status, and pagination. Promote additional stable calls without duplicating raw transport. |
| P1 | `fastAssetCtxs` decode helper | ✅ Implemented | `FastAssetCtxDecoder` decodes the documented base64 raw-DEFLATE update into typed sparse fields. |
| P2 | Pagination abstraction | 🟡 Started | `HyperliquidPageRequest` produces inclusive millisecond bounds. Automatic page collection remains endpoint-specific and caller-controlled. |
| P2 | DTO mapping layer | ⬜ Deferred | Introduce endpoint DTOs only where stable public models need insulation from wire evolution. |

### 4.3 Security and correctness boundaries

- Raw Exchange transport never serializes or transmits a private key.
- Native signing accepts a private key only in `Signer`; callers may continue supplying `SignatureTypes` for hardware wallets, contract wallets, or external signing services.
- The generic user-signed API requires the official field schema and primary type explicitly; it refuses to infer schemas.
- Every raw WebSocket unsubscribe carries the original subscription fields, including `user`, `coin`, `interval`, and `dex` when supplied.
- `FastAssetCtxDecoder` supports the official raw-DEFLATE encoding and fails closed for unsupported future encodings.

---

## 5. WebSocket Subscriptions

The raw subscription API supports all official channels: `allMids`, `notification`, `webData3`, `twapStates`, `clearinghouseState`, `openOrders`, `candle`, `l2Book`, `trades`, `orderUpdates`, user event/fill/funding/ledger/TWAP feeds, `bbo`, asset context/data, `spotState`, all-DEX feeds, outcome metadata, and `fastAssetCtxs`.

`SubscriptionChannel` remains the original typed convenience subset. Use `HyperliquidWebSocketSubscription` for user-scoped or newer official channels.

---

## 6. Architecture Details

### 6.1 Clean Architecture Flow

```
┌─────────────────────────────────────────────────────┐
│                    UseCase                          │
│         (Business Logic Orchestration)              │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│              Repository Protocol                   │
│              (Abstraction Layer)                    │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│            Repository Implementation               │
│            (Data Access Logic)                     │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   APIClient                         │
│              (URLSession HTTP)                      │
└─────────────────────────────────────────────────────┘
```

### 6.2 Concurrency Model

- **Native async/await** throughout the SDK
- All UseCases, Repositories, and Network layer use `async/await`
- No completion handler callbacks (pure Swift concurrency)
- **Sendable conformance**: All SDK types (DTOs, Entities, UseCases) conform to `Sendable` for Swift 6 data race safety

### 6.3 Moya-Style APIRouter

```swift
enum HyperliquidAPI {
    case userState(address: String)
    case allMids
    case order(signature: String, payload: OrderRequest)
    // ... etc
}

extension HyperliquidAPI: APIRouterProtocol {
    var path: String { "/info" or "/trade" }
    var method: HTTPMethod { .post }
    var task: HTTPTask { .requestWithBody(...) }
}
```

### 6.4 API Stability Annotations

- `@_spi(HeliqSDK)` for internal APIs used across modules
- `@available(*, unavailable, renamed: "...")` for deprecated APIs
- Beta APIs marked with `// Beta` comment for easy identification
- Public-facing APIs stabilized before v1.0.0 release

### 6.5 SDK Initialization & Access Pattern

**Singleton Pattern with Shared Access:**

```swift
// AppDelegate.swift - Initialize once in app launch
func application(_ application: UIApplication, 
    didFinishLaunchingWithOptions...) -> Bool {
    
    HeliqSDK.shared.initialize { builder in
        builder.environment(.testnet)  // or .mainnet, .local
        builder.wallet(myWalletService)
    }
    
    return true
}

// Anywhere else - global access after init
HeliqSDK.shared.exchange.placeOrder(order)
HeliqSDK.shared.info.getUserState(address: "0x...")
HeliqSDK.shared.webSocket.subscribe(channel: .allMids) { ... }
```

**Builder Pattern for Custom/Testing Instances:**

```swift
// Create custom instance (testing, multi-wallet)
let customSDK = HeliqSDK.builder()
    .environment(.testnet)
    .wallet(anotherWallet)
    .build()

// Read-only SDK (no wallet needed)
let infoOnlySDK = HeliqSDK.builder()
    .environment(.mainnet)
    .build()
```

**Key Design Decisions:**

| Aspect | Decision |
|--------|----------|
| **Access** | `HeliqSDK.shared` singleton |
| **Init** | Sync `initialize { builder in }` closure |
| **Failure** | `fatalError` if not initialized (app can't run anyway) |
| **Multi-instance** | `HeliqSDK.builder().build()` for testing |
| **DI Container** | Internal only, not exposed to users |

---

## 7. Key Components

### 7.1 Rate Limiting

- **Algorithm**: Token bucket
- **Default**: 100 requests per 10 seconds (based on Hyperliquid docs)
- **Per-endpoint**: Different limits for info vs trading endpoints

### 7.2 Retry Policy

- **Max retries**: 3
- **Backoff**: Exponential (1s, 2s, 4s)
- **Retryable errors**: 5xx, network errors, rate limits

### 7.3 Logging

- **Structured logging** with log levels: debug, info, warn, error
- **Categories**: Network, WebSocket, Signing, Cache
- **Output**: OSLog (unified logging) for iOS/macOS native experience
- **Plugin-based**: LoggingPlugin for easy extension/inspection

### 7.4 AssetMetaCache

- **Storage**: In-memory only
- **TTL**: 1 hour (auto-refresh)
- **Data**: coin name ↔ asset ID mapping

### 7.5 WebSocket

- **Encoding**: MsgPack (for Hyperliquid protocol)
- **Heartbeat**: 50-second ping/pong
- **Reconnection**: Automatic with exponential backoff
- **Subscriptions**: Managed via SubscriptionManager

### 7.6 Error Taxonomy

| Category | Types |
|----------|-------|
| **NetworkError** | Connectivity issues, timeouts, DNS failures |
| **APIError** | Rate limits (429), server errors (5xx), invalid requests (4xx) |
| **SigningError** | Invalid private key, signature verification failed, user rejected |
| **ValidationError** | Malformed data, missing required fields, type mismatches |

- All errors conform to `HeliqError` protocol
- `HeliqError` provides `isRetryable` property for automatic retry logic

### 7.7 Key Management Strategy

**Phased Implementation:**

1. **Phase 1 (MVP)**: Raw private key import
   - Direct key import for signing
   - Best for: power users, testing, algorithmic traders

2. **Phase 2**: Keychain storage
   - iOS Keychain / macOS Keychain
   - Uses Secure Enclave when available
   - Best for: most end-users

3. **Phase 3**: Agent abstraction (delegation)
   - Aligns with Hyperliquid's "u" (user), "p" (paper), "i" (info) model
   - Enables gasless/meta-transactions
   - Delegate signing to bot addresses
   - Best for: algorithmic traders, institutional users

4. **Optional (Future)**: WalletConnect integration
   - Non-custodial option for DApp-style integrations

---

## 8. GitHub Actions CI/CD

### 8.1 CI Pipeline (`ci.yml`)

- **Trigger**: Push, Pull Request
- **Matrix**: iOS + macOS
- **Steps**: Build → Test

### 8.2 Coverage (`coverage.yml`)

- **Trigger**: Pull Request
- **Steps**: Run tests with coverage → Upload to Codecov

### 8.3 Release (`release.yml`)

- **Trigger**: Tag `v*`
- **Steps**: Create GitHub Release

### 8.4 Documentation (DocC)

- Swift's native documentation format
- Generated as part of CI build
- Hosted on GitHub Pages (future)

### 8.5 Circuit Breaker

- **Pattern**: Circuit breaker for failing fast when API is degraded
- **States**: Closed (normal) → Open (failing) → Half-open (testing)
- **Thresholds**: 5 consecutive failures opens circuit, 30s timeout before half-open

---

## 8X. Post-MVP Considerations (Future)

| Item | Status |
|------|--------|
| CONTRIBUTING.md | Later |
| License (MIT) | Later |
| API versioning strategy | Later (track Hyperliquid API changes) |
| Breaking changes policy | Later |
| CHANGELOG | Later |
| CocoaPods support | No (SPM only) |
| Telemetry/metrics | Deferred (post-MVP) |

---

## 9. File Count Estimate

| Category | Count |
|----------|-------|
| Core SDK Swift files | ~61-66 |
| Test Swift files | ~20-25 |
| Demo App files | ~12-15 |
| Config files | 3 |
| Workflow files | 3 |
| **Total** | **~89-102 files** |

---

## 10. Platform Targets

| Platform | Min Version |
|----------|-------------|
| iOS | 16.0 |
| macOS | 13.0 (Ventura) |

---

## 11. Implementation Order

1. **Phase 1**: Project setup (project.yml, Package.swift)
2. **Phase 2**: Core layer (Constants, Error taxonomy, Encoding, Extensions)
3. **Phase 3**: Domain layer (Entities, Repository protocols)
4. **Phase 4**: Data layer - Network (APIClient, APIRouter, plugins)
5. **Phase 5**: Data layer - WebSocket (Services, Message handling)
6. **Phase 6**: Data layer - Repositories (Implementations)
7. **Phase 7**: Domain layer - UseCases
8. **Phase 8**: Services (Signer, WalletService, TransactionBuilder)
9. **Phase 9**: Unit Tests
10. **Phase 10**: Demo App (full-featured)
11. **Phase 11**: GitHub Actions workflows
12. **Phase 12**: README.md (includes Integration Guide)

---

## 13. Progress Tracker

| Phase | Status | Completed | Notes |
|-------|--------|-----------|-------|
| Phase 1: Project setup | ✅ Completed | 2026-04-05 | project.yml, Package.swift, folder structure, Info.plist files created. XcodeGen project generated. iOS-only initially (macOS targets deferred) |
| Phase 2: Core layer | ✅ Completed | 2026-04-05 | Constants, Error taxonomy (HeliqError, NetworkError, APIError, SigningError, ValidationError), Encoding (MessagePack stub using JSON, JSON), Network (RetryPolicy, APIResponse), Extensions (Data, String, Logger). Build succeeded after removing external MessagePack package (a2/MessagePack.swift repo not found) |
| Phase 3: Domain layer | ✅ Completed | 2026-04-05 | All entities (Asset, Order, User, Market, Signing, MultiSig, Vault, Spot, Meta) + Repository protocols (InfoRepository, ExchangeRepository) created |
| Phase 4: Data layer - Network | ✅ Completed | 2026-04-05 | APIClient, APIRouter, NetworkInterceptor, RateLimitHandler (actor-based), LoggingPlugin |
| Phase 5: Data layer - WebSocket | ✅ Completed | 2026-04-05 | WebSocketService, SubscriptionManager, WebSocketHealthMonitor, WebSocketMessageParser, WebSocketMessageRouter, WebSocketReconnectionHandler, WebSocketDataParser - all built with Swift 6 concurrency |
| Phase 6: Data layer - Repositories | ✅ Completed | 2026-04-05 | InfoRepositoryImpl fully implemented with InfoAPIRequest, ExchangeRepositoryImpl with ExchangeAPIRequest - all using TransactionBuilder |
| Phase 7: Domain layer - UseCases | ✅ Completed | 2026-04-05 | All Info and Exchange use cases created |
| Phase 8: Services | ✅ Completed | 2026-04-05 | Signer (stub), WalletService, KeyManager, TransactionBuilder fully implemented |
| Phase 9: Unit Tests | ✅ Completed | 2026-04-05 | ConstantsTests, OrderTypeTests, APIRouterTests, MockAPIClient, SigningTests |
| Phase 10: Demo App | ✅ Completed | 2026-04-05 | HeliqSDKDemoApp with Info, Trading, WebSocket, Wallet, Settings views |
| Phase 11: GitHub Actions | ✅ Completed | 2026-04-05 | ci.yml, coverage.yml, release.yml workflows |
| Phase 12: README.md | ✅ Completed | 2026-04-05 | Integration guide with Quick Start, Architecture, Requirements sections |

## 14. Post-Development Status

| Item | Status | Notes |
|------|--------|-------|
| Core typed repositories and use cases | ✅ Done | Stable convenience subset for common Info and Exchange flows |
| Lossless Hyperliquid raw transport | ✅ Done | Official Info, Exchange, WebSocket subscriptions, inbound events, and WS post requests; see §4 |
| Native EIP-712 signer | ❌ Not implemented | Existing `Signer` is a stub; caller supplies `SignatureTypes` for signed raw Exchange actions |
| Signed-action golden fixtures | ❌ Not implemented | Required before native signer can be considered correct |
| Typed advanced API models | ⬜ Optional | Raw `JSONValue` transport is available; add typed models where consumer demand justifies them |
| `fastAssetCtxs` decompression helper | ⬜ Optional | Raw compressed stream is available |
| AssetMetaCache | ✅ Done | Actor-based cache with TTL support |
| DTO mapping layer | ⬜ Deferred | Direct Codable entities remain appropriate until model isolation is needed |
| Swift 6 concurrency | ✅ Done | Async/await and isolated shared state |
| Demo UI tests | ✅ Done | `HeliqSDKDemoUITests` target + scheme |
| Official transport coverage tests | ✅ Done | Registry, payload, inbound-event, and live raw Info testnet coverage |

## 15. Testing Plan

See [TEST_PLAN.md](./TEST_PLAN.md) for full test specifications.

---

**Transport parity is complete. Production-ready native signing and optional typed ergonomics are tracked in §4.2.**
