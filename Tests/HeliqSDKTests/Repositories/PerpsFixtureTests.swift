//
//  PerpsFixtureTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import Testing

@testable import HeliqSDK

@Suite(.serialized)
struct PerpsFixtureTests {
  private let user = "0x1234567890123456789012345678901234567890"
  private let page = HyperliquidPageRequest(startTime: Date(timeIntervalSince1970: 1_700_000_000))
  static let queryNames = [
    "perpDexs", "meta", "metaAndAssetCtxs", "allPerpMetas", "clearinghouseState",
    "spotClearinghouseState", "activeAssetData", "userAbstraction", "userDexAbstraction",
    "fundingHistory", "predictedFundings", "perpsAtOpenInterestCap", "perpDeployAuctionStatus",
    "perpDexLimits", "perpDexStatus", "perpAnnotation", "perpCategories", "perpConciseAnnotations",
    "openOrders", "frontendOpenOrders", "historicalOrders", "userFills", "userFillsByTime",
    "userRateLimit", "userFees", "userTwapSliceFills", "userRole", "subAccounts", "extraAgents",
    "approvedBuilders", "maxBuilderFee", "orderStatus", "userFunding",
    "userNonFundingLedgerUpdates", "portfolio", "borrowLendUserState", "allMids", "l2Book",
    "candleSnapshot", "spotMeta", "borrowLendReserveState", "allBorrowLendReserveStates",
    "vaultDetails", "userVaultEquities", "referral",
  ]
  @Test(arguments: queryNames)
  func typedQueryDecodesItsOfficialFixture(_ name: String) throws {
    switch name {
    case "perpDexs": try check(.dexs(), fixture: name)
    case "meta": try check(.meta(dex: "xyz"), fixture: name)
    case "metaAndAssetCtxs": try check(.metaAndContexts(), fixture: name)
    case "allPerpMetas": try check(.allMetas(), fixture: name)
    case "clearinghouseState": try check(.account(address: user), fixture: name)
    case "spotClearinghouseState": try check(.spotState(address: user), fixture: name)
    case "activeAssetData": try check(.activeAsset(address: user, coin: "BTC"), fixture: name)
    case "userAbstraction": try check(.abstraction(address: user), fixture: name)
    case "userDexAbstraction": try check(.legacyDexAbstraction(address: user), fixture: name)
    case "fundingHistory": try check(.fundingHistory(coin: "BTC", page: page), fixture: name)
    case "predictedFundings": try check(.predictedFunding(), fixture: name)
    case "perpsAtOpenInterestCap": try check(.openInterestCaps(), fixture: name)
    case "perpDeployAuctionStatus": try check(.deployAuction(), fixture: name)
    case "perpDexLimits": try check(.dexLimits(dex: "xyz"), fixture: name)
    case "perpDexStatus": try check(.dexStatus(), fixture: name)
    case "perpAnnotation": try check(.annotation(coin: "BTC"), fixture: name)
    case "perpCategories": try check(.categories(), fixture: name)
    case "perpConciseAnnotations": try check(.conciseAnnotations(), fixture: name)
    case "openOrders": try check(.openOrders(address: user), fixture: name)
    case "frontendOpenOrders": try check(.frontendOpenOrders(address: user), fixture: name)
    case "historicalOrders": try check(.historicalOrders(address: user), fixture: name)
    case "userFills": try check(.fills(address: user), fixture: name)
    case "userFillsByTime": try check(.fillsByTime(address: user, page: page), fixture: name)
    case "userRateLimit": try check(.rateLimit(address: user), fixture: name)
    case "userFees": try check(.fees(address: user), fixture: name)
    case "userTwapSliceFills": try check(.twapSliceFills(address: user), fixture: name)
    case "userRole": try check(.role(address: user), fixture: name)
    case "subAccounts": try check(.subAccounts(address: user), fixture: name)
    case "extraAgents": try check(.agents(address: user), fixture: name)
    case "approvedBuilders": try check(.approvedBuilders(address: user), fixture: name)
    case "maxBuilderFee": try check(.builderFee(address: user, builder: user), fixture: name)
    case "orderStatus": try check(.orderStatus(address: user, orderID: 42), fixture: name)
    case "userFunding": try check(.userFunding(address: user, page: page), fixture: name)
    case "userNonFundingLedgerUpdates": try check(.ledger(address: user, page: page), fixture: name)
    case "portfolio": try check(.portfolio(address: user), fixture: name)
    case "borrowLendUserState": try check(.borrowLendUser(address: user), fixture: name)
    case "allMids": try check(.mids(), fixture: name)
    case "l2Book": try check(.book(coin: "BTC", nSigFigs: 5, mantissa: 2), fixture: name)
    case "candleSnapshot":
      try check(.candles(coin: "BTC", interval: .fifteenMinutes, page: page), fixture: name)
    case "spotMeta": try check(.spotMeta(), fixture: name)
    case "borrowLendReserveState": try check(.borrowReserve(token: 0), fixture: name)
    case "allBorrowLendReserveStates": try check(.borrowReserves(), fixture: name)
    case "vaultDetails": try check(.vaultDetails(address: user, user: user), fixture: name)
    case "userVaultEquities": try check(.vaultEquities(address: user), fixture: name)
    case "referral": try check(.referral(address: user), fixture: name)
    default: Issue.record("Unregistered query fixture")
    }
  }
  private func check<Response>(_ query: PerpsQuery<Response>, fixture: String) throws {
    #expect(query.request.body()["type"] == .string(fixture))
    try validatePerpsParameters(query.request.parameters)
    _ = try query.decode(try perpsFixture(fixture))
  }
  static let subscriptionNames = [
    "clearinghouseState", "spotState", "allDexsClearinghouseState", "allDexsAssetCtxs",
    "activeAssetData", "activeAssetCtx", "openOrders", "orderUpdates", "userFills",
    "userTwapSliceFills", "userTwapHistory", "twapStates", "allMids", "bbo", "trades", "candle",
    "l2Book", "userFundings", "userNonFundingLedgerUpdates", "user", "notification", "webData3",
    "fastAssetCtxs",
  ]
  @Test(arguments: subscriptionNames)
  func typedSubscriptionDecodesItsEnvelope(_ name: String) throws {
    switch name {
    case "clearinghouseState":
      try checkSubscription(PerpsSubscription<PerpsAccountEvent>.account(user: user), fixture: name)
    case "spotState":
      try checkSubscription(PerpsSubscription<PerpsSpotEvent>.spotState(user: user), fixture: name)
    case "allDexsClearinghouseState":
      try checkSubscription(
        PerpsSubscription<PerpsAllDexsAccountEvent>.allAccounts(user: user), fixture: name)
    case "allDexsAssetCtxs":
      try checkSubscription(
        PerpsSubscription<PerpsAllDexsContextsEvent>.allContexts(), fixture: name)
    case "activeAssetData":
      try checkSubscription(
        PerpsSubscription<PerpsActiveAssetData>.activeAsset(user: user, coin: "BTC"), fixture: name)
    case "activeAssetCtx":
      try checkSubscription(
        PerpsSubscription<PerpsAssetContextEvent>.assetContext(coin: "BTC"), fixture: name)
    case "openOrders":
      try checkSubscription(
        PerpsSubscription<PerpsOpenOrdersEvent>.openOrders(user: user), fixture: name)
    case "orderUpdates":
      try checkSubscription(
        PerpsSubscription<[PerpsHistoricalOrder]>.orderUpdates(user: user), fixture: name)
    case "userFills":
      try checkSubscription(PerpsSubscription<PerpsFillsEvent>.fills(user: user), fixture: name)
    case "userTwapSliceFills":
      try checkSubscription(
        PerpsSubscription<PerpsTwapSliceEvent>.twapSlices(user: user), fixture: name)
    case "userTwapHistory":
      try checkSubscription(
        PerpsSubscription<PerpsTwapHistoryEvent>.twapHistory(user: user), fixture: name)
    case "twapStates":
      try checkSubscription(
        PerpsSubscription<PerpsTwapStatesEvent>.twapStates(user: user), fixture: name)
    case "allMids": try checkSubscription(PerpsSubscription<PerpsMidsEvent>.mids(), fixture: name)
    case "bbo": try checkSubscription(PerpsSubscription<PerpsBbo>.bbo(coin: "BTC"), fixture: name)
    case "trades":
      try checkSubscription(PerpsSubscription<[PerpsTrade]>.trades(coin: "BTC"), fixture: name)
    case "candle":
      try checkSubscription(
        PerpsSubscription<[PerpsCandle]>.candles(coin: "BTC", interval: .minute), fixture: name)
    case "l2Book":
      try checkSubscription(PerpsSubscription<PerpsBook>.book(coin: "BTC"), fixture: name)
    case "userFundings":
      try checkSubscription(
        PerpsSubscription<PerpsFundingsEvent>.funding(user: user), fixture: name)
    case "userNonFundingLedgerUpdates":
      try checkSubscription(PerpsSubscription<PerpsLedgerEvent>.ledger(user: user), fixture: name)
    case "user":
      try checkSubscription(
        PerpsSubscription<PerpsUserEvents>.userEvents(user: user), fixture: name)
    case "notification":
      try checkSubscription(
        PerpsSubscription<PerpsNotification>.notifications(user: user), fixture: name)
    case "webData3":
      try checkSubscription(PerpsSubscription<PerpsWebData3>.webData(user: user), fixture: name)
    case "fastAssetCtxs":
      try checkSubscription(PerpsSubscription<PerpsFastContexts>.fastContexts(), fixture: name)
    default: Issue.record("Unregistered subscription fixture")
    }
  }
  private func checkSubscription<Event>(_ subscription: PerpsSubscription<Event>, fixture: String)
    throws
  {
    try validatePerpsParameters(subscription.subscription.parameters)
    let data = try perpsFixture("ws-" + fixture)
    _ = try subscription.decode(data)
    let wrong = Data(
      String(decoding: data, as: UTF8.self).replacingOccurrences(
        of: "\"channel\":\"" + fixture + "\"", with: "\"channel\":\"wrong\""
      ).utf8)
    #expect(throws: (any Error).self) { try subscription.decode(wrong) }
  }
}

func perpsFixture(_ name: String) throws -> Data {
  #if SWIFT_PACKAGE
    let bundle = Bundle.module
  #else
    let bundle = Bundle(for: PerpsFixtureBundle.self)
  #endif
  guard let url = bundle.url(forResource: name, withExtension: "json") else {
    throw ValidationError.missingRequiredField(field: "fixture " + name)
  }
  return try Data(contentsOf: url)
}
private final class PerpsFixtureBundle: NSObject {}
