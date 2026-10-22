# Trading-first sample app

The sample uses four native tabs, each with an independent navigation stack.

- **Overview:** connected environment, wallet, mode-aware balances, and shortcuts
  to trade, transfer USDC, and inspect wallet details.
- **Perpetuals:** searchable venue/market selection, current mark price and funding,
  a decimal order ticket, positions, and open orders on the selected DEX.
- **API Explorer:** existing Info, Exchange, WebSocket, and wallet-signing examples.
  SDK responses remain available; detailed JSON and stream payloads are expandable.
- **Settings:** select an environment, initialize its SDK, inspect connection and
  signing-wallet type, or disconnect before applying another environment.

## Connect and inspect

The app starts disconnected. Open Settings, choose an environment, and initialize.
Testnet uses the existing private saved wallet. Mainnet and Local retain their
read-only mock wallet behavior. Disconnecting does not delete the saved wallet.
No account abstraction mode is changed by browsing the app.

Overview separates total, held, unheld, available-after-maintenance, and withdrawable
values. Missing server values read **Unavailable**. Shared accounts display Spot
collateral once; their Perps rows do not add another collateral balance. Unheld
funds do not imply withdrawal or trading capacity.

## Perpetual workspace

Tap the market header to search coins or narrow the DEX selector. **Trade** shows
Limit/Market orders and coin-specific capacity. **Positions** exposes each position's
close, protection, isolated-margin, and leverage actions. **Open Orders** cancels
individual actual order IDs or orders in the selected market.

Advanced orders, TWAP cancellation, leverage/margin settings, and transfers use
focused sheets. Transfers between Spot and validator Perps are enabled only for
resolved standard accounts. Shared accounts explain why no class transfer is needed.
Market prices are USD; available-to-trade amounts are collateral capacity, and
maximum trade sizes are labeled with the selected coin.

Data refreshes on entry, market changes, pull-to-refresh, and successful mutations.
There is no polling and no automatic mutation retry. Loading/errors/results appear
in the workspace or action form; successful and rejected batch items remain visible.
Newer reads supersede older reads when a selection or connection changes.

## Compatibility and verification

The SDK minimum stays iOS 16/macOS 13. The sample retains its existing iOS 17
minimum because it already uses Observation. The interface supports system light
and dark appearance, Dynamic Type, VoiceOver labels, native controls, and keyboard
dismissal. No wallet import flow or mainnet signing wallet was added.

`TradingWorkspaceUITests` uses explicit `-ui-testing -demo-scenario <state>` launch
arguments for synthetic populated, empty, missing, standard, loading, error, and
partial-result states. These scenarios bypass exchange submission and label their
data as synthetic. Normal launches do not enable them. Live read-only UI checks
require `HELIQ_DEMO_READ_TESTS=1` and the controlled saved testnet wallet; funded
trading tests remain separate opt-in tests.

## Validation recorded on 2026-10-15

- All 426 SDK unit tests passed; SDK source and public interfaces are unchanged.
- The demo built for iOS 26.5 and iOS 18.5 simulators with the existing deployment
  minimum. The final build includes the bounded raw-response panel and larger input targets.
- All 11 workspace scenarios passed across targeted simulator runs: navigation,
  populated/empty/missing balances, loading/errors, partial outcomes, decimal
  validation, market search, advanced-order fields, transfer compatibility,
  adaptive layout, and live read-only testnet data.
- Existing metadata/builder-fee and user-data/order-query checks passed. Wallet
  persistence passed through disconnect, reconnect, and relaunch. All four launch
  appearance/orientation configurations passed; existing feature navigation,
  market-data, and candle checks also passed during the regression pass.
- Compact-device screenshots were inspected in light/dark appearance and large
  accessibility text, with portrait and landscape layout checks. Inputs have a
  minimum 44-point touch area; accessibility-sized workspace selection uses a menu.

Initial UI failures exposed unbounded raw JSON, ambiguous selectors, and test
scrolling/orientation assumptions. These were corrected and the affected checks
rerun. Some attempts stalled in diagnostic collection or lost the XCTest runner;
verification therefore used multiple targeted runs rather than one clean full-suite
run. Verbose sysdiagnose collection was disabled on retries; assertions, logs, and
screenshots remained enabled.

Local evidence:

- `/private/tmp/heliq-demo-redesign-sdk-tests.log`
- `/private/tmp/heliq-demo-polish-build.log`
- `/private/tmp/heliq-transfer-acceptance.xcresult`
- `/private/tmp/heliq-demo-final-acceptance.log`
- `/private/tmp/heliq-demo-clean-acceptance.log`
- `/private/tmp/heliq-demo-last-check.xcresult`
- `/private/tmp/heliq-demo-visual-final.xcresult`

No mainnet mutations, funded testnet orders/transfers, account-setting changes,
or physical-device checks were performed. Existing upstream package warnings remain.
The controlled test wallet was used only for reads and its temporary simulator copy
was removed after verification.

## Live candlestick charts

The Perpetuals **Trade** workspace includes a price/volume chart for its selected
market. The same chart is available at **API Explorer → WebSocket → Live candle
chart**, with its own metadata-driven market picker. Choose 1m, 15m, 1h, or 1d;
changing the chart interval preserves the order ticket's inputs.

The demo pins TradingView's official `LightweightChartsIOS` **5.2.0** using the
`LightweightCharts` product in `project.yml`. Only the demo links it; the SDK's
Swift package has no chart dependency. Run `xcodegen generate` after changing
project configuration. JavaScript chart assets are bundled by Swift Package
Manager; the chart does not fetch a script from a CDN or use TradingView prices.

`CandleChartModel` registers a typed candle handler and subscribes through the SDK
before querying `PerpsQuery.candles`. Incoming bars are buffered during the HTTP
snapshot. `CandleBuffer` merges by opening timestamp, lets live values override
snapshot values, sorts and deduplicates, loads up to 300 historical bars, and
retains at most 500. Decimals stay exact until rendering; millisecond timestamps
become UTC seconds at the renderer boundary. Invalid OHLCV values are ignored.

Each visible chart owns a socket using the existing SDK transport, router, and
subscription manager. Market/interval/connection changes replace that session;
leaving the chart cancels reads, removes the handler, unsubscribes, and disconnects.
Transport reconnection re-subscribes and backfills history while retaining the
visible chart. No background polling or exchange submission is involved.

Connection status, last stream update time, bar/update counts, and an accessible
OHLCV summary distinguish history from real-time updates. Nearby errors and the
reload button support manual recovery. Synthetic UI scenarios remain explicitly
labeled and never contact an exchange. Charts are read-only and need no funding.

TradingView attribution is visible on the chart and linked below it. The full
Apache 2.0 license is bundled as `TradingView-LICENSE.txt` and available in the
chart's open-source license disclosure. TradingView Lightweight Charts™:
Copyright © 2026 TradingView, Inc. See the [official project](https://github.com/tradingview/LightweightChartsIOS)
and [license requirements](https://tradingview.github.io/lightweight-charts/docs/5.0).

### Chart validation recorded on 2026-10-17

- Demo builds succeeded with iOS 17 minimum; the built SDK framework retains iOS
  16. macOS SPM compilation and all 426 SDK tests passed with `--no-parallel`.
  The initial parallel run exposed two shared-logger test races; SDK code was not changed.
- All seven chart unit tests passed: snapshot/live precedence, duplicate updates,
  out-of-order bars, reconnect backfill, retention, filtering, stale-session
  cancellation, and a synthetic live price change.
- Real testnet verification on iOS 26.5 loaded historical BTC candles and then
  received a public WebSocket update (301 retained bars in the captured check).
  No trades, transfers, or account changes were submitted.
- Compact iPhone SE (3rd generation), iOS 18.6 fixture checks passed for both chart
  entry points, market/interval selection, tab/back navigation, loading/empty/error
  states, and manual retry. Screenshots were inspected in light/dark appearance,
  large text, and landscape. The chart uses a shorter landscape canvas and
  vertically stacked status labels at accessibility sizes.
- The temporary compact simulator was removed after verification. The final app
  was installed on the original simulator, preserving its saved wallet.
- The six-case compact UI regression batch passed, including the existing order-ticket
  validation/market search and standard/shared-account transfer controls.
- Initial checks found and corrected a renderer-ready state reset on tab return
  and UI-test scrolling/tapping of partially obscured controls. Affected checks
  were rebuilt and rerun; earlier failed results remain in local evidence.
- iOS 18.5 simulator launch was blocked by the documented
  [WebKit runtime loader issue](https://developer.apple.com/forums/thread/785964).
  Validation used iOS 18.6 instead, with no system-library patches or raised
  deployment targets. Existing SwiftUI/XCTest diagnostics and the build's
  AppIntents metadata-extraction warning remain; no new chart-source warnings remain.

Evidence: `/private/tmp/heliq-chart-sdk-tests-serial.log`,
`/private/tmp/heliq-chart-build-complete.log`,
`/private/tmp/heliq-chart-selection-final.xcresult`,
`/private/tmp/heliq-chart-ui-complete.xcresult`,
`/private/tmp/heliq-chart-live-final.xcresult`,
`/private/tmp/heliq-chart-dark-final.xcresult`, and
`/private/tmp/heliq-chart-light-final.xcresult`.

Physical devices and forced live-network reconnection were not checked. Reconnect
buffer behavior and the existing transport lifecycle are covered by automated
fixtures. Indicators, drawing tools, and order overlays remain outside this example.

### Mainnet chart verification on 2026-10-17

The opt-in `testLiveMainnetCandles` UI test passed on the iPhone Air iOS 26.5
simulator. It explicitly initialized Mainnet with the existing read-only mock
wallet, rendered BTC history (at least 250 bars), received real WebSocket updates,
switched the standalone chart from 1m to 15m, and verified live candles again in
the Perpetuals workspace. Both chart entry points reported no chart error.
Screenshots were captured for all three contexts. No mainnet orders, transfers,
or account-setting mutations were submitted.

Evidence: `/private/tmp/heliq-chart-mainnet-build.log`,
`/private/tmp/heliq-chart-mainnet.xcresult`, and
`/private/tmp/heliq-chart-mainnet-screens/`.
