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
