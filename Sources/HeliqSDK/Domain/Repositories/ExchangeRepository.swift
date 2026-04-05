//
//  ExchangeRepository.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public protocol ExchangeRepository: Sendable {
  func placeOrder(_ order: OrderRequest) async throws -> OrderResponse
  func bulkOrders(_ orders: [OrderRequest]) async throws -> BulkOrderResponse
  func cancelOrder(orderId: String, asset: Int) async throws -> CancelResponse
  func cancelByCloid(cloid: String, asset: Int) async throws -> CancelResponse
  func cancelAll() async throws -> CancelAllResponse
  func modifyOrder(orderId: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse
  func modifyByCloid(cloid: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse
  func setLeverage(asset: Int, leverage: Int) async throws -> SetLeverageResponse
  func setMarginMode(asset: Int, mode: MarginMode) async throws -> SetMarginModeResponse
  func transfer(fromAddress: String, toAddress: String, amount: Double, asset: Int) async throws -> TransferResponse
  func sendToAddress(address: String, amount: Double, asset: Int) async throws -> SendToAddressResponse
  func spotTransfer(toAddress: String, amount: Double, asset: Int) async throws -> SpotTransferResponse
  func vaultTransfer(vaultTransfer: VaultTransfer) async throws -> VaultTransferResponse
  func updateBuilder(builderAddress: String) async throws -> UpdateBuilderResponse
  func scheduleCancel(time: Date) async throws -> ScheduleCancelResponse
  func setReferrer(referrer: String) async throws -> SetReferrerResponse
  func convertToMultiSigUser() async throws -> ConvertToMultiSigResponse
  func usdSend(destination: String, amount: Double) async throws -> UsdSendResponse
}

public struct OrderResponse: Sendable, Codable {
  public let orderId: String?
  public let status: String
  public let error: String?
  public let filledSize: Double?
  public let filledPx: Double?
  
  public init(orderId: String?, status: String, error: String? = nil, filledSize: Double? = nil, filledPx: Double? = nil) {
    self.orderId = orderId
    self.status = status
    self.error = error
    self.filledSize = filledSize
    self.filledPx = filledPx
  }
}

public struct BulkOrderResponse: Sendable, Codable {
  public let responses: [OrderResponse]
  
  public init(responses: [OrderResponse]) {
    self.responses = responses
  }
}

public struct CancelResponse: Sendable, Codable {
  public let status: String
  public let error: String?
  
  public init(status: String, error: String? = nil) {
    self.status = status
    self.error = error
  }
}

public struct CancelAllResponse: Sendable, Codable {
  public let cancelledOrders: [String]
  public let failedCancels: [FailedCancel]
  
  public init(cancelledOrders: [String], failedCancels: [FailedCancel]) {
    self.cancelledOrders = cancelledOrders
    self.failedCancels = failedCancels
  }
}

public struct FailedCancel: Sendable, Codable {
  public let orderId: String
  public let error: String
  
  public init(orderId: String, error: String) {
    self.orderId = orderId
    self.error = error
  }
}

public struct SetLeverageResponse: Sendable, Codable {
  public let status: String
  public let leverage: Int
  
  public init(status: String, leverage: Int) {
    self.status = status
    self.leverage = leverage
  }
}

public struct SetMarginModeResponse: Sendable, Codable {
  public let status: String
  
  public init(status: String) {
    self.status = status
  }
}

public struct TransferResponse: Sendable, Codable {
  public let status: String
  public let hash: String?
  
  public init(status: String, hash: String? = nil) {
    self.status = status
    self.hash = hash
  }
}

public struct SendToAddressResponse: Sendable, Codable {
  public let status: String
  public let hash: String?
  
  public init(status: String, hash: String? = nil) {
    self.status = status
    self.hash = hash
  }
}

public struct SpotTransferResponse: Sendable, Codable {
  public let status: String
  
  public init(status: String) {
    self.status = status
  }
}

public struct VaultTransferResponse: Sendable, Codable {
  public let status: String
  
  public init(status: String) {
    self.status = status
  }
}

public struct UpdateBuilderResponse: Sendable, Codable {
  public let status: String
  
  public init(status: String) {
    self.status = status
  }
}

public struct ScheduleCancelResponse: Sendable, Codable {
  public let status: String
  public let scheduledTime: Date
  
  public init(status: String, scheduledTime: Date) {
    self.status = status
    self.scheduledTime = scheduledTime
  }
}

public struct SetReferrerResponse: Sendable, Codable {
  public let status: String
  
  public init(status: String) {
    self.status = status
  }
}

public struct ConvertToMultiSigResponse: Sendable, Codable {
  public let status: String
  
  public init(status: String) {
    self.status = status
  }
}

public struct UsdSendResponse: Sendable, Codable {
  public let status: String
  public let hash: String?
  
  public init(status: String, hash: String? = nil) {
    self.status = status
    self.hash = hash
  }
}
