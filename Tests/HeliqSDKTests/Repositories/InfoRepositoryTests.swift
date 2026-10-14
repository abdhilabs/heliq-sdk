//
//  InfoRepositoryTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct MockInfoRepository: InfoRepository {
  var getUserStateThrowable: Error?
  var getUserStateResult: UserState?
  var getSpotUserStateThrowable: Error?
  var getSpotUserStateResult: SpotUserState?
  var getAllMidsThrowable: Error?
  var getAllMidsResult: AllMids?
  var getAssetCtxsThrowable: Error?
  var getAssetCtxsResult: [AssetContext]?
  var getSpotAssetCtxsThrowable: Error?
  var getSpotAssetCtxsResult: [SpotAssetContext]?
  var getCandleSnapshotThrowable: Error?
  var getCandleSnapshotResult: [Candle]?
  var getL2BookThrowable: Error?
  var getL2BookResult: L2Book?
  var queryOrderByOidThrowable: Error?
  var queryOrderByOidResult: [Order]?
  var queryOrderByCloidThrowable: Error?
  var queryOrderByCloidResult: [Order]?
  var queryFillsThrowable: Error?
  var queryFillsResult: [Fill]?
  var queryUserFundingsThrowable: Error?
  var queryUserFundingsResult: [UserFunding]?
  var getMetaThrowable: Error?
  var getMetaResult: Meta?
  var getSpotMetaThrowable: Error?
  var getSpotMetaResult: Meta?
  var getTimeThrowable: Error?
  var getTimeResult: Date?
  var fetchBuilderFeeThrowable: Error?
  var fetchBuilderFeeResult: BuilderFee?
  
  func getUserState(address: String) async throws -> UserState {
    if let error = getUserStateThrowable { throw error }
    guard let result = getUserStateResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getSpotUserState(address: String) async throws -> SpotUserState {
    if let error = getSpotUserStateThrowable { throw error }
    guard let result = getSpotUserStateResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getAllMids() async throws -> AllMids {
    if let error = getAllMidsThrowable { throw error }
    guard let result = getAllMidsResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getAssetCtxs() async throws -> [AssetContext] {
    if let error = getAssetCtxsThrowable { throw error }
    guard let result = getAssetCtxsResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getSpotAssetCtxs() async throws -> [SpotAssetContext] {
    if let error = getSpotAssetCtxsThrowable { throw error }
    guard let result = getSpotAssetCtxsResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getCandleSnapshot(coin: String, interval: String, startTime: Date, endTime: Date) async throws -> [Candle] {
    if let error = getCandleSnapshotThrowable { throw error }
    guard let result = getCandleSnapshotResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getL2Book(coin: String) async throws -> L2Book {
    if let error = getL2BookThrowable { throw error }
    guard let result = getL2BookResult else { throw APIError.invalidResponse }
    return result
  }
  
  func queryOrderByOid(orderId: String) async throws -> [Order] {
    if let error = queryOrderByOidThrowable { throw error }
    guard let result = queryOrderByOidResult else { throw APIError.invalidResponse }
    return result
  }
  
  func queryOrderByCloid(cloid: String) async throws -> [Order] {
    if let error = queryOrderByCloidThrowable { throw error }
    guard let result = queryOrderByCloidResult else { throw APIError.invalidResponse }
    return result
  }
  
  func queryOrderByOid(orderId: String, address: String) async throws -> [Order] {
    try await queryOrderByOid(orderId: orderId)
  }

  func queryOrderByCloid(cloid: String, address: String) async throws -> [Order] {
    try await queryOrderByCloid(cloid: cloid)
  }

  func queryFills(address: String) async throws -> [Fill] {
    if let error = queryFillsThrowable { throw error }
    guard let result = queryFillsResult else { throw APIError.invalidResponse }
    return result
  }
  
  func queryUserFundings(address: String) async throws -> [UserFunding] {
    if let error = queryUserFundingsThrowable { throw error }
    guard let result = queryUserFundingsResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getMeta() async throws -> Meta {
    if let error = getMetaThrowable { throw error }
    guard let result = getMetaResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getSpotMeta() async throws -> Meta {
    if let error = getSpotMetaThrowable { throw error }
    guard let result = getSpotMetaResult else { throw APIError.invalidResponse }
    return result
  }
  
  func getTime() async throws -> Date {
    if let error = getTimeThrowable { throw error }
    guard let result = getTimeResult else { throw APIError.invalidResponse }
    return result
  }
  
  func fetchBuilderFee(builderAddress: String, address: String) async throws -> BuilderFee {
    try await fetchBuilderFee(builderAddress: builderAddress)
  }

  func fetchBuilderFee(builderAddress: String) async throws -> BuilderFee {
    if let error = fetchBuilderFeeThrowable { throw error }
    guard let result = fetchBuilderFeeResult else { throw APIError.invalidResponse }
    return result
  }
}

struct InfoRepositoryTests {
  @Test func testGetUserState_returnsUserState() async throws {
    var mockRepo = MockInfoRepository()
    let expectedUserState = UserState(
      accountAddress: "0x1234567890123456789012345678901234567890",
      assetPositions: [],
      marginUsed: 0,
      marginTotal: 0,
      marginMode: .cross,
      leverage: 10
    )
    mockRepo.getUserStateResult = expectedUserState
    
    let result = try await mockRepo.getUserState(address: "0x1234567890123456789012345678901234567890")
    
    #expect(result.accountAddress == expectedUserState.accountAddress)
  }
  
  @Test func testGetUserState_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getUserStateThrowable = APIError.invalidResponse
    var mockRepo2 = mockRepo
    mockRepo2.getUserStateThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo2.getUserState(address: "0x1234567890123456789012345678901234567890")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetSpotUserState_returnsSpotUserState() async throws {
    var mockRepo = MockInfoRepository()
    let expectedSpotUserState = SpotUserState(
      accountAddress: "0x1234567890123456789012345678901234567890",
      spotPositions: [],
      totalUsdc: 1000.0
    )
    mockRepo.getSpotUserStateResult = expectedSpotUserState
    
    let result = try await mockRepo.getSpotUserState(address: "0x1234567890123456789012345678901234567890")
    
    #expect(result.accountAddress == expectedSpotUserState.accountAddress)
    #expect(result.totalUsdc == 1000.0)
  }
  
  @Test func testGetSpotUserState_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getSpotUserStateThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getSpotUserState(address: "0x1234567890123456789012345678901234567890")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetAllMids_returnsAllMids() async throws {
    var mockRepo = MockInfoRepository()
    let expectedMids = AllMids(prices: ["BTC": 50000.0, "ETH": 3000.0])
    mockRepo.getAllMidsResult = expectedMids
    
    let result = try await mockRepo.getAllMids()
    
    #expect(result.price(for: "BTC") == 50000.0)
    #expect(result.price(for: "ETH") == 3000.0)
  }
  
  @Test func testGetAllMids_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getAllMidsThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getAllMids()
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetAssetCtxs_returnsAssetContextArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedCtxs: [AssetContext] = []
    mockRepo.getAssetCtxsResult = expectedCtxs
    
    let result = try await mockRepo.getAssetCtxs()
    
    #expect(result.count == 0)
  }
  
  @Test func testGetAssetCtxs_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getAssetCtxsThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getAssetCtxs()
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetSpotAssetCtxs_returnsSpotAssetContextArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedCtxs: [SpotAssetContext] = []
    mockRepo.getSpotAssetCtxsResult = expectedCtxs
    
    let result = try await mockRepo.getSpotAssetCtxs()
    
    #expect(result.count == 0)
  }
  
  @Test func testGetSpotAssetCtxs_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getSpotAssetCtxsThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getSpotAssetCtxs()
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetCandleSnapshot_returnsCandleArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedCandles = [
      Candle(timestamp: Date(), open: 49000, high: 51000, low: 48000, close: 50000, volume: 1000)
    ]
    mockRepo.getCandleSnapshotResult = expectedCandles
    
    let result = try await mockRepo.getCandleSnapshot(coin: "BTC", interval: "1m", startTime: Date(), endTime: Date())
    
    #expect(result.count == 1)
  }
  
  @Test func testGetCandleSnapshot_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getCandleSnapshotThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getCandleSnapshot(coin: "BTC", interval: "1m", startTime: Date(), endTime: Date())
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetL2Book_returnsL2Book() async throws {
    var mockRepo = MockInfoRepository()
    let expectedBook = L2Book(coin: "BTC", levels: [], timestamp: Date())
    mockRepo.getL2BookResult = expectedBook
    
    let result = try await mockRepo.getL2Book(coin: "BTC")
    
    #expect(result.coin == "BTC")
  }
  
  @Test func testGetL2Book_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getL2BookThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getL2Book(coin: "BTC")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testQueryOrderByOid_returnsOrderArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedOrders: [Order] = []
    mockRepo.queryOrderByOidResult = expectedOrders
    
    let result = try await mockRepo.queryOrderByOid(orderId: "123")
    
    #expect(result.count == 0)
  }
  
  @Test func testQueryOrderByOid_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.queryOrderByOidThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.queryOrderByOid(orderId: "123")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testQueryOrderByCloid_returnsOrderArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedOrders: [Order] = []
    mockRepo.queryOrderByCloidResult = expectedOrders
    
    let result = try await mockRepo.queryOrderByCloid(cloid: "0x123")
    
    #expect(result.count == 0)
  }
  
  @Test func testQueryOrderByCloid_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.queryOrderByCloidThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.queryOrderByCloid(cloid: "0x123")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testQueryFills_returnsFillArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedFills: [Fill] = []
    mockRepo.queryFillsResult = expectedFills
    
    let result = try await mockRepo.queryFills(address: "0x123")
    
    #expect(result.count == 0)
  }
  
  @Test func testQueryFills_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.queryFillsThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.queryFills(address: "0x123")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testQueryUserFundings_returnsUserFundingArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedFundings: [UserFunding] = []
    mockRepo.queryUserFundingsResult = expectedFundings
    
    let result = try await mockRepo.queryUserFundings(address: "0x123")
    
    #expect(result.count == 0)
  }
  
  @Test func testQueryUserFundings_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.queryUserFundingsThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.queryUserFundings(address: "0x123")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetMeta_returnsMeta() async throws {
    var mockRepo = MockInfoRepository()
    let expectedMeta = Meta(universe: [], spotAssetConfigs: [:])
    mockRepo.getMetaResult = expectedMeta
    
    let result = try await mockRepo.getMeta()
    
    #expect(result.universe.count == 0)
  }
  
  @Test func testGetMeta_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getMetaThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getMeta()
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetSpotMeta_returnsMeta() async throws {
    var mockRepo = MockInfoRepository()
    let expectedMeta = Meta(universe: [], spotAssetConfigs: [:])
    mockRepo.getSpotMetaResult = expectedMeta
    
    let result = try await mockRepo.getSpotMeta()
    
    #expect(result.universe.count == 0)
  }
  
  @Test func testGetSpotMeta_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getSpotMetaThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getSpotMeta()
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetTime_returnsDate() async throws {
    var mockRepo = MockInfoRepository()
    let expectedDate = Date(timeIntervalSince1970: 1700000000)
    mockRepo.getTimeResult = expectedDate
    
    let result = try await mockRepo.getTime()
    
    #expect(result.timeIntervalSince1970 == expectedDate.timeIntervalSince1970)
  }
  
  @Test func testGetTime_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getTimeThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.getTime()
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testFetchBuilderFee_returnsBuilderFee() async throws {
    var mockRepo = MockInfoRepository()
    let expectedFee = BuilderFee(builderAddress: "0x123", feeBps: 100)
    mockRepo.fetchBuilderFeeResult = expectedFee
    
    let result = try await mockRepo.fetchBuilderFee(builderAddress: "0x123")
    
    #expect(result.feeBps == 100)
  }
  
  @Test func testFetchBuilderFee_throwsOnAPIError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.fetchBuilderFeeThrowable = APIError.invalidResponse
    
    do {
      _ = try await mockRepo.fetchBuilderFee(builderAddress: "0x123")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
}
