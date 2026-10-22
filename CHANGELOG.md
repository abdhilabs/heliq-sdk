# Changelog

## 1.0.0 — 2026-10-22

First public release of HeliqSDK.

- Independent `HeliqClient` instances for mainnet, testnet, and local environments.
- Async market-data and account queries, including metadata, order books, candles,
  positions, orders, fills, funding, and mode-aware balances.
- Typed Perps queries and actions with Decimal inputs, metadata-based market
  resolution, TP/SL orders, TWAP, margin controls, and multisig workflows.
- Application-owned wallet signing, native L1 and EIP-712 signing, and explicit
  error handling without automatic retries of exchange mutations.
- Raw Info and Exchange transport and WebSocket subscriptions, messages,
  reconnection, and unsubscribe support.
- OSLog diagnostics, an iOS 16-compatible sample app, and published DocC documentation.
- Fixed a sample-app navigation crash by preserving the API Explorer navigation
  stack while resetting its connection-dependent content.
- Fixed the documentation homepage redirect and updated examples to use
  `HeliqClient`.
- Fixed `getTime()` to use the exchange timestamp in a BTC order-book snapshot;
  Hyperliquid does not provide a `getTime` Info request.

### Requirements

Swift 6.1+, iOS 16+, or macOS 13+. The sample app also supports iOS 16+.

### Coverage boundaries

Typed APIs cover the workflows listed in [the API coverage guide](Docs/PERPS_API_COVERAGE.md).
Raw transport preserves caller-provided fields; it does not validate every upstream
request or make unsupported server actions available. Some administrative actions
require account eligibility or permissions. Testnet validation does not establish
mainnet execution or hardware-wallet compatibility.
