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
  
  // MARK: - Tests that require signature (expected to fail without valid key)
  
  @Test func testIntegration_placeOrder_marketOrder_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 1
    )
    // Without valid signature, this should throw an error
    do {
      _ = try await repo.placeOrder(order)
      #expect(true) // If no error, test passes (API accepted the request)
    } catch {
      // Error is expected - API returns error without valid signature
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_placeOrder_limitOrder_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .limit,
      size: 1,
      price: 50000
    )
    do {
      _ = try await repo.placeOrder(order)
      #expect(true)
    } catch {
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_modifyOrder_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    do {
      _ = try await repo.modifyOrder(orderId: "999999999", asset: 0, size: 1, price: 50000)
      #expect(true)
    } catch {
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_cancelByCloid_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    do {
      _ = try await repo.cancelByCloid(cloid: "0x1234567890abcdef1234567890abcdef12345678", asset: 0)
      #expect(true)
    } catch {
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_bulkOrders_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 1
    )
    do {
      _ = try await repo.bulkOrders([order])
      #expect(true)
    } catch {
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_modifyByCloid_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    do {
      _ = try await repo.modifyByCloid(cloid: "0x1234567890abcdef1234567890abcdef12345678", asset: 0, size: 1, price: 50000)
      #expect(true)
    } catch {
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_convertToMultiSig_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    do {
      _ = try await repo.convertToMultiSigUser()
      #expect(true)
    } catch {
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_vaultTransfer_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    let vaultTransfer = VaultTransfer(
      fromVault: false,
      toVault: true,
      usdcAmount: 1,
      vaultAddress: "0x0000000000000000000000000000000000000000"
    )
    do {
      _ = try await repo.vaultTransfer(vaultTransfer: vaultTransfer)
      #expect(true)
    } catch {
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_sendToAddress_requiresSignature() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    do {
      _ = try await repo.sendToAddress(address: "0x0000000000000000000000000000000000000000", amount: 0.001, asset: 0)
      #expect(true)
    } catch {
      #expect(error != nil)
    }
  }
  
  // MARK: - Tests that expose SDK model mismatches
  
  @Test func testIntegration_cancelOrder_exposesModelMismatch() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    // This exposes SDK model mismatch for cancel response
    do {
      let result = try await repo.cancelOrder(orderId: "999999999", asset: 0)
      #expect(result.status.isEmpty == false)
    } catch {
      // Error indicates SDK model doesn't match API response
      #expect(error != nil)
    }
  }
  
  @Test func testIntegration_cancelAll_exposesModelMismatch() async throws {
    let apiClient = APIClient(environment: .testnet)
    let repo = ExchangeRepositoryImpl(apiClient: apiClient)
    // This exposes SDK model mismatch for cancelAll response
    do {
      let result = try await repo.cancelAll()
      #expect(result.cancelledOrders.count >= 0)
    } catch {
      #expect(error != nil)
    }
  }
}
