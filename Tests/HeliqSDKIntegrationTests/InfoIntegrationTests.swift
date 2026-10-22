//
//  InfoIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct InfoIntegrationTests {
  private let zeroAddress = "0x0000000000000000000000000000000000000000"
  private let builderAddress = "0x0000000000000000000000000000000000000001"

  private func makeRepo() -> InfoRepositoryImpl {
    InfoRepositoryImpl(apiClient: APIClient(environment: .testnet))
  }

  // MARK: - Market data

  @Test func testIntegration_getAllMids_returnsLiveData() async throws {
    let repo = makeRepo()
    let result = try await repo.getAllMids()
    #expect(!result.prices.isEmpty)
  }

  @Test func testIntegration_getL2Book_BTC_returnsLiveData() async throws {
    let repo = makeRepo()
    let result = try await repo.getL2Book(coin: "BTC")
    #expect(!result.levels.isEmpty)
  }

  @Test func testIntegration_getCandleSnapshot_BTC_1m() async throws {
    let repo = makeRepo()
    let end = Date()
    let start = end.addingTimeInterval(-3600)
    let result = try await repo.getCandleSnapshot(coin: "BTC", interval: "1m", startTime: start, endTime: end)
    #expect(!result.isEmpty)
  }

  @Test func testIntegration_getAssetCtxs() async throws {
    let repo = makeRepo()
    let result = try await repo.getAssetCtxs()
    #expect(!result.isEmpty)
  }

  @Test func testIntegration_getSpotAssetCtxs() async throws {
    let repo = makeRepo()
    let result = try await repo.getSpotAssetCtxs()
    #expect(!result.isEmpty)
  }

  // MARK: - Metadata

  @Test func testIntegration_getMeta() async throws {
    let result = try await makeRepo().getMeta()
    #expect(!result.universe.isEmpty)
    #expect(result.universe.allSatisfy { $0.isPerpetual && $0.weiDecimals == nil })
  }

  @Test func testIntegration_getSpotMeta() async throws {
    let result = try await makeRepo().getSpotMeta()
    #expect(!result.universe.isEmpty)
    #expect(result.universe.allSatisfy { !$0.isPerpetual && $0.weiDecimals != nil })
  }

  @Test func testIntegration_getTime() async throws {
    let repo = makeRepo()
    let result = try await repo.getTime()
    #expect(abs(result.timeIntervalSinceNow) < 300)
  }

  @Test func testIntegration_fetchBuilderFee() async throws {
    let result = try await makeRepo().fetchBuilderFee(builderAddress: builderAddress, address: zeroAddress)
    #expect(result.feeBps >= 0)
  }

  // MARK: - User data

  @Test func testIntegration_getUserState_zeroAddress() async throws {
    let state = try await makeRepo().getUserState(address: zeroAddress)
    #expect(state.accountAddress == zeroAddress)
  }

  @Test func testIntegration_getSpotUserState_zeroAddress() async throws {
    let state = try await makeRepo().getSpotUserState(address: zeroAddress)
    #expect(state.accountAddress == zeroAddress)
  }

  @Test func testIntegration_queryFills_zeroAddress() async throws {
    _ = try await makeRepo().queryFills(address: zeroAddress)
  }

  @Test func testIntegration_queryUserFundings_zeroAddress() async throws {
    _ = try await makeRepo().queryUserFundings(address: zeroAddress)
  }

  @Test func testIntegration_queryOrderByOid_nonExistent() async throws {
    let result = try await makeRepo().queryOrderByOid(orderId: "999999999", address: zeroAddress)
    #expect(result.isEmpty)
  }

  @Test func testIntegration_queryOrderByCloid_nonExistent() async throws {
    let result = try await makeRepo().queryOrderByCloid(
      cloid: "0x1234567890abcdef1234567890abcdef", address: zeroAddress
    )
    #expect(result.isEmpty)
  }
}
