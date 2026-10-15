//
//  PerpsReadIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import Testing

@testable import HeliqSDK

@Suite(
  .serialized, .enabled(if: ProcessInfo.processInfo.environment["HELIQ_PERPS_READ_TESTS"] == "1"))
struct PerpsReadIntegrationTests {
  @Test func currentOfficialSchemasAndBalanceSemantics() async throws {
    let sdk = try HeliqClient.Builder().environment(.testnet).build()
    let address = "0x444483eba5faa8a1499a4d2261c5e4e927b558cf"
    let page = HyperliquidPageRequest(startTime: Date().addingTimeInterval(-86400))
    let checks: [(String, @Sendable () async throws -> Void)] = [
      (
        "balances",
        {
          let b = try await sdk.info.getBalances(address: address)
          #expect(b.hasSharedCollateral)
          #expect(b.perps[0].accountValue == nil)
          #expect(b.spot.first { $0.token == 0 }?.availableAfterMaintenance != nil)
        }
      ),
      (
        "activeAssetData",
        { _ = try await sdk.info.getActiveAssetData(address: address, coin: "BTC") }
      ),
      ("perpDexs", { _ = try await sdk.info.perps(.dexs()) }),
      ("meta", { _ = try await sdk.info.perps(.meta()) }),
      ("metaAndAssetCtxs", { _ = try await sdk.info.perps(.metaAndContexts()) }),
      ("allPerpMetas", { _ = try await sdk.info.perps(.allMetas()) }),
      ("clearinghouseState", { _ = try await sdk.info.perps(.account(address: address)) }),
      ("spotClearinghouseState", { _ = try await sdk.info.perps(.spotState(address: address)) }),
      (
        "fundingHistory", { _ = try await sdk.info.perps(.fundingHistory(coin: "BTC", page: page)) }
      ),
      ("predictedFundings", { _ = try await sdk.info.perps(.predictedFunding()) }),
      ("perpsAtOpenInterestCap", { _ = try await sdk.info.perps(.openInterestCaps()) }),
      ("perpDeployAuctionStatus", { _ = try await sdk.info.perps(.deployAuction()) }),
      ("perpDexLimits", { _ = try await sdk.info.perps(.dexLimits(dex: "test")) }),
      ("perpDexStatus", { _ = try await sdk.info.perps(.dexStatus()) }),
      ("perpAnnotation", { _ = try await sdk.info.perps(.annotation(coin: "BTC")) }),
      ("perpCategories", { _ = try await sdk.info.perps(.categories()) }),
      ("perpConciseAnnotations", { _ = try await sdk.info.perps(.conciseAnnotations()) }),
      ("openOrders", { _ = try await sdk.info.perps(.openOrders(address: address)) }),
      (
        "frontendOpenOrders",
        { _ = try await sdk.info.perps(.frontendOpenOrders(address: address)) }
      ),
      ("historicalOrders", { _ = try await sdk.info.perps(.historicalOrders(address: address)) }),
      ("userFills", { _ = try await sdk.info.perps(.fills(address: address)) }),
      (
        "userFillsByTime",
        { _ = try await sdk.info.perps(.fillsByTime(address: address, page: page)) }
      ),
      ("userRateLimit", { _ = try await sdk.info.perps(.rateLimit(address: address)) }),
      ("userFees", { _ = try await sdk.info.perps(.fees(address: address)) }),
      ("userTwapSliceFills", { _ = try await sdk.info.perps(.twapSliceFills(address: address)) }),
      ("userRole", { _ = try await sdk.info.perps(.role(address: address)) }),
      ("subAccounts", { _ = try await sdk.info.perps(.subAccounts(address: address)) }),
      ("extraAgents", { _ = try await sdk.info.perps(.agents(address: address)) }),
      ("approvedBuilders", { _ = try await sdk.info.perps(.approvedBuilders(address: address)) }),
      (
        "maxBuilderFee",
        {
          _ = try await sdk.info.perps(
            .builderFee(address: address, builder: "0xe39a25c15639680ca5c56de6514df00d44ca841d"))
        }
      ),
      ("orderStatus", { _ = try await sdk.info.perps(.orderStatus(address: address, orderID: 1)) }),
      ("userFunding", { _ = try await sdk.info.perps(.userFunding(address: address, page: page)) }),
      (
        "userNonFundingLedgerUpdates",
        { _ = try await sdk.info.perps(.ledger(address: address, page: page)) }
      ),
      ("portfolio", { _ = try await sdk.info.perps(.portfolio(address: address)) }),
      ("borrowLendUserState", { _ = try await sdk.info.perps(.borrowLendUser(address: address)) }),
      ("allMids", { _ = try await sdk.info.perps(.mids()) }),
      ("userAbstraction", { _ = try await sdk.info.perps(.abstraction(address: address)) }),
      ("vaultDetails", { _ = try await sdk.info.perps(.vaultDetails(address: address)) }),
      ("userVaultEquities", { _ = try await sdk.info.perps(.vaultEquities(address: address)) }),
      ("referral", { _ = try await sdk.info.perps(.referral(address: address)) }),
      ("spotMeta", { _ = try await sdk.info.perps(.spotMeta()) }),
      ("borrowLendReserveState", { _ = try await sdk.info.perps(.borrowReserve(token: 0)) }),
      ("allBorrowLendReserveStates", { _ = try await sdk.info.perps(.borrowReserves()) }),
      ("l2Book", { _ = try await sdk.info.perps(.book(coin: "BTC")) }),
      (
        "candleSnapshot",
        {
          _ = try await sdk.info.perps(.candles(coin: "BTC", interval: .fifteenMinutes, page: page))
        }
      ),
      (
        "userDexAbstraction",
        { _ = try await sdk.info.perps(.legacyDexAbstraction(address: address)) }
      ),
    ]
    for (name, check) in checks {
      do {
        try await check()
        print("PERPS READ PASS: \(name)")
      } catch {
        Issue.record("\(name): \(error)")
        print("PERPS READ FAIL: \(name): \(error)")
      }
    }
  }
}
