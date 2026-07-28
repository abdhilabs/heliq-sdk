//
//  ExchangeIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct ExchangeIntegrationTests {
  private let zeroAddress = "0x0000000000000000000000000000000000000000"

  private func makeRepo() -> ExchangeRepositoryImpl {
    ExchangeRepositoryImpl(apiClient: APIClient(environment: .testnet))
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
    await expectExchangeErrorOrResponse {
      try await makeRepo().placeOrder(sampleOrder())
    }
  }

  @Test func testIntegration_placeOrder_limit() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().placeOrder(sampleOrder(limit: true))
    }
  }

  @Test func testIntegration_bulkOrders() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().bulkOrders([sampleOrder(), sampleOrder(limit: true)])
    }
  }

  @Test func testIntegration_cancelOrder() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().cancelOrder(orderId: "999999999", asset: 0)
    }
  }

  @Test func testIntegration_cancelByCloid() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().cancelByCloid(cloid: "0x1234567890abcdef1234567890abcdef", asset: 0)
    }
  }

  @Test func testIntegration_cancelAll() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().cancelAll()
    }
  }

  @Test func testIntegration_modifyOrder() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().modifyOrder(orderId: "999999999", asset: 0, size: 0.001, price: 1)
    }
  }

  @Test func testIntegration_modifyByCloid() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().modifyByCloid(cloid: "0x1234567890abcdef1234567890abcdef", asset: 0, size: 0.001, price: 1)
    }
  }

  // MARK: - Position / margin

  @Test func testIntegration_setLeverage() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().setLeverage(asset: 0, leverage: 2)
    }
  }

  @Test func testIntegration_setMarginMode() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().setMarginMode(asset: 0, mode: .cross)
    }
  }

  // MARK: - Transfers

  @Test func testIntegration_transfer() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().transfer(fromAddress: zeroAddress, toAddress: zeroAddress, amount: 0.001, asset: 0)
    }
  }

  @Test func testIntegration_sendToAddress() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().sendToAddress(address: zeroAddress, amount: 0.001, asset: 0)
    }
  }

  @Test func testIntegration_spotTransfer() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().spotTransfer(toAddress: zeroAddress, amount: 0.001, asset: 0)
    }
  }

  @Test func testIntegration_vaultTransfer() async throws {
    let vt = VaultTransfer(fromVault: false, toVault: true, usdcAmount: 1, vaultAddress: zeroAddress)
    await expectExchangeErrorOrResponse {
      try await makeRepo().vaultTransfer(vaultTransfer: vt)
    }
  }

  @Test func testIntegration_usdSend() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().usdSend(destination: zeroAddress, amount: 0.001)
    }
  }

  // MARK: - Account ops

  @Test func testIntegration_updateBuilder() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().updateBuilder(builderAddress: zeroAddress)
    }
  }

  @Test func testIntegration_scheduleCancel() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().scheduleCancel(time: Date().addingTimeInterval(3600))
    }
  }

  @Test func testIntegration_setReferrer() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().setReferrer(referrer: "test")
    }
  }

  @Test func testIntegration_convertToMultiSigUser() async throws {
    await expectExchangeErrorOrResponse {
      try await makeRepo().convertToMultiSigUser()
    }
  }

  // Helper: exchange calls must either succeed or throw a typed error (never crash).
  private func expectExchangeErrorOrResponse<T>(_ work: () async throws -> T) async {
    do {
      _ = try await work()
      #expect(true)
    } catch {
      #expect(
        error is APIError ||
        error is NetworkError ||
        error is DecodingError ||
        error is ValidationError
      )
    }
  }
}
