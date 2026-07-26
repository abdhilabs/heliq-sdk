//
//  FeatureCoverageTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct FeatureCoverageTests {
  static let officialInfoTypes: Set<String> = [
    "allMids", "openOrders", "frontendOpenOrders", "userFills", "userFillsByTime", "userRateLimit", "orderStatus", "l2Book", "candleSnapshot", "maxBuilderFee", "historicalOrders", "userTwapSliceFills", "subAccounts", "vaultDetails", "userVaultEquities", "userRole", "portfolio", "delegations", "delegatorSummary", "delegatorHistory", "delegatorRewards", "userDexAbstraction", "userAbstraction", "borrowLendUserState", "borrowLendReserveState", "allBorrowLendReserveStates", "approvedBuilders", "perpDexs", "meta", "metaAndAssetCtxs", "clearinghouseState", "userFunding", "userNonFundingLedgerUpdates", "fundingHistory", "predictedFundings", "perpsAtOpenInterestCap", "perpDeployAuctionStatus", "activeAssetData", "perpDexLimits", "perpDexStatus", "allPerpMetas", "perpAnnotation", "perpCategories", "perpConciseAnnotations", "spotMeta", "spotMetaAndAssetCtxs", "spotClearinghouseState", "spotDeployState", "spotPairDeployAuctionStatus", "tokenDetails", "outcomeMeta", "settledOutcome"
  ]

  static let officialExchangeActions: Set<String> = [
    "order", "cancel", "cancelByCloid", "scheduleCancel", "modify", "batchModify", "updateLeverage", "updateIsolatedMargin", "agentSetAbstraction", "userOutcome", "validatorL1Stream", "authorizeAqav2Role", "claimRewards"
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
    #expect(encoded.contains(.string("claimRewards")))
  }

  @Test func webSocketParity_payloadPreservesEveryOfficialSubscription() {
    let names = Set(Self.officialWSSubscriptions.compactMap { HyperliquidWebSocketSubscription(type: .custom($0)).payload()["type"] as? String })
    #expect(names == Self.officialWSSubscriptions)
  }

  @Test func officialInfoRegistry_matchesResearchInventory() {
    let named: Set<String> = [
      HyperliquidInfoType.perpDexs.rawValue, HyperliquidInfoType.userDexAbstraction.rawValue,
      HyperliquidInfoType.userAbstraction.rawValue, HyperliquidInfoType.fundingHistory.rawValue,
      HyperliquidInfoType.spotClearinghouseState.rawValue, HyperliquidInfoType.tokenDetails.rawValue,
      HyperliquidInfoType.settledOutcome.rawValue
    ]
    #expect(named.isSubset(of: Self.officialInfoTypes))
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
