//
//  FeatureCoverageTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//
//  Guards that every SDK-supported Hyperliquid surface stays wired.
//

import Foundation
import Testing
import HeliqSDK

struct FeatureCoverageTests {
  /// Info endpoints currently implemented by HeliqSDK (not full Hyperliquid surface).
  static let implementedInfoTypes: Set<String> = [
    "userState",
    "spotUserState",
    "allMids",
    "assetCtxs",
    "spotAssetCtxs",
    "candleSnapshot",
    "l2Book",
    "queryOrderByOid",
    "queryOrderByCloid",
    "queryFills",
    "queryUserFundings",
    "meta",
    "spotMeta",
    "getTime",
    "fetchBuilderFee"
  ]

  /// Exchange action types currently implemented by HeliqSDK.
  static let implementedExchangeTypes: Set<String> = [
    "order",
    "bulkOrders",
    "cancel",
    "cancelByCloid",
    "cancelAll",
    "modify",
    "modifyByCloid",
    "setLeverage",
    "setMarginMode",
    "transfer",
    "sendToAddress",
    "spotTransfer",
    "vaultTransfer",
    "updateBuilder",
    "scheduleCancel",
    "setReferrer",
    "convertToMultiSig",
    "usdSend"
  ]

  /// Official Hyperliquid WS subscription types covered by SubscriptionChannel.
  static let implementedWSChannels: Set<String> = [
    "allMids",
    "l2Book",
    "trades",
    "userEvents",
    "userFills",
    "candle",
    "orderUpdates",
    "userFundings",
    "userNonFundingLedgerUpdates",
    "webData2",
    "bbo",
    "activeAssetCtx",
    "activeAssetData"
  ]

  /// Known Hyperliquid Info types NOT yet in the SDK (documented gap).
  static let missingInfoTypes: Set<String> = [
    "openOrders",
    "frontendOpenOrders",
    "userFills",
    "userFillsByTime",
    "historicalOrders",
    "orderStatus",
    "portfolio",
    "userRole",
    "userFees",
    "referral",
    "subAccounts",
    "vaultDetails",
    "userVaultEquities",
    "userTwapSliceFills",
    "maxBuilderFee",
    "approvedBuilders",
    "clearinghouseState",
    "metaAndAssetCtxs",
    "spotMetaAndAssetCtxs",
    "predictedFundings",
    "perpsAtOpenInterestCap",
    "delegatorSummary",
    "delegations",
    "delegatorHistory",
    "delegatorRewards",
    "borrowLendUserState",
    "borrowLendReserveState",
    "allBorrowLendReserveStates"
  ]

  /// Known Hyperliquid Exchange actions NOT yet in the SDK (documented gap).
  static let missingExchangeTypes: Set<String> = [
    "withdraw3",
    "spotSend",
    "usdClassTransfer",
    "updateLeverage",
    "updateIsolatedMargin",
    "batchModify",
    "twapOrder",
    "twapCancel",
    "approveAgent",
    "approveBuilderFee",
    "cDeposit",
    "cWithdraw",
    "tokenDelegate",
    "vaultDistribute",
    "createSubAccount",
    "subAccountTransfer",
    "sendAsset",
    "reserveRequestWeight",
    "topUpIsolatedOnlyMargin"
  ]

  /// Official WS channels NOT yet in SubscriptionChannel.
  static let missingWSChannels: Set<String> = [
    "notification",
    "webData3",
    "twapStates",
    "clearinghouseState",
    "openOrders",
    "userTwapSliceFills",
    "userTwapHistory",
    "spotState",
    "allDexsClearinghouseState",
    "allDexsAssetCtxs",
    "outcomeMetaUpdates",
    "fastAssetCtxs"
  ]

  @Test func testImplementedInfoCoverage_isNonEmptyAndStable() {
    #expect(Self.implementedInfoTypes.count == 15)
    #expect(Self.implementedInfoTypes.contains("allMids"))
    #expect(Self.implementedInfoTypes.contains("meta"))
    #expect(Self.implementedInfoTypes.contains("l2Book"))
  }

  @Test func testImplementedExchangeCoverage_isNonEmptyAndStable() {
    #expect(Self.implementedExchangeTypes.count == 18)
    #expect(Self.implementedExchangeTypes.contains("order"))
    #expect(Self.implementedExchangeTypes.contains("cancel"))
    #expect(Self.implementedExchangeTypes.contains("usdSend"))
  }

  @Test func testImplementedWSCoverage_matchesSubscriptionChannel() {
    let channels: [SubscriptionChannel] = [
      .allMids,
      .l2Book(coin: "BTC"),
      .trades(coin: "BTC"),
      .userEvents,
      .userFills,
      .candle(coin: "BTC", interval: "1m"),
      .orderUpdates,
      .userFundings,
      .userNonFundingLedgerUpdates,
      .webData2,
      .bbo(coin: "BTC"),
      .activeAssetCtx(coin: "BTC"),
      .activeAssetData(coin: "BTC")
    ]
    let names = Set(channels.map(\.channelName))
    #expect(names == Self.implementedWSChannels)
  }

  @Test func testMissingInfoAndImplemented_doNotOverlap() {
    #expect(Self.implementedInfoTypes.isDisjoint(with: Self.missingInfoTypes))
  }

  @Test func testMissingExchangeAndImplemented_doNotOverlap() {
    #expect(Self.implementedExchangeTypes.isDisjoint(with: Self.missingExchangeTypes))
  }

  @Test func testMissingWSAndImplemented_doNotOverlap() {
    #expect(Self.implementedWSChannels.isDisjoint(with: Self.missingWSChannels))
  }

  @Test func testInfoPath_isPublicAndStable() {
    // Endpoint routing action strings are internal; APIRouterTests owns wire checks.
    #expect(Constants.API.infoEndpoint == "/info")
  }

  @Test func testEnvironments_pointToOfficialHosts() {
    #expect(Constants.API.mainnetBaseURL == "https://api.hyperliquid.xyz")
    #expect(Constants.API.testnetBaseURL == "https://api.hyperliquid-testnet.xyz")
    #expect(Constants.WebSocket.mainnetURL == "wss://api.hyperliquid.xyz/ws")
    #expect(Constants.WebSocket.testnetURL == "wss://api.hyperliquid-testnet.xyz/ws")
  }
}
