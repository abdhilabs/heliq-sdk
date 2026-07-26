//
//  FeatureCoverageTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//
//  Guards official Hyperliquid full-surface transport coverage.
//

import Foundation
import Testing
import HeliqSDK

struct FeatureCoverageTests {
  static let officialInfoTypes: Set<String> = [
    "allMids", "openOrders", "frontendOpenOrders", "userFills", "userFillsByTime", "userRateLimit", "orderStatus", "l2Book", "candleSnapshot", "maxBuilderFee", "historicalOrders", "userTwapSliceFills", "subAccounts", "userStakingSummary", "userStakingHistory", "userStakingRewards", "delegatorSummary", "delegations", "delegatorHistory", "delegatorRewards", "userRole", "portfolio", "userFees", "referral", "userState", "spotUserState", "clearinghouseState", "meta", "metaAndAssetCtxs", "spotMeta", "spotMetaAndAssetCtxs", "assetCtxs", "spotAssetCtxs", "predictedFundings", "perpsAtOpenInterestCap", "vaultDetails", "userVaultEquities", "userNonFundingLedgerUpdates", "queryOrderByOid", "queryOrderByCloid", "queryFills", "queryUserFundings", "getTime", "fetchBuilderFee", "maxBuilderFeeApproval", "approvedBuilders", "borrowLendUserState", "borrowLendReserveState", "allBorrowLendReserveStates", "webData2"
  ]

  static let officialExchangeActions: Set<String> = [
    "order", "cancel", "cancelByCloid", "scheduleCancel", "modify", "batchModify", "updateLeverage", "updateIsolatedMargin", "usdSend", "withdraw3", "spotSend", "usdClassTransfer", "vaultTransfer", "createSubAccount", "subAccountTransfer", "approveAgent", "approveBuilderFee", "updateBuilderFee", "tokenDelegate", "cDeposit", "cWithdraw", "twapOrder", "twapCancel", "setReferrer", "convertToMultiSig", "multiSig", "reserveRequestWeight", "noop"
  ]

  static let officialWSSubscriptions: Set<String> = [
    "allMids", "notification", "webData2", "webData3", "twapStates", "clearinghouseState", "openOrders", "userEvents", "userFills", "userFundings", "userNonFundingLedgerUpdates", "userTwapSliceFills", "userTwapHistory", "l2Book", "trades", "candle", "bbo", "activeAssetCtx", "activeAssetData", "spotState", "allDexsClearinghouseState", "allDexsAssetCtxs", "fastAssetCtxs", "outcomeMetaUpdates", "orderUpdates"
  ]

  @Test func infoParity_enumPreservesEveryOfficialType() {
    let encoded = Set(Self.officialInfoTypes.map { HyperliquidInfoRequest(type: .custom($0)).body()["type"] })
    #expect(encoded.count == Self.officialInfoTypes.count)
    #expect(encoded.contains(.string("borrowLendUserState")))
  }

  @Test func exchangeParity_enumPreservesEveryOfficialAction() {
    let encoded = Set(Self.officialExchangeActions.map { HyperliquidExchangeAction(type: .custom($0)).body()["type"] })
    #expect(encoded.count == Self.officialExchangeActions.count)
    #expect(encoded.contains(.string("twapOrder")))
  }

  @Test func webSocketParity_payloadPreservesEveryOfficialSubscription() {
    let names = Set(Self.officialWSSubscriptions.compactMap { HyperliquidWebSocketSubscription(type: .custom($0)).payload()["type"] as? String })
    #expect(names == Self.officialWSSubscriptions)
  }

  @Test func endpoints_pointToOfficialHosts() {
    #expect(Constants.API.infoEndpoint == "/info")
    #expect(Constants.API.exchangeEndpoint == "/exchange")
    #expect(Constants.API.mainnetBaseURL == "https://api.hyperliquid.xyz")
    #expect(Constants.API.testnetBaseURL == "https://api.hyperliquid-testnet.xyz")
    #expect(Constants.WebSocket.mainnetURL == "wss://api.hyperliquid.xyz/ws")
    #expect(Constants.WebSocket.testnetURL == "wss://api.hyperliquid-testnet.xyz/ws")
  }
}
