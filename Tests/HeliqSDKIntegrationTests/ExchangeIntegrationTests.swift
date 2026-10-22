//
//  ExchangeIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Security
import Testing
import HeliqSDK

@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["HELIQ_TRADING_LIVE_TESTS"] == "1"))
struct ExchangeIntegrationTests {
  private let zeroAddress = "0x0000000000000000000000000000000000000000"

  private func makeRepo() throws -> ExchangeRepositoryImpl {
    ExchangeRepositoryImpl(apiClient: APIClient(environment: .testnet), wallet: try ProbeWallet())
  }

  private func sampleOrder(limit: Bool = false) -> OrderRequest {
    OrderRequest(
      asset: 0,
      side: .buy,
      orderType: limit ? .limit : .market,
      size: 0.001,
      price: limit ? 1 : nil,
      reduceOnly: false,
      cloid: nil
    )
  }

  // MARK: - Orders

  @Test func testIntegration_placeOrder_market() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().placeOrder(sampleOrder())
    }
  }

  @Test func testIntegration_placeOrder_limit() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().placeOrder(sampleOrder(limit: true))
    }
  }

  @Test func testIntegration_bulkOrders() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().bulkOrders([sampleOrder(), sampleOrder(limit: true)])
    }
  }

  @Test func testIntegration_cancelOrder() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().cancelOrder(orderId: "999999999", asset: 0)
    }
  }

  @Test func testIntegration_cancelByCloid() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().cancelByCloid(cloid: "0x1234567890abcdef1234567890abcdef", asset: 0)
    }
  }

  @Test func testIntegration_cancelAll() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().cancelAll()
    }
  }

  @Test func testIntegration_modifyOrder() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().modifyOrder(orderId: "999999999", asset: 0, size: 0.001, price: 1)
    }
  }

  @Test func testIntegration_modifyByCloid() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().modifyByCloid(cloid: "0x1234567890abcdef1234567890abcdef", asset: 0, size: 0.001, price: 1)
    }
  }

  // MARK: - Position / margin

  @Test func testIntegration_setLeverage() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().setLeverage(asset: 0, leverage: 2)
    }
  }

  @Test func testIntegration_setMarginMode() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().setMarginMode(asset: 0, mode: .cross)
    }
  }

  // MARK: - Transfers

  @Test func testIntegration_transfer() async throws {
    await expectSuccessfulExchangeResponse {
      let wallet = try ProbeWallet()
      let transferRepo = ExchangeRepositoryImpl(apiClient: APIClient(environment: .testnet), wallet: wallet)
      return try await transferRepo.transfer(fromAddress: wallet.address, toAddress: zeroAddress, amount: 0.001, asset: 0)
    }
  }

  @Test func testIntegration_sendToAddress() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().sendToAddress(address: zeroAddress, amount: 0.001, asset: 0)
    }
  }

  @Test func testIntegration_spotTransfer() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().spotTransfer(toAddress: zeroAddress, amount: 0.001, asset: 0)
    }
  }

  @Test func testIntegration_vaultTransfer() async throws {
    let vt = VaultTransfer(fromVault: false, toVault: true, usdcAmount: 1, vaultAddress: zeroAddress)
    await expectSuccessfulExchangeResponse {
      try await makeRepo().vaultTransfer(vaultTransfer: vt)
    }
  }

  @Test func testIntegration_usdSend() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().usdSend(destination: zeroAddress, amount: 0.001)
    }
  }

  // MARK: - Account ops

  @Test func testIntegration_updateBuilder() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().updateBuilder(builderAddress: zeroAddress, maxFeeRate: "0%")
    }
  }

  @Test func testIntegration_scheduleCancel() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().scheduleCancel(time: Date().addingTimeInterval(3600))
    }
  }

  @Test func testIntegration_setReferrer() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().setReferrer(referrer: "test")
    }
  }

  @Test func testIntegration_convertToMultiSigUser() async throws {
    await expectSuccessfulExchangeResponse {
      try await makeRepo().convertToMultiSigUser(authorizedUsers: [zeroAddress], threshold: 1)
    }
  }

  @Test func testIntegration_testnetRecoversFreshWalletFromEverySigningSchema() async throws {
    let wallet = try ProbeWallet()
    let repo = ExchangeRepositoryImpl(apiClient: APIClient(environment: .testnet), wallet: wallet)
    let operations: [(String, @Sendable () async throws -> Void)] = [
      ("limit", { _ = try await repo.placeOrder(self.sampleOrder(limit: true)) }),
      ("market", { _ = try await repo.placeOrder(self.sampleOrder()) }),
      ("bulk", { _ = try await repo.bulkOrders([self.sampleOrder(limit: true)]) }),
      ("cancel", { _ = try await repo.cancelOrder(orderId: "999999999", asset: 0) }),
      ("cancelByCloid", { _ = try await repo.cancelByCloid(cloid: "0x1234567890abcdef1234567890abcdef", asset: 0) }),
      ("leverage", { _ = try await repo.setLeverage(asset: 0, leverage: 2) }),
      ("margin", { _ = try await repo.setMarginMode(asset: 0, mode: .isolated) }),
      ("transfer", { _ = try await repo.transfer(fromAddress: wallet.address, toAddress: wallet.address, amount: 1, asset: 0) }),
      ("send", { _ = try await repo.sendToAddress(address: wallet.address, amount: 1, asset: 0) }),
      ("spot", { _ = try await repo.spotTransfer(toAddress: wallet.address, amount: 1, asset: 0) }),
      ("vault", { _ = try await repo.vaultTransfer(vaultTransfer: .init(fromVault: false, toVault: true, usdcAmount: 1, vaultAddress: wallet.address)) }),
      ("builder", { _ = try await repo.updateBuilder(builderAddress: wallet.address, maxFeeRate: "0%") }),
      ("schedule", { _ = try await repo.scheduleCancel(time: Date().addingTimeInterval(60)) }),
      ("referral", { _ = try await repo.setReferrer(referrer: "TEST") }),
      ("multisig", { _ = try await repo.convertToMultiSigUser(authorizedUsers: [wallet.address], threshold: 1) }),
      ("usd", { _ = try await repo.usdSend(destination: wallet.address, amount: 1) })
    ]
    for (name, operation) in operations {
      do {
        try await operation()
        Issue.record("Fresh unfunded wallet unexpectedly executed \(name)")
      } catch APIError.hyperliquidError(_, let message) {
        #expect(message.lowercased().contains(wallet.address), "Server must recover the actual signer for \(name)")
        #expect(message.contains("does not exist") || message.contains("Must deposit"), "Expected account eligibility rejection for \(name)")
      } catch { Issue.record("Protocol/signature failure for \(name): \(error)") }
    }
  }

  // Opt-in live probes must fail on any rejection; an error is not successful trading.
  private func expectSuccessfulExchangeResponse<T>(_ work: () async throws -> T) async {
    do {
      let result = try await work()
      if let order = result as? OrderResponse, let error = order.error { Issue.record("Exchange rejected item: \(error)") }
      if let bulk = result as? BulkOrderResponse {
        for order in bulk.responses { if let error = order.error { Issue.record("Exchange rejected item: \(error)") } }
      }
      if let cancel = result as? CancelResponse, let error = cancel.error { Issue.record("Exchange rejected item: \(error)") }
    } catch {
      Issue.record("Live trading operation failed: \(error)")
    }
  }

  private struct ProbeWallet: WalletServiceProtocol {
    private let signer: Signer
    var address: String { signer.address }
    init() throws {
      var bytes = [UInt8](repeating: 0, count: 32)
      guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else { throw SigningError.keyNotFound }
      signer = try Signer(privateKey: bytes.map { String(format: "%02x", $0) }.joined())
    }
    func sign(message: String) async throws -> SignatureTypes { try await signer.sign(message: message) }
    func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws -> SignatureTypes {
      try await signer.signL1(action: action, nonce: nonce, isMainnet: isMainnet)
    }
    func signUserSigned(primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue], isMainnet: Bool) async throws -> SignatureTypes {
      try await signer.signUserSigned(primaryType: primaryType, fields: fields, action: action, isMainnet: isMainnet)
    }
  }
}
