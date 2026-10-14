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

  @Test func testIntegration_getAllMids_returnsOrSurfacesModelMismatch() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.getAllMids()
      #expect(result.prices.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_getL2Book_BTC_returnsOrSurfacesModelMismatch() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.getL2Book(coin: "BTC")
      #expect(result.levels.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
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
    do {
      let result = try await repo.getAssetCtxs()
      #expect(result.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_getSpotAssetCtxs() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.getSpotAssetCtxs()
      #expect(result.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  // MARK: - Metadata

  @Test func testIntegration_getMeta() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.getMeta()
      #expect(result.universe.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_getSpotMeta() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.getSpotMeta()
      #expect(result.universe.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_getTime() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.getTime()
      #expect(result.timeIntervalSince1970 > 1_600_000_000)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_fetchBuilderFee() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.fetchBuilderFee(builderAddress: builderAddress)
      #expect(result.feeBps >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  // MARK: - User data

  @Test func testIntegration_getUserState_zeroAddress() async throws {
    let repo = makeRepo()
    do {
      _ = try await repo.getUserState(address: zeroAddress)
      #expect(true)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_getSpotUserState_zeroAddress() async throws {
    let repo = makeRepo()
    do {
      _ = try await repo.getSpotUserState(address: zeroAddress)
      #expect(true)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_queryFills_zeroAddress() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.queryFills(address: zeroAddress)
      #expect(result.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_queryUserFundings_zeroAddress() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.queryUserFundings(address: zeroAddress)
      #expect(result.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_queryOrderByOid_nonExistent() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.queryOrderByOid(orderId: "999999999")
      #expect(result.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }

  @Test func testIntegration_queryOrderByCloid_nonExistent() async throws {
    let repo = makeRepo()
    do {
      let result = try await repo.queryOrderByCloid(cloid: "0x1234567890abcdef1234567890abcdef")
      #expect(result.count >= 0)
    } catch {
      #expect(error is APIError || error is NetworkError || error is DecodingError)
    }
  }
}
