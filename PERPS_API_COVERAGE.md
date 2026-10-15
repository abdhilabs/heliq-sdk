# Typed Perps API coverage

Baseline: official Hyperliquid documentation inspected on 2026-10-15 (Asia/Jakarta).
Sources: [Perps info](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint/perpetuals),
[shared info](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint),
[exchange](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/exchange-endpoint),
[HIP-3](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/hip-3-deployer-actions),
[WebSocket](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/websocket/subscriptions).

## Read APIs

`info.perps(query)` binds each request factory to a concrete response model.
`getBalances(address:)` reads global Spot and validator Perps; its `dexes:` overload
explicitly selects additional DEXs. Monetary Perps summaries are omitted for shared
or unresolved modes; positions remain visible. No aggregate double counts collateral.

| Operation | Typed API | Fixture |
|---|---|---|
| Mode-aware balances | `info.getBalances(address:dexes:)` | `PerpsAPITests.balancesKeepDistinctSemantics` |
| Coin-specific capacity | `info.getActiveAssetData(address:coin:)` | activeAssetData + malformed pair tests |
| `perpDexs` | `info.perps(.dexs(...))` | `perpDexs.json`, `PerpsFixtureTests` |
| `meta` | `info.perps(.meta(...))` | `meta.json`, `PerpsFixtureTests` |
| `metaAndAssetCtxs` | `info.perps(.metaAndContexts(...))` | `metaAndAssetCtxs.json`, `PerpsFixtureTests` |
| `allPerpMetas` | `info.perps(.allMetas(...))` | `allPerpMetas.json`, `PerpsFixtureTests` |
| `clearinghouseState` | `info.perps(.account(...))` | `clearinghouseState.json`, `PerpsFixtureTests` |
| `spotClearinghouseState` | `info.perps(.spotState(...))` | `spotClearinghouseState.json`, `PerpsFixtureTests` |
| `activeAssetData` | `info.perps(.activeAsset(...))` | `activeAssetData.json`, `PerpsFixtureTests` |
| `userAbstraction` | `info.perps(.abstraction(...))` | `userAbstraction.json`, `PerpsFixtureTests` |
| `userDexAbstraction` | `info.perps(.legacyDexAbstraction(...))` | `userDexAbstraction.json`, `PerpsFixtureTests` |
| `fundingHistory` | `info.perps(.fundingHistory(...))` | `fundingHistory.json`, `PerpsFixtureTests` |
| `predictedFundings` | `info.perps(.predictedFunding(...))` | `predictedFundings.json`, `PerpsFixtureTests` |
| `perpsAtOpenInterestCap` | `info.perps(.openInterestCaps(...))` | `perpsAtOpenInterestCap.json`, `PerpsFixtureTests` |
| `perpDeployAuctionStatus` | `info.perps(.deployAuction(...))` | `perpDeployAuctionStatus.json`, `PerpsFixtureTests` |
| `perpDexLimits` | `info.perps(.dexLimits(...))` | `perpDexLimits.json`, `PerpsFixtureTests` |
| `perpDexStatus` | `info.perps(.dexStatus(...))` | `perpDexStatus.json`, `PerpsFixtureTests` |
| `perpAnnotation` | `info.perps(.annotation(...))` | `perpAnnotation.json`, `PerpsFixtureTests` |
| `perpCategories` | `info.perps(.categories(...))` | `perpCategories.json`, `PerpsFixtureTests` |
| `perpConciseAnnotations` | `info.perps(.conciseAnnotations(...))` | `perpConciseAnnotations.json`, `PerpsFixtureTests` |
| `openOrders` | `info.perps(.openOrders(...))` | `openOrders.json`, `PerpsFixtureTests` |
| `frontendOpenOrders` | `info.perps(.frontendOpenOrders(...))` | `frontendOpenOrders.json`, `PerpsFixtureTests` |
| `historicalOrders` | `info.perps(.historicalOrders(...))` | `historicalOrders.json`, `PerpsFixtureTests` |
| `userFills` | `info.perps(.fills(...))` | `userFills.json`, `PerpsFixtureTests` |
| `userFillsByTime` | `info.perps(.fillsByTime(...))` | `userFillsByTime.json`, `PerpsFixtureTests` |
| `userRateLimit` | `info.perps(.rateLimit(...))` | `userRateLimit.json`, `PerpsFixtureTests` |
| `userFees` | `info.perps(.fees(...))` | `userFees.json`, `PerpsFixtureTests` |
| `userTwapSliceFills` | `info.perps(.twapSliceFills(...))` | `userTwapSliceFills.json`, `PerpsFixtureTests` |
| `userRole` | `info.perps(.role(...))` | `userRole.json`, `PerpsFixtureTests` |
| `subAccounts` | `info.perps(.subAccounts(...))` | `subAccounts.json`, `PerpsFixtureTests` |
| `extraAgents` | `info.perps(.agents(...))` | `extraAgents.json`, `PerpsFixtureTests` |
| `approvedBuilders` | `info.perps(.approvedBuilders(...))` | `approvedBuilders.json`, `PerpsFixtureTests` |
| `orderStatus` | `info.perps(.orderStatus(...))` | `orderStatus.json`, `PerpsFixtureTests` |
| `orderStatus` | `info.perps(.orderStatus(...))` | `orderStatus.json`, `PerpsFixtureTests` |
| `allMids` | `info.perps(.mids(...))` | `allMids.json`, `PerpsFixtureTests` |
| `userNonFundingLedgerUpdates` | `info.perps(.ledger(...))` | `userNonFundingLedgerUpdates.json`, `PerpsFixtureTests` |
| `userFunding` | `info.perps(.userFunding(...))` | `userFunding.json`, `PerpsFixtureTests` |
| `portfolio` | `info.perps(.portfolio(...))` | `portfolio.json`, `PerpsFixtureTests` |
| `borrowLendUserState` | `info.perps(.borrowLendUser(...))` | `borrowLendUserState.json`, `PerpsFixtureTests` |
| `maxBuilderFee` | `info.perps(.builderFee(...))` | `maxBuilderFee.json`, `PerpsFixtureTests` |
| `l2Book` | `info.perps(.book(...))` | `l2Book.json`, `PerpsFixtureTests` |
| `candleSnapshot` | `info.perps(.candles(...))` | `candleSnapshot.json`, `PerpsFixtureTests` |
| `borrowLendReserveState` | `info.perps(.spotMeta(...))` | `borrowLendReserveState.json`, `PerpsFixtureTests` |

Typed responses include margin tables, collateral tokens, nullable funding venues,
metadata-only and metadata/context forms of allPerpMetas, exact decimal strings,
fees, ledger history, portfolio periods, and vault/referral account dependencies.
Undocumented fee-trial metadata remains an optional JSON field rather than making
otherwise valid fee responses undecodable. Legacy referral rewardHistory is omitted;
current reward payouts are available in the typed non-funding ledger.

## Exchange APIs

All actions use `exchange.executePerps(action:context:)`, with existing signing,
nonce allocation and transport. `usdClassTransfer` and `sendAsset` also have direct
conveniences. New inputs use Decimal; old Double-based interfaces are unchanged.

| Operation | Typed action/API | Wire/signature coverage |
|---|---|---|
| `order` | `orders — Gtc/Ioc/Alo, market, trigger TP/SL, grouping, builder fee` | order-Gtc/Ioc/Alo, trigger-true/false, grouped |
| `cancel` | `cancel(orderID), optional fast` | cancel, cancel-fast |
| `cancelByCloid` | `cancel(cloid), optional fast` | cancelByCloid |
| `modify` | `modifyOrder, explicit alwaysPlace` | modify; live default acknowledgement fixture |
| `batchModify` | `modify, explicit alwaysPlace` | batchModify |
| `scheduleCancel` | `scheduleCancel(Date?) — nil removes schedule` | schedule-set/clear |
| `updateLeverage` | `leverage(market:value:cross:)` | leverage |
| `updateIsolatedMargin` | `isolatedMargin — signed collateral units` | margin-add/remove |
| `topUpIsolatedOnlyMargin` | `isolatedLeverage` | isolated-leverage |
| `market close` | `marketClose — current position, reduce-only IOC` | market order fixtures + funded lifecycle |
| `twapOrder` | `twap` | twap |
| `twapCancel` | `cancelTwap` | twapCancel |
| `trailingStop` | `trailingStop(percent/price retracement)` | trailing-percent/price |
| `usdClassTransfer` | `usdClassTransfer(amount:toPerp:)` | class-transfer, standard/shared-mode regression |
| `sendAsset` | `sendAsset — ledgers/token/subaccount` | send-asset, metadata/precision validation |
| `agentSendAsset` | `agentSendAsset — same-account agent transfer` | agent-send |
| `approveAgent` | `approveAgent — explicit agent address` | agent-approval |
| `userSetAbstraction` | `userAbstraction` | user-mode |
| `agentSetAbstraction` | `agentAbstraction` | agent-mode |
| `userDexAbstraction` | `legacyUserDexAbstraction` | legacy-user-mode |
| `agentEnableDexAbstraction` | `legacyAgentDexAbstraction` | legacy-agent-mode |
| `createSubAccount` | `createSubAccount` | subaccount-create |
| `subAccountTransfer` | `subAccountTransfer` | subaccount-transfer |
| `subAccountSpotTransfer` | `subAccountSpotTransfer` | subaccount-spot |
| `reserveRequestWeight` | `reserveRequestWeight` | reserve |
| `noop` | `invalidateNonce — explicit pending nonce` | noop |
| `withdraw3` | `withdraw — bridge withdrawal` | withdraw |
| `approveBuilderFee` | `approveBuilder — explicit maximum percentage` | builder-approval |
| `vaultTransfer` | `vaultTransfer` | vault |
| `setReferrer` | `setReferrer` | referrer |
| `convertToMultiSigUser` | `convertMultisig / restoreNormalAccount` | convert/restore |
| `multiSig` | `preparePerpsMultisig → signPerpsMultisig → executeMultisig` | multisig-l1, frozen-payload and funded recovery tests |
| `hip3LiquidatorTransfer` | `liquidatorTransfer` | liquidator-transfer; newer schema uses official generic EIP-712 reference |

Single modification returns the server acknowledgement; it does not invent a
replacement ID. Batch/per-order results preserve partial rejections. `fast` and
`alwaysPlace` flags are omitted when false. User-signed operations reject unsupported
vault/expiry envelope context. Class transfers reject shared/unresolved modes without
changing the mode. Multisig resolves one immutable payload before collecting signatures.
Large signed integers are preserved in MessagePack and JSON, including identifiers
above Double's exact range; legacy small-number behavior remains unchanged.

## HIP-3 deployment

| Variant | Typed deployment case | Fixture |
|---|---|---|
| `registerAsset2` | `PerpsDeployAction.registerAsset(legacy: false)` | `deploy-registerAsset2` signing vector |
| `registerAsset` | `PerpsDeployAction.registerAsset(legacy: true)` | `deploy-registerAsset` signing vector |
| `setOracle` | `PerpsDeployAction.oracle` | `deploy-setOracle` signing vector |
| `setFundingMultipliers` | `PerpsDeployAction.fundingMultipliers` | `deploy-setFundingMultipliers` signing vector |
| `setFundingInterestRates` | `PerpsDeployAction.fundingInterestRates` | `deploy-setFundingInterestRates` signing vector |
| `setFundingClamps` | `PerpsDeployAction.fundingClamps` | `deploy-setFundingClamps` signing vector |
| `haltTrading` | `PerpsDeployAction.halt` | `deploy-haltTrading` signing vector |
| `insertMarginTable` | `PerpsDeployAction.insertMarginTable` | `deploy-insertMarginTable` signing vector |
| `setMarginTableIds` | `PerpsDeployAction.marginTableIDs` | `deploy-setMarginTableIds` signing vector |
| `setFeeRecipient` | `PerpsDeployAction.feeRecipient` | `deploy-setFeeRecipient` signing vector |
| `setOpenInterestCaps` | `PerpsDeployAction.openInterestCaps` | `deploy-setOpenInterestCaps` signing vector |
| `setSubDeployers` | `PerpsDeployAction.subDeployers` | `deploy-setSubDeployers` signing vector |
| `setMarginModes` | `PerpsDeployAction.marginModes` | `deploy-setMarginModes` signing vector |
| `setDeployerFees` | `PerpsDeployAction.deployerFees` | `deploy-setDeployerFees` signing vector |
| `setPerpAnnotation` | `PerpsDeployAction.annotation` | `deploy-setPerpAnnotation` signing vector |
| `disableDex` | `PerpsDeployAction.disableDex` | `deploy-disableDex` signing vector |

Tuple inputs are validated and sorted lexicographically before signing. Current
`setDeployerFees` combines fee scaling and growth mode. Deployments, oracle changes,
fee settings, backstop-liquidator funding, and other privileged operations are fixture
verified only; no deployer account, HYPE stake, or administrative permissions were provisioned.

## WebSocket

Each factory binds subscription parameters and a concrete event decoder. The existing
SubscriptionManager owns subscribe/unsubscribe/reconnect behavior. Typed router handlers
receive complete envelopes and distinguish user/coin/DEX/interval identity without replacing
legacy payload handlers. Unlabelled feeds and multiple aggregation variants for one book
require separate routers/connections to avoid attributing an event to the wrong source.

| Channel | Typed subscription factory | Fixture |
|---|---|---|
| `clearinghouseState` | `PerpsSubscription<PerpsAccountEvent>.account(user: user)` | `ws-clearinghouseState.json` |
| `spotState` | `PerpsSubscription<PerpsSpotEvent>.spotState(user: user)` | `ws-spotState.json` |
| `allDexsClearinghouseState` | `PerpsSubscription<PerpsAllDexsAccountEvent>.allAccounts(user: user)` | `ws-allDexsClearinghouseState.json` |
| `allDexsAssetCtxs` | `PerpsSubscription<PerpsAllDexsContextsEvent>.allContexts()` | `ws-allDexsAssetCtxs.json` |
| `activeAssetData` | `PerpsSubscription<PerpsActiveAssetData>.activeAsset(user: user, coin: "BTC")` | `ws-activeAssetData.json` |
| `activeAssetCtx` | `PerpsSubscription<PerpsAssetContextEvent>.assetContext(coin: "BTC")` | `ws-activeAssetCtx.json` |
| `openOrders` | `PerpsSubscription<PerpsOpenOrdersEvent>.openOrders(user: user)` | `ws-openOrders.json` |
| `orderUpdates` | `PerpsSubscription<[PerpsHistoricalOrder]>.orderUpdates(user: user)` | `ws-orderUpdates.json` |
| `userFills` | `PerpsSubscription<PerpsFillsEvent>.fills(user: user)` | `ws-userFills.json` |
| `userTwapSliceFills` | `PerpsSubscription<PerpsTwapSliceEvent>.twapSlices(user: user)` | `ws-userTwapSliceFills.json` |
| `userTwapHistory` | `PerpsSubscription<PerpsTwapHistoryEvent>.twapHistory(user: user)` | `ws-userTwapHistory.json` |
| `twapStates` | `PerpsSubscription<PerpsTwapStatesEvent>.twapStates(user: user)` | `ws-twapStates.json` |
| `allMids` | `PerpsSubscription<PerpsMidsEvent>.mids()` | `ws-allMids.json` |
| `bbo` | `PerpsSubscription<PerpsBbo>.bbo(coin: "BTC")` | `ws-bbo.json` |
| `trades` | `PerpsSubscription<[PerpsTrade]>.trades(coin: "BTC")` | `ws-trades.json` |
| `candle` | `PerpsSubscription<[PerpsCandle]>.candles(coin: "BTC", interval: .minute)` | `ws-candle.json` |
| `l2Book` | `PerpsSubscription<PerpsBook>.book(coin: "BTC")` | `ws-l2Book.json` |
| `userFundings` | `PerpsSubscription<PerpsFundingsEvent>.funding(user: user)` | `ws-userFundings.json` |
| `userNonFundingLedgerUpdates` | `PerpsSubscription<PerpsLedgerEvent>.ledger(user: user)` | `ws-userNonFundingLedgerUpdates.json` |
| `user` | `PerpsSubscription<PerpsUserEvents>.userEvents(user: user)` | `ws-user.json` |
| `notification` | `PerpsSubscription<PerpsNotification>.notifications(user: user)` | `ws-notification.json` |
| `webData3` | `PerpsSubscription<PerpsWebData3>.webData(user: user)` | `ws-webData3.json` |
| `fastAssetCtxs` | `PerpsSubscription<PerpsFastContexts>.fastContexts()` | `ws-fastAssetCtxs.json` |

Candle decoding accepts both arrays and single updates. Fast-context decoding accepts
numeric/string prices and expands its buffer until the complete raw-DEFLATE JSON stream
fits, with a 4 MiB limit. Existing FastAssetCtx String properties remain unchanged.

## Acceptance and limits

- `PerpsFixtureTests`: synthetic request-response and WS-envelope fixtures for every query/channel.
- `PerpsAPITests`: Decimal/identifier validation, shared/standard/unknown balances,
  partial failures, modification acknowledgements, routing, compression, and immutable multisig payloads.
- Signing fixtures: 116 mainnet/testnet vectors generated with official Python SDK
  revision `2fdb18f9517675ea03695a0962bd19eece9c83f0`, using a public test-only key.
  Newer action schemas without dedicated Python helpers use its generic signer.
- Live results and reproducible commands: `PERPS_TEST_REPORT.md`.
- Unknown operations remain available through raw APIs. Validator management, staking
  management, Spot deployment, and HyperEVM contract APIs are outside this Perps scope.
- Remaining upstream warnings are retained. No dependency, deployment minimum, or wallet
  storage implementation was changed by this feature.
