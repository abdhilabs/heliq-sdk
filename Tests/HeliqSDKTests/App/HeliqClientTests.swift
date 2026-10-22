//
//  HeliqClientTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Testing
import HeliqSDK

struct HeliqClientTests {
  @Test func builderCreatesIndependentPublicClientWithoutWallet() throws {
    let client = try HeliqClient.Builder()
      .environment(.testnet)
      .build()

    #expect(client.environment == .testnet)
  }

  @Test func exchangeFacadeRejectsSignedActionWithoutWallet() async {
    let client = try! HeliqClient.Builder().build()
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 1,
      price: nil,
      reduceOnly: false,
      cloid: nil
    )

    do {
      _ = try await client.exchange.placeOrder(order)
      Issue.record("Expected a missing-wallet validation error")
    } catch let error as ValidationError {
      #expect(error.errorCode == "VALIDATION_MISSING_FIELD")
      #expect(error.errorDescription == "Missing required field: wallet")
    } catch {
      Issue.record("Expected ValidationError, got \(error)")
    }
  }
}
