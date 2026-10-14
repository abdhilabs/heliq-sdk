//
//  FundedTradingIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import Testing

@testable import HeliqSDK

@Suite(
  .serialized,
  .enabled(if: ProcessInfo.processInfo.environment["HELIQ_FUNDED_TRADING_TESTS"] == "1"))
struct FundedTradingIntegrationTests {
  private let expectedAddress = "0x444483eba5faa8a1499a4d2261c5e4e927b558cf"

  @Test func fundedOrderLifecycleAndPositionSettings() async throws {
    let keyURL = URL(
      fileURLWithPath: ProcessInfo.processInfo.environment["HELIQ_TESTNET_KEY_FILE"]
        ?? ".local/hyperliquid-testnet.key")
    let key = try String(contentsOf: keyURL, encoding: .utf8).trimmingCharacters(
      in: .whitespacesAndNewlines)
    let wallet = try await WalletService(keyManager: KeyManager(privateKey: key))
    guard wallet.address == expectedAddress else {
      throw ValidationError.malformedData(reason: "Unexpected funded test wallet")
    }
    let client = try HeliqClient.Builder().environment(.testnet).wallet(wallet).build()
    guard try await client.raw.openOrders(user: wallet.address).isEmpty,
      try await client.info.getUserState(address: wallet.address).assetPositions.isEmpty
    else {
      throw ValidationError.malformedData(
        reason: "Funded tests require an account with no orders or positions")
    }
    let metadata = try await client.info.getMeta()
    let btc = try #require(metadata.universe.first { $0.name == "BTC" })
    let initial = try await leverage(client: client, address: wallet.address)
    let abstraction = try await client.raw.info(
      .init(type: .custom("userAbstraction"), parameters: ["user": .string(wallet.address)]))
    let unified =
      abstraction == .string("unifiedAccount") || abstraction == .string("portfolioMargin")
    var moved = false
    do {
      if !unified {
        try await classTransfer(client: client, wallet: wallet, amount: "100", toPerp: true)
        moved = true
        #expect(try await client.info.getUserState(address: wallet.address).marginTotal >= 100)
        print("FUNDED PASS: Spot -> Perps, 100 USDC")
      } else {
        print("FUNDED INFO: unified collateral; no class transfer required")
      }
      #expect(try await client.exchange.setLeverage(asset: btc.asset, leverage: 2).status == "ok")
      #expect(try await leverage(client: client, address: wallet.address).value == 2)
      #expect(
        try await client.exchange.setMarginMode(asset: btc.asset, mode: .isolated).status == "ok")
      #expect(try await leverage(client: client, address: wallet.address).type == "isolated")
      #expect(
        try await client.exchange.setMarginMode(asset: btc.asset, mode: .cross).status == "ok")
      print("FUNDED PASS: leverage, isolated margin, cross margin")

      let mid = try #require(try await client.info.getAllMids().prices["BTC"])
      let scale = pow(10.0, Double(btc.szDecimals))
      let size = ceil(20 / mid * scale) / scale
      let price = floor(mid * 0.7 / 100) * 100
      let firstID = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
      let cloid = "0x" + firstID
      let placed = try await client.exchange.placeOrder(
        .init(
          asset: btc.asset, side: .buy, orderType: .limit, size: size, price: price, cloid: cloid))
      guard placed.status == "resting", let oid = placed.orderId else {
        throw APIError.invalidResponse
      }
      #expect(
        try await client.raw.openOrders(user: wallet.address).contains { String($0.orderID) == oid }
      )
      print("FUNDED PASS: limit order resting, oid=\(oid)")
      let modified = try await client.exchange.modifyOrder(
        orderId: oid, asset: btc.asset, size: size, price: price - 100)
      let replacementID = try #require(modified.orderId)
      #expect(modified.status == "resting")
      #expect(try await client.raw.openOrders(user: wallet.address).contains {
        String($0.orderID) == replacementID
      })
      let cloidModified = try await client.exchange.modifyByCloid(
        cloid: cloid, asset: btc.asset, size: size, price: price - 200)
      #expect(cloidModified.status == "resting")
      #expect(try await client.exchange.cancelByCloid(cloid: cloid, asset: btc.asset).error == nil)
      print("FUNDED PASS: modify by order ID/client ID and cancel by client ID")

      let bulk = try await client.exchange.bulkOrders([
        .init(asset: btc.asset, side: .buy, orderType: .limit, size: size, price: price),
        .init(asset: btc.asset, side: .buy, orderType: .limit, size: size, price: price - 100),
      ])
      guard bulk.responses.count == 2,
        bulk.responses.allSatisfy({ $0.status == "resting" && $0.error == nil })
      else { throw APIError.invalidResponse }
      let bulkID = try #require(bulk.responses.first?.orderId)
      #expect(try await client.exchange.cancelOrder(orderId: bulkID, asset: btc.asset).error == nil)
      let cancelled = try await client.exchange.cancelAll()
      #expect(cancelled.cancelledOrders.count == 1 && cancelled.failedCancels.isEmpty)
      #expect(try await client.raw.openOrders(user: wallet.address).isEmpty)
      print("FUNDED PASS: bulk orders, cancel by order ID, cancel all")

      let opened = try await client.exchange.placeOrder(
        .init(asset: btc.asset, side: .buy, orderType: .market, size: size))
      guard opened.status == "filled" else { throw APIError.invalidResponse }
      let position = try #require(
        try await client.info.getUserState(address: wallet.address).assetPositions.first {
          $0.asset == btc.asset
        })
      #expect(position.positionSize > 0)
      let closed = try await client.exchange.placeOrder(
        .init(
          asset: btc.asset, side: .sell, orderType: .market, size: position.positionSize,
          reduceOnly: true))
      guard closed.status == "filled" else { throw APIError.invalidResponse }
      #expect(try await client.info.getUserState(address: wallet.address).assetPositions.isEmpty)
      print("FUNDED PASS: market buy filled, reduce-only market close filled")
    } catch {
      try await cleanup(
        client: client, wallet: wallet, asset: btc.asset, initial: initial, moved: moved)
      throw error
    }
    try await cleanup(
      client: client, wallet: wallet, asset: btc.asset, initial: initial, moved: moved)
    print(
      "FUNDED PASS: no remaining orders/positions; settings restored; any separate Perps collateral returned to Spot"
    )
  }

  @Test func fundedTransfersBetweenOwnedWallets() async throws {
    let main = try await storedWallet(".local/hyperliquid-testnet.key")
    let recipient = try await storedWallet(".local/hyperliquid-testnet-recipient.key")
    guard main.address == expectedAddress,
      recipient.address == "0xe39a25c15639680ca5c56de6514df00d44ca841d"
    else { throw SigningError.invalidPrivateKey }
    let sender = try HeliqClient.Builder().environment(.testnet).wallet(main).build()
    let receiver = try HeliqClient.Builder().environment(.testnet).wallet(recipient).build()
    do {
      #expect(
        try await sender.exchange.spotTransfer(toAddress: recipient.address, amount: 5, asset: 0)
          .status == "ok")
      #expect(try await receiver.info.getSpotUserState(address: recipient.address).totalUsdc >= 4)
      print("FUNDED PASS: spot USDC transfer confirmed at owned recipient")
      var before = try await totalUsdc(client: receiver, address: recipient.address)
      #expect(
        try await sender.exchange.usdSend(destination: recipient.address, amount: 5).status == "ok")
      #expect(
        abs(try await totalUsdc(client: receiver, address: recipient.address) - before - 5)
          < 0.000001)
      print("FUNDED PASS: USD send")
      before = try await totalUsdc(client: receiver, address: recipient.address)
      #expect(
        try await sender.exchange.sendToAddress(address: recipient.address, amount: 5, asset: 0)
          .status == "ok")
      #expect(
        abs(try await totalUsdc(client: receiver, address: recipient.address) - before - 5)
          < 0.000001)
      print("FUNDED PASS: send to address")
      before = try await totalUsdc(client: receiver, address: recipient.address)
      #expect(
        try await sender.exchange.transfer(
          fromAddress: main.address, toAddress: recipient.address, amount: 5, asset: 0
        ).status == "ok")
      #expect(
        abs(try await totalUsdc(client: receiver, address: recipient.address) - before - 5)
          < 0.000001)
      print("FUNDED PASS: transfer")
    } catch {
      try await returnFunds(client: receiver, wallet: recipient, destination: main.address)
      throw error
    }
    try await returnFunds(client: receiver, wallet: recipient, destination: main.address)
    print("FUNDED PASS: recipient funds returned to prepared wallet")
  }

  @Test(.enabled(if: ProcessInfo.processInfo.environment["HELIQ_APPROVED_ACCOUNT_TESTS"] == "1"))
  func fundedApprovedScheduleAndZeroFeeBuilderChecks() async throws {
    let wallet = try await storedWallet(".local/hyperliquid-testnet.key")
    guard wallet.address == expectedAddress else { throw SigningError.invalidPrivateKey }
    let client = try HeliqClient.Builder().environment(.testnet).wallet(wallet).build()
    guard try await client.raw.openOrders(user: wallet.address).isEmpty else {
      throw APIError.invalidResponse
    }
    let meta = try #require(try await client.info.getMeta().universe.first { $0.name == "BTC" })
    let mid = try #require(try await client.info.getAllMids().prices["BTC"])
    let scale = pow(10.0, Double(meta.szDecimals))
    let order = try await client.exchange.placeOrder(
      .init(
        asset: meta.asset, side: .buy, orderType: .limit, size: ceil(20 / mid * scale) / scale,
        price: floor(mid * 0.7 / 100) * 100))
    let oid = try #require(order.orderId)
    do {
      #expect(
        try await client.exchange.scheduleCancel(time: Date().addingTimeInterval(6)).status == "ok")
      try await Task.sleep(for: .seconds(7))
      #expect(try await client.raw.openOrders(user: wallet.address).isEmpty)
      #expect(
        try await client.raw.orderStatus(user: wallet.address, oid: Int64(oid)!).status
          == "canceled")
      print("FUNDED PASS: scheduled cancellation triggered and canceled test order")
    } catch {
      _ = try await client.exchange.cancelAll()
      Issue.record("Schedule cancellation rejected: \(error)")
      print("FUNDED BLOCKED: schedule cancellation: \(error)")
    }
    do {
      #expect(
        try await client.exchange.updateBuilder(
          builderAddress: "0xe39a25c15639680ca5c56de6514df00d44ca841d", maxFeeRate: "0%"
        ).status == "ok")
      #expect(
        try await client.info.fetchBuilderFee(
          builderAddress: "0xe39a25c15639680ca5c56de6514df00d44ca841d", address: wallet.address
        ).feeBps == 0)
      print("FUNDED PASS: zero-fee builder approval confirmed")
    } catch {
      Issue.record("Builder approval rejected: \(error)")
      print("FUNDED BLOCKED: builder approval: \(error)")
    }
  }

  @Test func testnetReferralCandidate() async throws {
    let wallet = try await storedWallet(".local/hyperliquid-testnet-recipient.key")
    guard wallet.address == "0xe39a25c15639680ca5c56de6514df00d44ca841d" else {
      throw APIError.invalidResponse
    }
    let client = try HeliqClient.Builder().environment(.testnet).wallet(wallet).build()
    do {
      _ = try await client.exchange.setReferrer(referrer: "TESTNET")
      let state = try await client.raw.info(
        .init(type: .referral, parameters: ["user": .string(wallet.address)]))
      guard case .object(let object) = state,
        case .object(let referred)? = object["referredBy"]
      else {
        throw APIError.invalidResponse
      }
      #expect(referred["code"] == .string("TESTNET"))
      print("FUNDED PASS: secondary wallet referral TESTNET confirmed")
    } catch {
      Issue.record("Live referral candidate rejected: \(error)")
      print("FUNDED BLOCKED: referral TESTNET: \(error)")
    }
  }

  @Test func disposableMultisigThresholdAndRecovery() async throws {
    let owner = try await storedWallet(".local/hyperliquid-testnet-multisig.key")
    let first = try await storedWallet(".local/hyperliquid-testnet.key")
    let second = try await storedWallet(".local/hyperliquid-testnet-recipient.key")
    guard owner.address == "0x0bc576fe7da3dc9f1e90223f658dcb9245247e59",
      first.address == expectedAddress,
      second.address == "0xe39a25c15639680ca5c56de6514df00d44ca841d"
    else {
      throw APIError.invalidResponse
    }
    let client = try HeliqClient.Builder().environment(.testnet).wallet(owner).build()
    let funding = try HeliqClient.Builder().environment(.testnet).wallet(first).build()
    // A separate account keeps conversion and recovery away from the trading wallet.
    _ = try await funding.exchange.spotTransfer(toAddress: owner.address, amount: 2, asset: 0)
    var converted = false
    do {
      // Build both recovery signatures before converting the account.
      let prepared = try await multisigRecovery(
        owner: owner.address,
        signers: [first, second])
      #expect(
        try await client.exchange.convertToMultiSigUser(
          authorizedUsers: [first.address, second.address], threshold: 2
        ).status == "ok")
      converted = true
      let one = try await multisigRecovery(
        owner: owner.address,
        signers: [first])
      let rejected = try await client.raw.exchange(one)
      guard case .object(let rejection) = rejected, rejection["status"] == .string("err") else {
        throw APIError.invalidResponse
      }
      guard case .string(let reason)? = rejection["response"],
        reason == "Multi-sig threshold not met" else {
        throw APIError.invalidResponse
      }
      print("FUNDED INFO: one-signature rejection: \(reason)")
      print("FUNDED PASS: multisig rejects one of two required signatures")
      let restored = try await client.raw.exchange(prepared)
      guard case .object(let response) = restored, response["status"] == .string("ok") else {
        throw APIError.invalidResponse
      }
      converted = false
      let role = try await client.raw.info(
        .init(type: .userRole, parameters: ["user": .string(owner.address)]))
      guard case .object(let state) = role, state["role"] == .string("user") else {
        throw APIError.invalidResponse
      }
      print("FUNDED PASS: multisig accepts two signatures and restores normal user")
      try await returnFunds(client: client, wallet: owner, destination: first.address)
    } catch {
      if converted {
        let recovery = try await multisigRecovery(
          owner: owner.address,
          signers: [first, second])
        let result = try await client.raw.exchange(recovery)
        guard case .object(let object) = result, object["status"] == .string("ok") else {
          Issue.record("Disposable account recovery failed: \(result)")
          throw error
        }
      }
      try await returnFunds(client: client, wallet: owner, destination: first.address)
      throw error
    }
  }

  private func multisigRecovery(owner: String, signers: [WalletService])
    async throws -> HyperliquidExchangeEnvelope
  {
    let leader = signers[0]
    let nonce = Int64(Date().timeIntervalSince1970 * 1000)
    let inner: [String: JSONValue] = [
      "type": .string("convertToMultiSigUser"), "signatureChainId": .string("0x66eee"),
      "hyperliquidChain": .string("Testnet"), "signers": .string("null"),
      "nonce": .number(Double(nonce)),
    ]
    var enriched = inner
    enriched["payloadMultiSigUser"] = .string(owner)
    enriched["outerSigner"] = .string(leader.address)
    var signatures: [CanonicalMessagePack.Value] = []
    for signer in signers {
      let signature = try await signer.signUserSigned(
        primaryType: "HyperliquidTransaction:ConvertToMultiSigUser",
        fields: [
          .init(name: "hyperliquidChain", type: "string"),
          .init(name: "payloadMultiSigUser", type: "address"),
          .init(name: "outerSigner", type: "address"), .init(name: "signers", type: "string"),
          .init(name: "nonce", type: "uint64"),
        ], action: enriched, isMainnet: false)
      signatures.append(
        .object(
          .init([
            ("r", .string(signature.r)),
            ("s", .string(signature.s)), ("v", .number(Double(signature.v))),
          ])))
    }
    let payload = CanonicalMessagePack.Object([
      ("multiSigUser", .string(owner)), ("outerSigner", .string(leader.address)),
      (
        "action",
        .object(
          .init([
            ("type", .string("convertToMultiSigUser")),
            ("signatureChainId", .string("0x66eee")), ("hyperliquidChain", .string("Testnet")),
            ("signers", .string("null")), ("nonce", .number(Double(nonce))),
          ]))
      ),
    ])
    let unsigned = CanonicalMessagePack.Object([
      ("signatureChainId", .string("0x66eee")),
      ("signatures", .array(signatures)), ("payload", .object(payload)),
    ])
    let hash = try Signer.actionHash(action: unsigned, nonce: nonce)
    let hashHex = "0x" + hash.map { String(format: "%02x", $0) }.joined()
    let signature = try await leader.signUserSigned(
      primaryType: "HyperliquidTransaction:SendMultiSig",
      fields: [
        .init(name: "hyperliquidChain", type: "string"),
        .init(name: "multiSigActionHash", type: "bytes32"), .init(name: "nonce", type: "uint64"),
      ],
      action: [
        "hyperliquidChain": .string("Testnet"), "signatureChainId": .string("0x66eee"),
        "multiSigActionHash": .string(hashHex), "nonce": .number(Double(nonce)),
      ], isMainnet: false)
    return .init(
      action: .init(type: .multiSig, parameters: CanonicalMessagePack.json(unsigned)),
      nonce: nonce, signature: signature)
  }

  private func totalUsdc(client: HeliqClient, address: String) async throws -> Double {
    let spot = try await client.info.getSpotUserState(address: address).totalUsdc
    let perps = try await client.info.getUserState(address: address).marginTotal
    return spot + perps
  }

  private func storedWallet(_ path: String) async throws -> WalletService {
    let key = try String(contentsOfFile: path, encoding: .utf8).trimmingCharacters(
      in: .whitespacesAndNewlines)
    return try await WalletService(keyManager: KeyManager(privateKey: key))
  }

  private func returnFunds(client: HeliqClient, wallet: WalletService, destination: String)
    async throws
  {
    let spot = try await client.info.getSpotUserState(address: wallet.address).totalUsdc
    if spot > 0 {
      _ = try await client.exchange.spotTransfer(toAddress: destination, amount: spot, asset: 0)
    }
    let perps = try await client.info.getUserState(address: wallet.address).marginTotal
    if perps > 0 { _ = try await client.exchange.usdSend(destination: destination, amount: perps) }
  }

  private struct Leverage: Decodable {
    let type: String
    let value: Int
  }

  private func leverage(client: HeliqClient, address: String) async throws -> Leverage {
    let value = try await client.raw.info(
      .init(
        type: .custom("activeAssetData"),
        parameters: ["user": .string(address), "coin": .string("BTC")]))
    guard case .object(let object) = value, let leverage = object["leverage"] else {
      throw APIError.invalidResponse
    }
    return try JSONDecoder().decode(Leverage.self, from: JSONEncoder().encode(leverage))
  }

  private func classTransfer(
    client: HeliqClient, wallet: WalletService, amount: String, toPerp: Bool
  ) async throws {
    let nonce = Int64(Date().timeIntervalSince1970 * 1000)
    let parameters: [String: JSONValue] = [
      "amount": .string(amount), "toPerp": .bool(toPerp), "nonce": .number(Double(nonce)),
      "signatureChainId": .string("0x66eee"), "hyperliquidChain": .string("Testnet"),
    ]
    let signature = try await wallet.signUserSigned(
      primaryType: "HyperliquidTransaction:UsdClassTransfer",
      fields: [
        .init(name: "hyperliquidChain", type: "string"), .init(name: "amount", type: "string"),
        .init(name: "toPerp", type: "bool"), .init(name: "nonce", type: "uint64"),
      ], action: parameters, isMainnet: false)
    let response = try await client.raw.exchange(
      .init(
        action: .init(type: .usdClassTransfer, parameters: parameters), nonce: nonce,
        signature: signature))
    guard case .object(let object) = response, object["status"] == .string("ok") else {
      throw ValidationError.malformedData(reason: "USDC class transfer rejected: \(response)")
    }
  }

  private func cleanup(
    client: HeliqClient, wallet: WalletService, asset: Int, initial: Leverage, moved: Bool
  ) async throws {
    let cancellations = try await client.exchange.cancelAll()
    guard cancellations.failedCancels.isEmpty else { throw APIError.invalidResponse }
    if let position = try await client.info.getUserState(address: wallet.address).assetPositions
      .first(where: { $0.asset == asset }), position.positionSize != 0
    {
      let closed = try await client.exchange.placeOrder(
        .init(
          asset: asset, side: position.positionSize > 0 ? .sell : .buy, orderType: .market,
          size: abs(position.positionSize), reduceOnly: true))
      guard closed.status == "filled" else { throw APIError.invalidResponse }
    }
    _ = try await client.exchange.setMarginMode(
      asset: asset, mode: initial.type == "isolated" ? .isolated : .cross)
    _ = try await client.exchange.setLeverage(asset: asset, leverage: initial.value)
    if moved {
      let balance = try await client.info.getUserState(address: wallet.address).marginTotal
      let rounded = floor(balance * 1_000_000) / 1_000_000
      if rounded > 0 {
        try await classTransfer(
          client: client, wallet: wallet,
          amount: String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), rounded),
          toPerp: false)
      }
    }
    #expect(try await client.raw.openOrders(user: wallet.address).isEmpty)
    #expect(try await client.info.getUserState(address: wallet.address).assetPositions.isEmpty)
  }
}
