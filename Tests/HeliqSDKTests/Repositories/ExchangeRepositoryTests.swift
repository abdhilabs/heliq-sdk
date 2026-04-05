//
//  ExchangeRepositoryTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct ExchangeRepositoryTests {
  @Test func testPlaceOrder_returnsOrderResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let expectedResponse = OrderResponse(orderId: "123", status: "filled")
    mockRepo.placeOrderResult = expectedResponse
    
    let order = OrderRequest(asset: 0, side: .buy, orderType: .market, size: 1.0)
    let result = try await mockRepo.placeOrder(order)
    
    #expect(result.orderId == "123")
    #expect(result.status == "filled")
  }
  
  @Test func testPlaceOrder_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.placeOrderThrowable = APIError.invalidResponse
    
    let order = OrderRequest(asset: 0, side: .buy, orderType: .market, size: 1.0)
    
    var threwError = false
    do {
      _ = try await mockRepo.placeOrder(order)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testBulkOrders_returnsBulkOrderResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let response1 = OrderResponse(orderId: "1", status: "filled")
    let response2 = OrderResponse(orderId: "2", status: "filled")
    mockRepo.bulkOrdersResult = BulkOrderResponse(responses: [response1, response2])
    
    let orders = [
      OrderRequest(asset: 0, side: .buy, orderType: .market, size: 1.0),
      OrderRequest(asset: 0, side: .sell, orderType: .market, size: 0.5)
    ]
    let result = try await mockRepo.bulkOrders(orders)
    
    #expect(result.responses.count == 2)
  }
  
  @Test func testBulkOrders_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.bulkOrdersThrowable = APIError.invalidResponse
    
    let orders = [
      OrderRequest(asset: 0, side: .buy, orderType: .market, size: 1.0)
    ]
    
    var threwError = false
    do {
      _ = try await mockRepo.bulkOrders(orders)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testCancelOrder_returnsCancelResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.cancelOrderResult = CancelResponse(status: "cancelled")
    
    let result = try await mockRepo.cancelOrder(orderId: "123", asset: 0)
    
    #expect(result.status == "cancelled")
  }
  
  @Test func testCancelOrder_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.cancelOrderThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.cancelOrder(orderId: "123", asset: 0)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testCancelByCloid_returnsCancelResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.cancelByCloidResult = CancelResponse(status: "cancelled")
    
    let result = try await mockRepo.cancelByCloid(cloid: "0x1234567890abcdef", asset: 0)
    
    #expect(result.status == "cancelled")
  }
  
  @Test func testCancelByCloid_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.cancelByCloidThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.cancelByCloid(cloid: "0x1234567890abcdef", asset: 0)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testCancelAll_returnsCancelAllResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.cancelAllResult = CancelAllResponse(cancelledOrders: ["1", "2"], failedCancels: [])
    
    let result = try await mockRepo.cancelAll()
    
    #expect(result.cancelledOrders.count == 2)
  }
  
  @Test func testCancelAll_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.cancelAllThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.cancelAll()
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testModifyOrder_returnsOrderResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.modifyOrderResult = OrderResponse(orderId: "123", status: "open")
    
    let result = try await mockRepo.modifyOrder(orderId: "123", asset: 0, size: 2.0, price: 50000.0)
    
    #expect(result.orderId == "123")
  }
  
  @Test func testModifyOrder_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.modifyOrderThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.modifyOrder(orderId: "123", asset: 0, size: 2.0, price: 50000.0)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testModifyByCloid_returnsOrderResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.modifyByCloidResult = OrderResponse(orderId: "123", status: "open")
    
    let result = try await mockRepo.modifyByCloid(cloid: "0x1234567890abcdef", asset: 0, size: 2.0, price: 50000.0)
    
    #expect(result.orderId == "123")
  }
  
  @Test func testModifyByCloid_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.modifyByCloidThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.modifyByCloid(cloid: "0x1234567890abcdef", asset: 0, size: 2.0, price: 50000.0)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testSetLeverage_returnsSetLeverageResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.setLeverageResult = SetLeverageResponse(status: "ok", leverage: 10)
    
    let result = try await mockRepo.setLeverage(asset: 0, leverage: 10)
    
    #expect(result.leverage == 10)
  }
  
  @Test func testSetLeverage_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.setLeverageThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.setLeverage(asset: 0, leverage: 10)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testSetMarginMode_returnsSetMarginModeResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.setMarginModeResult = SetMarginModeResponse(status: "ok")
    
    let result = try await mockRepo.setMarginMode(asset: 0, mode: .cross)
    
    #expect(result.status == "ok")
  }
  
  @Test func testSetMarginMode_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.setMarginModeThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.setMarginMode(asset: 0, mode: .cross)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testTransfer_returnsTransferResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.transferResult = TransferResponse(status: "ok", hash: "0xabc")
    
    let result = try await mockRepo.transfer(fromAddress: "0x123", toAddress: "0x456", amount: 100.0, asset: 0)
    
    #expect(result.hash == "0xabc")
  }
  
  @Test func testTransfer_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.transferThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.transfer(fromAddress: "0x123", toAddress: "0x456", amount: 100.0, asset: 0)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testSendToAddress_returnsSendToAddressResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.sendToAddressResult = SendToAddressResponse(status: "ok", hash: "0xdef")
    
    let result = try await mockRepo.sendToAddress(address: "0x456", amount: 100.0, asset: 0)
    
    #expect(result.hash == "0xdef")
  }
  
  @Test func testSendToAddress_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.sendToAddressThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.sendToAddress(address: "0x456", amount: 100.0, asset: 0)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testSpotTransfer_returnsSpotTransferResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.spotTransferResult = SpotTransferResponse(status: "ok")
    
    let result = try await mockRepo.spotTransfer(toAddress: "0x456", amount: 100.0, asset: 0)
    
    #expect(result.status == "ok")
  }
  
  @Test func testSpotTransfer_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.spotTransferThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.spotTransfer(toAddress: "0x456", amount: 100.0, asset: 0)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testVaultTransfer_returnsVaultTransferResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.vaultTransferResult = VaultTransferResponse(status: "ok")
    
    let vaultTransfer = VaultTransfer(fromVault: true, toVault: false, usdcAmount: 100, vaultAddress: nil)
    let result = try await mockRepo.vaultTransfer(vaultTransfer: vaultTransfer)
    
    #expect(result.status == "ok")
  }
  
  @Test func testVaultTransfer_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.vaultTransferThrowable = APIError.invalidResponse
    
    let vaultTransfer = VaultTransfer(fromVault: true, toVault: false, usdcAmount: 100, vaultAddress: nil)
    var threwError = false
    do {
      _ = try await mockRepo.vaultTransfer(vaultTransfer: vaultTransfer)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testUpdateBuilder_returnsUpdateBuilderResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.updateBuilderResult = UpdateBuilderResponse(status: "ok")
    
    let result = try await mockRepo.updateBuilder(builderAddress: "0xbuilder")
    
    #expect(result.status == "ok")
  }
  
  @Test func testUpdateBuilder_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.updateBuilderThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.updateBuilder(builderAddress: "0xbuilder")
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testScheduleCancel_returnsScheduleCancelResponse() async throws {
    var mockRepo = MockExchangeRepository()
    let scheduledTime = Date(timeIntervalSince1970: 1700000000)
    mockRepo.scheduleCancelResult = ScheduleCancelResponse(status: "ok", scheduledTime: scheduledTime)
    
    let result = try await mockRepo.scheduleCancel(time: scheduledTime)
    
    #expect(result.status == "ok")
  }
  
  @Test func testScheduleCancel_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.scheduleCancelThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.scheduleCancel(time: Date())
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testSetReferrer_returnsSetReferrerResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.setReferrerResult = SetReferrerResponse(status: "ok")
    
    let result = try await mockRepo.setReferrer(referrer: "0xreferrer")
    
    #expect(result.status == "ok")
  }
  
  @Test func testSetReferrer_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.setReferrerThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.setReferrer(referrer: "0xreferrer")
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testConvertToMultiSigUser_returnsConvertToMultiSigResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.convertToMultiSigUserResult = ConvertToMultiSigResponse(status: "ok")
    
    let result = try await mockRepo.convertToMultiSigUser()
    
    #expect(result.status == "ok")
  }
  
  @Test func testConvertToMultiSigUser_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.convertToMultiSigUserThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.convertToMultiSigUser()
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testUsdSend_returnsUsdSendResponse() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.usdSendResult = UsdSendResponse(status: "ok", hash: "0xusd")
    
    let result = try await mockRepo.usdSend(destination: "0xdest", amount: 100.0)
    
    #expect(result.hash == "0xusd")
  }
  
  @Test func testUsdSend_throwsOnAPIError() async throws {
    var mockRepo = MockExchangeRepository()
    mockRepo.usdSendThrowable = APIError.invalidResponse
    
    var threwError = false
    do {
      _ = try await mockRepo.usdSend(destination: "0xdest", amount: 100.0)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
}

struct APIRequestTests {
  @Test func testInfoAPIRequest_pathIsCorrect() throws {
    let request = InfoAPIRequest(endpoint: .allMids, body: nil)
    
    #expect(request.path == "/info")
    #expect(request.method == .post)
  }
  
  @Test func testInfoAPIRequest_methodIsPost() throws {
    let request = InfoAPIRequest(endpoint: .userState, body: nil)
    
    #expect(request.method == .post)
  }
  
  @Test func testExchangeAPIRequest_pathIsCorrect() throws {
    let request = ExchangeAPIRequest(endpoint: .placeOrder, body: nil)
    
    #expect(request.path == "/exchange")
    #expect(request.method == .post)
  }
  
  @Test func testExchangeAPIRequest_methodIsPost() throws {
    let request = ExchangeAPIRequest(endpoint: .cancel, body: nil)
    
    #expect(request.method == .post)
  }
}
