//
//  InfoUseCaseTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct MockExchangeRepository: ExchangeRepository {
  var placeOrderThrowable: Error?
  var placeOrderResult: OrderResponse?
  var bulkOrdersThrowable: Error?
  var bulkOrdersResult: BulkOrderResponse?
  var cancelOrderThrowable: Error?
  var cancelOrderResult: CancelResponse?
  var cancelByCloidThrowable: Error?
  var cancelByCloidResult: CancelResponse?
  var cancelAllThrowable: Error?
  var cancelAllResult: CancelAllResponse?
  var modifyOrderThrowable: Error?
  var modifyOrderResult: OrderResponse?
  var modifyByCloidThrowable: Error?
  var modifyByCloidResult: OrderResponse?
  var setLeverageThrowable: Error?
  var setLeverageResult: SetLeverageResponse?
  var setMarginModeThrowable: Error?
  var setMarginModeResult: SetMarginModeResponse?
  var transferThrowable: Error?
  var transferResult: TransferResponse?
  var sendToAddressThrowable: Error?
  var sendToAddressResult: SendToAddressResponse?
  var spotTransferThrowable: Error?
  var spotTransferResult: SpotTransferResponse?
  var vaultTransferThrowable: Error?
  var vaultTransferResult: VaultTransferResponse?
  var updateBuilderThrowable: Error?
  var updateBuilderResult: UpdateBuilderResponse?
  var scheduleCancelThrowable: Error?
  var scheduleCancelResult: ScheduleCancelResponse?
  var setReferrerThrowable: Error?
  var setReferrerResult: SetReferrerResponse?
  var convertToMultiSigUserThrowable: Error?
  var convertToMultiSigUserResult: ConvertToMultiSigResponse?
  var usdSendThrowable: Error?
  var usdSendResult: UsdSendResponse?
  
  func placeOrder(_ order: OrderRequest) async throws -> OrderResponse {
    if let error = placeOrderThrowable { throw error }
    guard let result = placeOrderResult else { throw APIError.invalidResponse }
    return result
  }
  
  func bulkOrders(_ orders: [OrderRequest]) async throws -> BulkOrderResponse {
    if let error = bulkOrdersThrowable { throw error }
    guard let result = bulkOrdersResult else { throw APIError.invalidResponse }
    return result
  }
  
  func cancelOrder(orderId: String, asset: Int) async throws -> CancelResponse {
    if let error = cancelOrderThrowable { throw error }
    guard let result = cancelOrderResult else { throw APIError.invalidResponse }
    return result
  }
  
  func cancelByCloid(cloid: String, asset: Int) async throws -> CancelResponse {
    if let error = cancelByCloidThrowable { throw error }
    guard let result = cancelByCloidResult else { throw APIError.invalidResponse }
    return result
  }
  
  func cancelAll() async throws -> CancelAllResponse {
    if let error = cancelAllThrowable { throw error }
    guard let result = cancelAllResult else { throw APIError.invalidResponse }
    return result
  }
  
  func modifyOrder(orderId: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse {
    if let error = modifyOrderThrowable { throw error }
    guard let result = modifyOrderResult else { throw APIError.invalidResponse }
    return result
  }
  
  func modifyByCloid(cloid: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse {
    if let error = modifyByCloidThrowable { throw error }
    guard let result = modifyByCloidResult else { throw APIError.invalidResponse }
    return result
  }
  
  func setLeverage(asset: Int, leverage: Int) async throws -> SetLeverageResponse {
    if let error = setLeverageThrowable { throw error }
    guard let result = setLeverageResult else { throw APIError.invalidResponse }
    return result
  }
  
  func setMarginMode(asset: Int, mode: MarginMode) async throws -> SetMarginModeResponse {
    if let error = setMarginModeThrowable { throw error }
    guard let result = setMarginModeResult else { throw APIError.invalidResponse }
    return result
  }
  
  func transfer(fromAddress: String, toAddress: String, amount: Double, asset: Int) async throws -> TransferResponse {
    if let error = transferThrowable { throw error }
    guard let result = transferResult else { throw APIError.invalidResponse }
    return result
  }
  
  func sendToAddress(address: String, amount: Double, asset: Int) async throws -> SendToAddressResponse {
    if let error = sendToAddressThrowable { throw error }
    guard let result = sendToAddressResult else { throw APIError.invalidResponse }
    return result
  }
  
  func spotTransfer(toAddress: String, amount: Double, asset: Int) async throws -> SpotTransferResponse {
    if let error = spotTransferThrowable { throw error }
    guard let result = spotTransferResult else { throw APIError.invalidResponse }
    return result
  }
  
  func vaultTransfer(vaultTransfer: VaultTransfer) async throws -> VaultTransferResponse {
    if let error = vaultTransferThrowable { throw error }
    guard let result = vaultTransferResult else { throw APIError.invalidResponse }
    return result
  }
  
  func updateBuilder(builderAddress: String) async throws -> UpdateBuilderResponse {
    if let error = updateBuilderThrowable { throw error }
    guard let result = updateBuilderResult else { throw APIError.invalidResponse }
    return result
  }
  
  func scheduleCancel(time: Date) async throws -> ScheduleCancelResponse {
    if let error = scheduleCancelThrowable { throw error }
    guard let result = scheduleCancelResult else { throw APIError.invalidResponse }
    return result
  }
  
  func setReferrer(referrer: String) async throws -> SetReferrerResponse {
    if let error = setReferrerThrowable { throw error }
    guard let result = setReferrerResult else { throw APIError.invalidResponse }
    return result
  }
  
  func convertToMultiSigUser() async throws -> ConvertToMultiSigResponse {
    if let error = convertToMultiSigUserThrowable { throw error }
    guard let result = convertToMultiSigUserResult else { throw APIError.invalidResponse }
    return result
  }
  
  func usdSend(destination: String, amount: Double) async throws -> UsdSendResponse {
    if let error = usdSendThrowable { throw error }
    guard let result = usdSendResult else { throw APIError.invalidResponse }
    return result
  }
}

struct InfoUseCaseTests {
  @Test func testGetUserStateUseCase_execute_returnsUserState() async throws {
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
    
    let useCase = GetUserStateUseCase(infoRepository: mockRepo)
    let result = try await useCase.execute(address: "0x1234567890123456789012345678901234567890")
    
    #expect(result.accountAddress == expectedUserState.accountAddress)
  }
  
  @Test func testGetUserStateUseCase_execute_throwsOnRepositoryError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getUserStateThrowable = APIError.invalidResponse
    
    let useCase = GetUserStateUseCase(infoRepository: mockRepo)
    
    do {
      _ = try await useCase.execute(address: "0x1234567890123456789012345678901234567890")
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetSpotUserStateUseCase_execute_returnsSpotUserState() async throws {
    var mockRepo = MockInfoRepository()
    let expectedSpotUserState = SpotUserState(
      accountAddress: "0x1234567890123456789012345678901234567890",
      spotPositions: [],
      totalUsdc: 1000.0
    )
    mockRepo.getSpotUserStateResult = expectedSpotUserState
    
    let useCase = GetSpotUserStateUseCase(infoRepository: mockRepo)
    let result = try await useCase.execute(address: "0x1234567890123456789012345678901234567890")
    
    #expect(result.totalUsdc == 1000.0)
  }
  
  @Test func testGetAllMidsUseCase_execute_returnsAllMids() async throws {
    var mockRepo = MockInfoRepository()
    let expectedMids = AllMids(prices: ["BTC": 50000.0])
    mockRepo.getAllMidsResult = expectedMids
    
    let useCase = GetAllMidsUseCase(infoRepository: mockRepo)
    let result = try await useCase.execute()
    
    #expect(result.price(for: "BTC") == 50000.0)
  }
  
  @Test func testGetAllMidsUseCase_execute_throwsOnRepositoryError() async throws {
    var mockRepo = MockInfoRepository()
    mockRepo.getAllMidsThrowable = APIError.invalidResponse
    
    let useCase = GetAllMidsUseCase(infoRepository: mockRepo)
    
    do {
      _ = try await useCase.execute()
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testGetAssetCtxsUseCase_execute_returnsAssetContextArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedCtxs: [AssetContext] = []
    mockRepo.getAssetCtxsResult = expectedCtxs
    
    let useCase = GetAssetCtxsUseCase(infoRepository: mockRepo)
    let result = try await useCase.execute()
    
    #expect(result.count == 0)
  }
  
  @Test func testGetL2BookUseCase_execute_returnsL2Book() async throws {
    var mockRepo = MockInfoRepository()
    let expectedBook = L2Book(coin: "BTC", levels: [], timestamp: Date())
    mockRepo.getL2BookResult = expectedBook
    
    let useCase = GetL2BookUseCase(infoRepository: mockRepo)
    let result = try await useCase.execute(coin: "BTC")
    
    #expect(result.coin == "BTC")
  }
  
  @Test func testQueryFillsUseCase_execute_returnsFillArray() async throws {
    var mockRepo = MockInfoRepository()
    let expectedFills: [Fill] = []
    mockRepo.queryFillsResult = expectedFills
    
    let useCase = QueryFillsUseCase(infoRepository: mockRepo)
    let result = try await useCase.execute(address: "0x123")
    
    #expect(result.count == 0)
  }
  
  @Test func testGetMetaUseCase_execute_returnsMeta() async throws {
    var mockRepo = MockInfoRepository()
    let expectedMeta = Meta(universe: [], spotAssetConfigs: [:])
    mockRepo.getMetaResult = expectedMeta
    
    let useCase = GetMetaUseCase(infoRepository: mockRepo)
    let result = try await useCase.execute()
    
    #expect(result.universe.count == 0)
  }
  
  @Test func testGetTimeUseCase_execute_returnsDate() async throws {
    var mockRepo = MockInfoRepository()
    let expectedDate = Date(timeIntervalSince1970: 1700000000)
    mockRepo.getTimeResult = expectedDate
    
    let useCase = GetTimeUseCase(infoRepository: mockRepo)
    let result = try await useCase.execute()
    
    #expect(result.timeIntervalSince1970 == expectedDate.timeIntervalSince1970)
  }
}

struct ExchangeUseCaseTests {
  @Test func testPlaceOrderUseCase_execute_returnsOrderResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = OrderResponse(orderId: "123", status: "filled")
    mockRepo.placeOrderResult = expectedResponse
    
    let useCase = PlaceOrderUseCase(exchangeRepository: mockRepo)
    let order = OrderRequest(asset: 0, side: .buy, orderType: .market, size: 1.0)
    let result = try await useCase.execute(order)
    
    #expect(result.orderId == "123")
    #expect(result.status == "filled")
  }
  
  @Test func testPlaceOrderUseCase_execute_throwsOnRepositoryError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.placeOrderThrowable = APIError.invalidResponse
    
    let useCase = PlaceOrderUseCase(exchangeRepository: mockRepo)
    let order = OrderRequest(asset: 0, side: .buy, orderType: .market, size: 1.0)
    
    do {
      _ = try await useCase.execute(order)
      #expect(Bool(false), "Expected throw")
    } catch let error as APIError {
      #expect(error.errorCode == APIError.invalidResponse.errorCode)
    }
  }
  
  @Test func testCancelOrderUseCase_execute_returnsCancelResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = CancelResponse(status: "cancelled")
    mockRepo.cancelOrderResult = expectedResponse
    
    let useCase = CancelOrderUseCase(exchangeRepository: mockRepo)
    let result = try await useCase.execute(orderId: "123", asset: 0)
    
    #expect(result.status == "cancelled")
  }
  
  @Test func testCancelAllUseCase_execute_returnsCancelAllResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = CancelAllResponse(cancelledOrders: ["1", "2"], failedCancels: [])
    mockRepo.cancelAllResult = expectedResponse
    
    let useCase = CancelAllUseCase(exchangeRepository: mockRepo)
    let result = try await useCase.execute()
    
    #expect(result.cancelledOrders.count == 2)
  }
  
  @Test func testModifyOrderUseCase_execute_returnsOrderResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = OrderResponse(orderId: "123", status: "open")
    mockRepo.modifyOrderResult = expectedResponse
    
    let useCase = ModifyOrderUseCase(exchangeRepository: mockRepo)
    let result = try await useCase.execute(orderId: "123", asset: 0, size: 2.0, price: 50000.0)
    
    #expect(result.orderId == "123")
  }
  
  @Test func testSetLeverageUseCase_execute_returnsSetLeverageResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = SetLeverageResponse(status: "ok", leverage: 10)
    mockRepo.setLeverageResult = expectedResponse
    
    let useCase = SetLeverageUseCase(exchangeRepository: mockRepo)
    let result = try await useCase.execute(asset: 0, leverage: 10)
    
    #expect(result.leverage == 10)
  }
  
  @Test func testSetMarginModeUseCase_execute_returnsSetMarginModeResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = SetMarginModeResponse(status: "ok")
    mockRepo.setMarginModeResult = expectedResponse
    
    let useCase = SetMarginModeUseCase(exchangeRepository: mockRepo)
    let result = try await useCase.execute(asset: 0, mode: .cross)
    
    #expect(result.status == "ok")
  }
  
  @Test func testTransferUseCase_execute_returnsTransferResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = TransferResponse(status: "ok", hash: "0xabc")
    mockRepo.transferResult = expectedResponse
    
    let useCase = TransferUseCase(exchangeRepository: mockRepo)
    let result = try await useCase.execute(fromAddress: "0x123", toAddress: "0x456", amount: 100.0, asset: 0)
    
    #expect(result.hash == "0xabc")
  }
  
  @Test func testSpotTransferUseCase_execute_returnsSpotTransferResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = SpotTransferResponse(status: "ok")
    mockRepo.spotTransferResult = expectedResponse
    
    let useCase = SpotTransferUseCase(exchangeRepository: mockRepo)
    let result = try await useCase.execute(toAddress: "0x123", amount: 100.0, asset: 0)
    
    #expect(result.status == "ok")
  }
  
  @Test func testScheduleCancelUseCase_execute_returnsScheduleCancelResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let scheduledTime = Date(timeIntervalSince1970: 1700000000)
    let expectedResponse = ScheduleCancelResponse(status: "ok", scheduledTime: scheduledTime)
    mockRepo.scheduleCancelResult = expectedResponse
    
    let useCase = ScheduleCancelUseCase(exchangeRepository: mockRepo)
    let result = try await useCase.execute(time: scheduledTime)
    
    #expect(result.status == "ok")
  }
}
