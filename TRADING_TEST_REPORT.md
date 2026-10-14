# Trading SDK repair and end-to-end results

Updated: 2026-10-15 (Asia/Jakarta). Hyperliquid testnet; iPhone Air simulator, iOS 26.5.

## Outcome

The unsigned legacy exchange path has been replaced with official signed requests.
The original HTTP 422/deserialization failures are gone in the live checks.
Funded testnet order, position, transfer, referral, builder approval, and demo
trading checks now pass. Scheduled cancellation is blocked by the server volume
requirement. No mainnet mutations were performed.

## SDK changes

- Send `{action, nonce, signature}` with canonical L1 or user-signed EIP-712 signing.
  Native `WalletService` delegates to `Signer`; custom wallets implement the new
  `signL1` and `signUserSigned` protocol requirements. Their defaults explicitly
  reject unsupported signing, preserving source compatibility for read-only wallets.
- Map official response envelopes, resting/filled/trigger statuses, per-item bulk
  failures, and cancellation failures. Never automatically retry exchange mutations.
- Encode bulk orders as `order`, cancellations as lists, modifications as
  `batchModify`, and leverage/margin changes as `updateLeverage`. Modification reads
  the existing order and preserves side, reduce-only, trigger, and requested time in force.
  Hyperliquid can override non-executable Gtc modifications to Alo. Client-ID
  modification resolves the active open order when history returns a canceled predecessor.
  Leverage and margin-mode changes preserve the other account setting.
- Market orders use an IOC limit, current mids, 5% slippage, and official price
  rounding. An explicit `price` supplies the execution bound.
- Route unified/portfolio-margin transfers through `sendAsset`; standard accounts
  retain `spotSend`/`usdSend`. Resolve spot token identifiers from metadata. Transfer asset 0 means perpetual
  USDC; other values are spot token indices. `spotTransfer` always uses a token
  index, including 0 for spot USDC. Source address must match the signing wallet.
- Encode vault amounts as integer micro-USDC and require exactly one direction.
  Referral input is a code. Builder approvals require an explicit maximum fee;
  multisig conversions require explicit signer addresses and threshold. Old methods
  without those required settings fail locally rather than inventing permissions.
- Extend canonical MessagePack to support addresses, client IDs, and batches larger
  than 15. Reject numeric overflow before conversion.

The demo now parses its bulk JSON, fixes vault direction, accepts builder/multisig
settings, displays SDK errors, and uses native testnet signing. The dedicated funding
wallet is now stored privately (Keychain on devices); rejection probes explicitly use fresh, unfunded
wallets. Mainnet remains a read-only mock. See `TESTNET_WALLET.md`.

Protocol references: [Exchange endpoint](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint),
[official Python SDK](https://github.com/hyperliquid-dex/hyperliquid-python-sdk/blob/master/hyperliquid/exchange.py),
[official signing implementation](https://github.com/hyperliquid-dex/hyperliquid-python-sdk/blob/master/hyperliquid/utils/signing.py).

## Funded verification (2026-10-15)

| Feature | Actual live result |
|---|---|
| Limit order | Resting order confirmed |
| Modify by order ID and client ID | Replacement confirmed; stale client-ID history handled |
| Cancel by client ID/order ID/all | Orders removed |
| Bulk orders | Two resting orders confirmed, then canceled |
| Market buy and reduce-only sell | Both filled; position closed |
| Leverage and isolated/cross margin | State confirmed; original settings restored |
| Spot transfer, USD send, send-to-address, transfer | Recipient balance changes confirmed; funds returned |
| Builder approval | Approved at 0%; live maximum fee verified |
| Referral | TESTNET applied to secondary wallet; referredBy.code confirmed |
| Multisig | Disposable account converted to 2-of-2; one signature rejected with exact threshold error; two signatures restored normal user |
| Vault | Public testnet vaultSummaries returned []; no target available |
| Scheduled cancellation | Server rejects until $1,000,000 trading volume; test remains red |
| Demo place/modify/cancel | Funded simulator test passed |

The funded wallet uses unified collateral: its Spot USDC backs Perps directly.
The server rejects class transfers on this account; its abstraction was preserved.
The live testnet metadata identifies BTC as asset 3 and SOL as asset 0. The UI
test initially used SOL with BTC size precision; using the correct BTC index fixed
the invalid-size rejection. The SDK lifecycle resolves BTC from metadata.

Final cleanup query confirmed **no open orders or positions on all three accounts**.
The main wallet holds **996.958516 test USDC**; both secondary accounts hold zero.
All three roles are normal users. Referral remains applied only to the secondary
wallet, and the approved 0% builder permission remains on the main wallet.
The additional disposable account activation cost 1 test USDC.

Latest unit run: **410 tests passed**. SDK iOS 16 build succeeded. The funded SDK
account-check test remains red for scheduled cancellation (reported volume $81.62);
its temporary resting order was canceled. No artificial volume was generated.

Artifacts:
- `/private/tmp/heliq-funded-final.log` — order/position/transfers/builder/schedule
- `/private/tmp/heliq-funded-unit-final.log` — 410 unit tests
- `/private/tmp/heliq-funded-ios16.log` — iOS 16 SDK build
- `/private/tmp/heliq-funded-ui-btc.xcresult` — funded demo lifecycle passed
- `/private/tmp/heliq-referral-live.log` — successful secondary-wallet referral
- `/private/tmp/heliq-multisig-live-final.log` — exact threshold rejection and recovery
- `/private/tmp/heliq-funded-final-state.jsonl` — balances, orders, positions, roles

## Reproduction

Live mutation suites are opt-in and require the ignored local wallet files.

```sh
swift test --filter HeliqSDKTests --no-parallel
HELIQ_FUNDED_TRADING_TESTS=1 swift test --filter FundedTradingIntegrationTests --no-parallel
```

Schedule and builder checks additionally require `HELIQ_APPROVED_ACCOUNT_TESTS=1`.
Funded UI checks require `TEST_RUNNER_HELIQ_FUNDED_UI_TESTS=1` for xcodebuild and
`-only-testing:HeliqSDKDemoUITests/HeliqSDKDemoUITests/testFundedTradingPlaceModifyCancel()`.
The funded UI fixture uses the verified testnet BTC index 3; update it if metadata changes.

Device Keychain execution and mainnet mutations were not tested. Earlier unfunded
rejection probes were diagnostic only; obsolete simulator probes have been removed.

Remaining warnings are not suppressed: upstream BigInt's watchOS 4 minimum,
Argent `web3` lacking library-evolution support, and existing SDK/test diagnostics
such as the deprecated `tradeEndpoint` alias and unused test variables.

The [official faucet](https://hyperliquid.gitbook.io/hyperliquid-docs/onboarding/testnet-faucet)
requires prior mainnet eligibility for the same address. These checks use locally controlled testing wallets, never someone else's wallet
or a published example key.
