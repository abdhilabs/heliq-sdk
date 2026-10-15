//
//  PerpsFundedIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import Testing

@testable import HeliqSDK

@Suite(
  .serialized, .enabled(if: ProcessInfo.processInfo.environment["HELIQ_PERPS_FUNDED_TESTS"] == "1"))
struct PerpsFundedIntegrationTests {
  private let mainAddress = "0x444483eba5faa8a1499a4d2261c5e4e927b558cf"
  private let disposableAddress = "0x309ef1a1b1c9c0b2321213c1ffd2f74f8bdb8c93"

  @Test func standardSpotPerpsRoundTripAndTypedMultisigRecovery() async throws {
    let main = try await wallet("hyperliquid-testnet.key", address: mainAddress)
    let owner = try await wallet("hyperliquid-testnet-standard.key", address: disposableAddress)
    let second = try await wallet(
      "hyperliquid-testnet-recipient.key", address: "0xe39a25c15639680ca5c56de6514df00d44ca841d")
    let sdk = try client(owner)
    let funding = try client(main)
    let other = try client(second)
    let before = try await balance(funding, main.address)
    let initialMode = try await sdk.info.perps(.abstraction(address: owner.address))
    guard
      initialMode == .defaultMode || initialMode == .unifiedAccount
        || initialMode.supportsClassTransfer
    else {
      throw ValidationError.malformedData(
        reason: "Disposable account mode cannot be restored safely")
    }
    try await requireClean(sdk, owner.address)
    _ = try await funding.exchange.spotTransfer(toAddress: owner.address, amount: 2, asset: 0)
    let fundedSpot = try await balance(sdk, owner.address)
    var converted = false
    var movedToPerps = false
    do {
      _ = try await sdk.exchange.executePerps(
        .userAbstraction(address: owner.address, mode: .standard))
      _ = try await sdk.exchange.usdClassTransfer(amount: 1, toPerp: true)
      movedToPerps = true
      let separate = try await sdk.info.getBalances(address: owner.address)
      #expect(separate.abstraction.supportsClassTransfer)
      #expect(separate.perps[0].accountValue == 1)
      #expect(separate.spot.first { $0.token == 0 }?.total == fundedSpot - 1)
      _ = try await sdk.exchange.usdClassTransfer(amount: 1, toPerp: false)
      movedToPerps = false
      #expect(try await sdk.info.getBalances(address: owner.address).perps[0].accountValue == 0)
      print("PERPS FUNDED PASS: standard Spot -> Perps -> Spot with exact ledger balances")
      _ = try await sdk.exchange.executePerps(
        .userAbstraction(
          address: owner.address,
          mode: initialMode == .unifiedAccount ? .unifiedAccount : .standard))
      _ = try await sdk.exchange.executePerps(
        .convertMultisig(authorizedUsers: [main.address, second.address], threshold: 2))
      converted = true
      let failedNonce = await ExchangeNonceForPerpsTest.shared.next()
      let failedAction = PerpsAction.invalidateNonce(failedNonce)
      let failedPayload = try await funding.exchange.preparePerpsMultisig(
        action: failedAction,
        user: owner.address, leader: main.address, nonce: failedNonce, context: .init())
      let one = try await funding.exchange.signPerpsMultisig(failedPayload)
      do {
        _ = try await funding.exchange.executeMultisig(
          .init(payload: failedPayload, signatures: [one]))
        Issue.record("Multisig accepted fewer signatures than its threshold")
      } catch APIError.hyperliquidError(_, let message) {
        #expect(message == "Multi-sig threshold not met")
      }
      let nonce = await ExchangeNonceForPerpsTest.shared.next()
      let action = PerpsAction.invalidateNonce(nonce)
      let payload = try await funding.exchange.preparePerpsMultisig(
        action: action,
        user: owner.address, leader: main.address, nonce: nonce, context: .init())
      let a = try await funding.exchange.signPerpsMultisig(payload)
      let b = try await other.exchange.signPerpsMultisig(payload)
      _ = try await funding.exchange.executeMultisig(.init(payload: payload, signatures: [a, b]))
      print(
        "PERPS FUNDED PASS: typed L1 multisig threshold enforced and two-signature action accepted")
      try await restoreMultisig(owner: owner, first: funding, second: other)
      converted = false
      _ = try await sdk.exchange.executePerps(
        .invalidateNonce(await ExchangeNonceForPerpsTest.shared.next()))
      print(
        "PERPS FUNDED PASS: typed user-signed multisig recovery restores original owner signing")
    } catch {
      if converted { try await restoreMultisig(owner: owner, first: funding, second: other) }
      if movedToPerps { _ = try await sdk.exchange.usdClassTransfer(amount: 1, toPerp: false) }
      _ = try await sdk.exchange.executePerps(
        .userAbstraction(
          address: owner.address,
          mode: initialMode == .unifiedAccount ? .unifiedAccount : .standard))
      try await returnFunds(sdk, owner: owner.address, destination: main.address)
      throw error
    }
    try await returnFunds(sdk, owner: owner.address, destination: main.address)
    try await requireClean(sdk, owner.address)
    #expect(try await balance(sdk, owner.address) == 0)
    #expect(before - (try await balance(funding, main.address)) <= 5)
    #expect(try await funding.info.perps(.abstraction(address: main.address)) == .unifiedAccount)
  }

  @Test func boundedAdvancedTradingLifecycleAndMarginRestoration() async throws {
    let main = try await wallet("hyperliquid-testnet.key", address: mainAddress)
    let sdk = try client(main)
    try await requireClean(sdk, main.address)
    let initialBalance = try await balance(sdk, main.address)
    let initial = try await sdk.info.getActiveAssetData(address: main.address, coin: "BTC")
    let meta = try await sdk.info.perps(.meta())
    let btc = try #require(meta.universe.first { $0.name == "BTC" })
    let mid = try #require(try await sdk.info.perps(.mids())["BTC"])
    var scaled = 20 / mid
    var rounded = Decimal()
    NSDecimalRound(&rounded, &scaled, btc.szDecimals, .up)
    let size = rounded
    let price = roundedPerpsPrice(mid * Decimal(string: "0.7")!, decimals: btc.szDecimals)
    let twapID: Int64? = nil
    do {
      let placed = try await sdk.exchange.executePerps(
        .orders([
          .init(market: .coin("BTC"), side: .buy, size: size, price: price, kind: .limit(.alo))
        ]))
      let id = try resting(placed)
      #expect(
        try await sdk.info.perps(.openOrders(address: main.address)).contains { $0.oid == id })
      let replacement = try await sdk.exchange.executePerps(
        .modifyOrder(
          .init(
            identifier: .orderID(id),
            order: .init(market: .coin("BTC"), side: .buy, size: size, price: price - 100))))
      guard case .success = replacement else { throw APIError.invalidResponse }
      let open = try await sdk.info.perps(.openOrders(address: main.address))
      guard open.count == 1, open[0].limitPx == price - 100 else { throw APIError.invalidResponse }
      let replacementID = open[0].oid
      let canceled = try await sdk.exchange.executePerps(
        .cancel([.init(market: .coin("BTC"), identifier: .orderID(replacementID))]))
      guard case .cancellations(let results) = canceled, case .success = results[0] else {
        throw APIError.invalidResponse
      }
      print("PERPS FUNDED PASS: metadata-based Alo order, single modification, typed cancellation")
      _ = try await sdk.exchange.executePerps(
        .leverage(market: .coin("BTC"), value: 2, cross: false))
      let opened = try await sdk.exchange.executePerps(
        .orders([.init(market: .coin("BTC"), side: .buy, size: size, kind: .market())]))
      try requireFilled(opened)
      let position = try #require(
        try await sdk.info.perps(.account(address: main.address)).assetPositions.first?.position)
      let oldMargin = try #require(position.leverage.rawUsd)
      _ = try await sdk.exchange.executePerps(.isolatedMargin(market: .coin("BTC"), amount: 1))
      let increased = try #require(
        try await sdk.info.perps(.account(address: main.address)).assetPositions.first?.position
          .leverage.rawUsd)
      #expect(increased == oldMargin + 1)
      _ = try await sdk.exchange.executePerps(
        .isolatedMargin(market: .coin("BTC"), amount: Decimal(string: "-0.5")!))
      let reduced = try #require(
        try await sdk.info.perps(.account(address: main.address)).assetPositions.first?.position
          .leverage.rawUsd)
      #expect(reduced == oldMargin + Decimal(string: "0.5")!)
      print("PERPS FUNDED PASS: market open and exact isolated margin add/remove")
      let tp = roundedPerpsPrice(mid * Decimal(string: "1.2")!, decimals: btc.szDecimals)
      let sl = roundedPerpsPrice(mid * Decimal(string: "0.8")!, decimals: btc.szDecimals)
      let protective = try await sdk.exchange.executePerps(
        .orders(
          [
            .init(
              market: .coin("BTC"), side: .sell, size: abs(position.szi),
              kind: .trigger(price: tp, kind: .takeProfit, market: true), reduceOnly: true),
            .init(
              market: .coin("BTC"), side: .sell, size: abs(position.szi),
              kind: .trigger(price: sl, kind: .stopLoss, market: true), reduceOnly: true),
          ], grouping: .positionTpsl))
      try requireAccepted(protective)
      let triggerOrders = try await sdk.info.perps(.frontendOpenOrders(address: main.address))
        .filter { $0.isTrigger == true }
      #expect(triggerOrders.count == 2)
      _ = try await sdk.exchange.executePerps(
        .cancel(triggerOrders.map { .init(market: .coin("BTC"), identifier: .orderID($0.oid)) }))
      print("PERPS FUNDED PASS: position TP/SL grouping and trigger cancellations")
      do {
        let trailing = try await sdk.exchange.executePerps(
          .trailingStop(
            market: .coin("BTC"), side: .sell,
            size: abs(position.szi), reduceOnly: true, retracement: .percent(1),
            activationPrice: nil))
        guard case .trailingStop(let id) = trailing else { throw APIError.invalidResponse }
        _ = try await sdk.exchange.executePerps(
          .cancel([.init(market: .coin("BTC"), identifier: .orderID(id))]))
        print("PERPS FUNDED PASS: trailing stop placed and canceled")
      } catch {
        Issue.record("Trailing stop unavailable/rejected: \(error)")
        print("PERPS FUNDED BLOCKED: trailing stop: \(error)")
      }
      try requireFilled(try await sdk.exchange.executePerps(.marketClose(market: .coin("BTC"))))
      print("PERPS FUNDED PASS: reduce-only typed market close")

    } catch {
      try await cleanup(sdk, address: main.address, initial: initial, twapID: twapID)
      throw error
    }
    try await cleanup(sdk, address: main.address, initial: initial, twapID: twapID)
    #expect(initialBalance - (try await balance(sdk, main.address)) <= 5)
    print(
      "PERPS FUNDED PASS: no remaining orders/positions; original leverage and mode restored; cost within 5 USDC"
    )
  }

  @Test func boundedTwapPlacementAndCancellation() async throws {
    let main = try await wallet("hyperliquid-testnet.key", address: mainAddress)
    let sdk = try client(main)
    try await requireClean(sdk, main.address)
    let before = try await balance(sdk, main.address)
    let initial = try await sdk.info.getActiveAssetData(address: main.address, coin: "BTC")
    let btc = try #require(try await sdk.info.perps(.meta()).universe.first { $0.name == "BTC" })
    let mid = try #require(try await sdk.info.perps(.mids())["BTC"])
    // Testnet enforces a $100 TWAP minimum; a buffer covers small price movement.
    var amount = 110 / mid
    var size = Decimal()
    NSDecimalRound(&size, &amount, btc.szDecimals, .up)
    var id: Int64?
    do {
      let result = try await sdk.exchange.executePerps(
        .twap(
          market: .coin("BTC"), side: .buy,
          size: size, minutes: 5, reduceOnly: false, randomize: false))
      guard case .twap(let placedID) = result else { throw APIError.invalidResponse }
      id = placedID
      _ = try await sdk.exchange.executePerps(.cancelTwap(market: .coin("BTC"), id: placedID))
      id = nil
      print("PERPS FUNDED PASS: TWAP placed at valid notional and canceled")
    } catch {
      try await cleanup(sdk, address: main.address, initial: initial, twapID: id)
      throw error
    }
    try await cleanup(sdk, address: main.address, initial: initial, twapID: id)
    #expect(before - (try await balance(sdk, main.address)) <= 5)
  }

  @Test(.enabled(if: ProcessInfo.processInfo.environment["HELIQ_PERPS_UI_FUNDING_PHASE"] != nil))
  func standardSimulatorFundingAndCleanup() async throws {
    let main = try await wallet("hyperliquid-testnet.key", address: mainAddress)
    let owner = try await wallet("hyperliquid-testnet-standard.key", address: disposableAddress)
    let funding = try client(main)
    let sdk = try client(owner)
    let tokens = try await sdk.info.perps(.spotMeta()).tokens
    let token = try #require(tokens.first { $0.index == 0 })
    let identifier = token.name + ":" + token.tokenId
    if ProcessInfo.processInfo.environment["HELIQ_PERPS_UI_FUNDING_PHASE"] == "prepare" {
      try await requireClean(sdk, owner.address)
      #expect(try await sdk.info.perps(.abstraction(address: owner.address)).supportsClassTransfer)
      guard try await balance(sdk, owner.address) == 0 else { throw APIError.invalidResponse }
      _ = try await funding.exchange.sendAsset(
        destination: owner.address, source: .spot,
        destinationLedger: .spot, token: identifier, amount: 1)
      #expect(try await balance(sdk, owner.address) == 1)
      print("PERPS UI PREPARED: one test USDC at the dedicated standard-mode wallet")
    } else {
      try await requireClean(sdk, owner.address)
      let state = try await sdk.info.perps(.account(address: owner.address))
      if state.marginSummary.accountValue > 0 {
        _ = try await sdk.exchange.usdClassTransfer(
          amount: state.marginSummary.accountValue, toPerp: false)
      }
      let available = try await balance(sdk, owner.address)
      if available > 0 {
        _ = try await sdk.exchange.sendAsset(
          destination: main.address, source: .spot,
          destinationLedger: .spot, token: identifier, amount: available)
      }
      #expect(try await balance(sdk, owner.address) == 0)
      #expect(
        try await sdk.info.perps(.account(address: owner.address)).marginSummary.accountValue == 0)
      print("PERPS UI CLEANUP PASS: standard-wallet funds returned using typed sendAsset")
    }
  }

  private func wallet(_ file: String, address: String) async throws -> WalletService {
    let key = try String(contentsOfFile: ".local/" + file, encoding: .utf8).trimmingCharacters(
      in: .whitespacesAndNewlines)
    let value = try await WalletService(keyManager: KeyManager(privateKey: key))
    guard value.address == address else { throw SigningError.keyNotFound }
    return value
  }
  private func client(_ wallet: WalletService) throws -> HeliqClient {
    try HeliqClient.Builder().environment(.testnet).wallet(wallet).build()
  }
  private func balance(_ sdk: HeliqClient, _ address: String) async throws -> Decimal {
    try await sdk.info.perps(.spotState(address: address)).balances.first { $0.token == 0 }?.total
      ?? 0
  }
  private func requireClean(_ sdk: HeliqClient, _ address: String) async throws {
    guard try await sdk.info.perps(.openOrders(address: address)).isEmpty,
      try await sdk.info.perps(.account(address: address)).assetPositions.isEmpty
    else {
      throw ValidationError.malformedData(
        reason: "Live tests require no existing orders or positions")
    }
  }
  private func restoreMultisig(owner: WalletService, first: HeliqClient, second: HeliqClient)
    async throws
  {
    let nonce = await ExchangeNonceForPerpsTest.shared.next()
    let leader = mainAddress
    let payload = try await first.exchange.preparePerpsMultisig(
      action: .restoreNormalAccount,
      user: owner.address, leader: leader, nonce: nonce, context: .init())
    let a = try await first.exchange.signPerpsMultisig(payload)
    let b = try await second.exchange.signPerpsMultisig(payload)
    _ = try await first.exchange.executeMultisig(.init(payload: payload, signatures: [a, b]))
  }
  private func returnFunds(_ sdk: HeliqClient, owner: String, destination: String) async throws {
    let available = try await balance(sdk, owner)
    if available > 0 {
      _ = try await sdk.exchange.spotTransfer(
        toAddress: destination,
        amount: NSDecimalNumber(decimal: available).doubleValue, asset: 0)
    }
  }
  private func resting(_ result: PerpsActionResult) throws -> Int64 {
    try requireAccepted(result)
    guard case .orders(let statuses) = result, statuses.count == 1,
      case .resting(let id) = statuses[0]
    else { throw APIError.invalidResponse }
    return id
  }
  private func requireAccepted(_ result: PerpsActionResult) throws {
    guard case .orders(let statuses) = result, !statuses.isEmpty else {
      throw APIError.invalidResponse
    }
    for status in statuses {
      if case .rejected(let error) = status {
        throw APIError.hyperliquidError(code: 0, message: error)
      }
    }
  }
  private func requireFilled(_ result: PerpsActionResult) throws {
    try requireAccepted(result)
    guard case .orders(let statuses) = result, statuses.count == 1, case .filled = statuses[0]
    else { throw APIError.invalidResponse }
  }
  private func cleanup(
    _ sdk: HeliqClient, address: String, initial: PerpsActiveAssetData, twapID: Int64?
  ) async throws {
    if let twapID {
      _ = try await sdk.exchange.executePerps(.cancelTwap(market: .coin("BTC"), id: twapID))
    }
    _ = try await sdk.exchange.cancelAll()
    if try await !sdk.info.perps(.account(address: address)).assetPositions.isEmpty {
      try requireFilled(try await sdk.exchange.executePerps(.marketClose(market: .coin("BTC"))))
    }
    _ = try await sdk.exchange.executePerps(
      .leverage(
        market: .coin("BTC"), value: initial.leverage.value, cross: initial.leverage.type == "cross"
      ))
    try await requireClean(sdk, address)
  }
}
private actor ExchangeNonceForPerpsTest {
  static let shared = ExchangeNonceForPerpsTest()
  private var value: Int64 = 0
  func next() -> Int64 {
    value = max(value + 1, Int64(Date().timeIntervalSince1970 * 1000))
    return value
  }
}
