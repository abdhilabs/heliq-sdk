//
//  RawParityIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Testing
import HeliqSDK

struct RawParityIntegrationTests {
  @Test func testnet_rawInfoTransport_fetchesAllMids() async throws {
    let api = HyperliquidAPI(apiClient: APIClient(environment: .testnet))
    let value = try await api.info(.init(type: .allMids))
    guard case .object(let mids) = value else {
      Issue.record("Expected allMids JSON object")
      return
    }
    #expect(!mids.isEmpty)
  }
}
