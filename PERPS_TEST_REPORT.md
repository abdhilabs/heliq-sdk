# Typed Perps validation — 2026-10-15

Scope and operation-to-fixture mapping: [coverage matrix](PERPS_API_COVERAGE.md).
Examples: [balances and Perps](Sources/HeliqSDK/HeliqSDK.docc/PerpsAndBalances.md).

## Passed

- 426 unit tests in 58 suites, including existing signature fixtures, Decimal balances,
  standard/unified/portfolio modes, missing values, multiple collateral ledgers,
  integer precision, partial failures, and WebSocket routing/decoding.
- 116 canonical payload/signature vectors compared with the official Python
  signing implementation at revision `2fdb18f9517675ea03695a0962bd19eece9c83f0`.
  Fixtures contain synthetic data and a public test-only key; no wallet history.
- 46 live testnet read checks and 19 live WebSocket snapshot feeds.
- Three funded testnet scenarios: standard class-transfer round trip and two-signer
  multisig/recovery; metadata-based Alo order, modification/cancellation, isolated
  market open, margin addition/removal, TP/SL, trailing stop, market close;
  valid-notional TWAP placement/cancellation and cleanup.
- Simulator shared-balance/trading flow and standard-mode Spot↔Perps transfer
  round trip passed, with ledger assertions. The primary simulator wallet was restored.
- macOS Swift Package Manager build, iOS SDK build with deployment target 16,
  and demo build-for-testing passed. macOS minimum 13 and Swift 6.1 remain unchanged.

Final read-only cleanup verified all four controlled wallets have zero open orders
and positions. Secondary wallets have zero Spot USDC and Perps account value.
The primary wallet remains unified; the dedicated standard wallet remains disabled
(standard). Trading leverage/margin settings were restored by the funded tests.
Total newly incurred cost across this work: **1.055708 test USDC**, including the
standard account activation charge, below the 5 USDC limit.

## Rejections observed and corrected

TWAP below the server's 100 USDC minimum was rejected; a 110 USDC notional order
was accepted and canceled. Removing the full added isolated margin after execution
was rejected because fees reduced the available margin; a smaller withdrawal
succeeded, followed by a complete position close. One signature for a two-signer
multisig was rejected as expected; two signatures succeeded. An ambiguous demo
transfer toggle was replaced with explicit direction selection before the passing
simulator round trip. Exchange mutations are never automatically retried.

## Unavailable live checks and retained warnings

Privileged HIP-3 deployment, liquidator transfer, and event-only WebSocket feeds
have fixtures but were not exercised live. The liquidator schema uses the documented
fields and generic official EIP-712 signing helper; a dedicated upstream helper was
unavailable. Valid-vault details use synthetic fixtures; no suitable vault was selected.
No mainnet mutations, validator/staking/Spot deployment/HyperEVM coverage, or
physical-device checks were performed.

Retained upstream warnings include BigInt's watchOS deployment declaration and
Argent library-evolution warnings. Existing deprecation/unused-variable warnings
and demo AppIntents metadata notices remain. No dependency forks, cache patches,
or warning suppression were introduced.

## Reproduction and local artifacts

Run `swift test --scratch-path /private/tmp/heliq-argent-spm --filter HeliqSDKTests`
for unit fixtures. Set `HELIQ_PERPS_READ_TESTS=1` for read and WebSocket integration
suites. Funded tests require ignored controlled wallet files described in
[wallet setup](TESTNET_WALLET.md), `HELIQ_PERPS_FUNDED_TESTS=1`, and serialized
execution of `PerpsFundedIntegrationTests`. They perform testnet mutations and
cleanup. Simulator tests additionally require `HELIQ_PERPS_UI_TESTS=1`; the
standard-wallet flow requires `HELIQ_PERPS_STANDARD_UI_TESTS=1` and deliberate
local wallet preparation. Never substitute a mainnet wallet.

Local evidence (temporary artifacts, not repository fixtures):

- `/private/tmp/heliq-perps-all-unit-final.log`
- `/private/tmp/heliq-perps-live-read-final.log`
- `/private/tmp/heliq-perps-live-ws.log`
- `/private/tmp/heliq-perps-funded-accepted.log`
- `/private/tmp/heliq-perps-ui-main-verified.xcresult`
- `/private/tmp/heliq-perps-ui-standard-verified.xcresult`
- `/private/tmp/heliq-perps-ios16-final.log`
- `/private/tmp/heliq-perps-demo-final.log`
- `/private/tmp/heliq-perps-spm-final.log`

Automatic approval review rejected copying funded-wallet history into committed
fixtures. Synthetic fixtures were used instead; no private account payloads were saved.
