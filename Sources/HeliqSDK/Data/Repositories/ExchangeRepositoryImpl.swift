//
//  ExchangeRepositoryImpl.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct AnyCodable: Encodable {
  public let value: Any
  
  public init(_ value: Any) {
    self.value = value
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    if let string = value as? String {
      try container.encode(string)
    } else if let int = value as? Int {
      try container.encode(int)
    } else if let double = value as? Double {
      try container.encode(double)
    } else if let bool = value as? Bool {
      try container.encode(bool)
    } else {
      try container.encodeNil()
    }
  }
}

public enum ExchangeEndpoint: Sendable {
  case placeOrder
  case bulkOrders
  case cancel
  case cancelByCloid
  case cancelAll
  case modifyOrder
  case modifyByCloid
  case setLeverage
  case setMarginMode
  case transfer
  case sendToAddress
  case spotTransfer
  case vaultTransfer
  case updateBuilder
  case scheduleCancel
  case setReferrer
  case convertToMultiSig
  case usdSend
  
  var path: String { "/exchange" }
  
  var typeString: String {
    switch self {
    case .placeOrder: return "order"
    case .bulkOrders: return "bulkOrders"
    case .cancel: return "cancel"
    case .cancelByCloid: return "cancelByCloid"
    case .cancelAll: return "cancelAll"
    case .modifyOrder: return "modify"
    case .modifyByCloid: return "modifyByCloid"
    case .setLeverage: return "setLeverage"
    case .setMarginMode: return "setMarginMode"
    case .transfer: return "transfer"
    case .sendToAddress: return "sendToAddress"
    case .spotTransfer: return "spotTransfer"
    case .vaultTransfer: return "vaultTransfer"
    case .updateBuilder: return "updateBuilder"
    case .scheduleCancel: return "scheduleCancel"
    case .setReferrer: return "setReferrer"
    case .convertToMultiSig: return "convertToMultiSig"
    case .usdSend: return "usdSend"
    }
  }
}

public struct ExchangeAPIRequest: APIRouterProtocol, Sendable {
  public let endpoint: ExchangeEndpoint
  private let _body: Data?
  
  public var path: String { endpoint.path }
  public var method: HTTPMethod { .post }
  public var body: Data? { _body }
  
  public init(endpoint: ExchangeEndpoint, body: Data?) {
    self.endpoint = endpoint
    self._body = body
  }
}

public final class ExchangeRepositoryImpl: ExchangeRepository, @unchecked Sendable {
  private let apiClient: APIClient
  private let transactionBuilder: TransactionBuilder
  
  public init(apiClient: APIClient, transactionBuilder: TransactionBuilder = TransactionBuilder()) {
    self.apiClient = apiClient
    self.transactionBuilder = transactionBuilder
  }
  
  public func placeOrder(_ order: OrderRequest) async throws -> OrderResponse {
    let transaction = try transactionBuilder.buildOrderTransaction(order: order)
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .placeOrder, body: data)
    return try await apiClient.request(request) as OrderResponse
  }
  
  public func bulkOrders(_ orders: [OrderRequest]) async throws -> BulkOrderResponse {
    let transactions = try orders.map { try transactionBuilder.buildOrderTransaction(order: $0) }
    let wrapper: [String: Any] = ["type": "bulkOrders", "orders": transactions]
    let data = try JSONSerialization.data(withJSONObject: wrapper)
    let request = ExchangeAPIRequest(endpoint: .bulkOrders, body: data)
    return try await apiClient.request(request) as BulkOrderResponse
  }
  
  public func cancelOrder(orderId: String, asset: Int) async throws -> CancelResponse {
    let transaction = transactionBuilder.buildCancelTransaction(orderId: orderId, asset: asset)
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .cancel, body: data)
    return try await apiClient.request(request) as CancelResponse
  }
  
  public func cancelByCloid(cloid: String, asset: Int) async throws -> CancelResponse {
    let transaction = transactionBuilder.buildCancelByCloidTransaction(cloid: cloid, asset: asset)
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .cancelByCloid, body: data)
    return try await apiClient.request(request) as CancelResponse
  }
  
  public func cancelAll() async throws -> CancelAllResponse {
    let transaction = transactionBuilder.buildCancelAllTransaction()
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .cancelAll, body: data)
    return try await apiClient.request(request) as CancelAllResponse
  }
  
  public func modifyOrder(orderId: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse {
    var transaction: [String: Any] = [
      "type": "modify",
      "oid": orderId,
      "asset": asset
    ]
    if let size = size { transaction["size"] = size }
    if let price = price { transaction["price"] = price }
    
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .modifyOrder, body: data)
    return try await apiClient.request(request) as OrderResponse
  }
  
  public func modifyByCloid(cloid: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse {
    var transaction: [String: Any] = [
      "type": "modifyByCloid",
      "cloid": cloid,
      "asset": asset
    ]
    if let size = size { transaction["size"] = size }
    if let price = price { transaction["price"] = price }
    
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .modifyByCloid, body: data)
    return try await apiClient.request(request) as OrderResponse
  }
  
  public func setLeverage(asset: Int, leverage: Int) async throws -> SetLeverageResponse {
    let transaction = transactionBuilder.buildSetLeverageTransaction(asset: asset, leverage: leverage)
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .setLeverage, body: data)
    return try await apiClient.request(request) as SetLeverageResponse
  }
  
  public func setMarginMode(asset: Int, mode: MarginMode) async throws -> SetMarginModeResponse {
    let transaction: [String: Any] = [
      "type": "setMarginMode",
      "asset": asset,
      "mode": mode.rawValue
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .setMarginMode, body: data)
    return try await apiClient.request(request) as SetMarginModeResponse
  }
  
  public func transfer(fromAddress: String, toAddress: String, amount: Double, asset: Int) async throws -> TransferResponse {
    let transaction: [String: Any] = [
      "type": "transfer",
      "fromAddress": fromAddress,
      "toAddress": toAddress,
      "amount": amount,
      "asset": asset
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .transfer, body: data)
    return try await apiClient.request(request) as TransferResponse
  }
  
  public func sendToAddress(address: String, amount: Double, asset: Int) async throws -> SendToAddressResponse {
    let transaction: [String: Any] = [
      "type": "sendToAddress",
      "address": address,
      "amount": amount,
      "asset": asset
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .sendToAddress, body: data)
    return try await apiClient.request(request) as SendToAddressResponse
  }
  
  public func spotTransfer(toAddress: String, amount: Double, asset: Int) async throws -> SpotTransferResponse {
    let transaction: [String: Any] = [
      "type": "spotTransfer",
      "toAddress": toAddress,
      "amount": amount,
      "asset": asset
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .spotTransfer, body: data)
    return try await apiClient.request(request) as SpotTransferResponse
  }
  
  public func vaultTransfer(vaultTransfer: VaultTransfer) async throws -> VaultTransferResponse {
    let transaction: [String: Any] = [
      "type": "vaultTransfer",
      "fromVault": vaultTransfer.fromVault,
      "toVault": vaultTransfer.toVault,
      "usdcAmount": vaultTransfer.usdcAmount,
      "vaultAddress": vaultTransfer.vaultAddress as Any
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .vaultTransfer, body: data)
    return try await apiClient.request(request) as VaultTransferResponse
  }
  
  public func updateBuilder(builderAddress: String) async throws -> UpdateBuilderResponse {
    let transaction: [String: Any] = [
      "type": "updateBuilder",
      "builderAddress": builderAddress
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .updateBuilder, body: data)
    return try await apiClient.request(request) as UpdateBuilderResponse
  }
  
  public func scheduleCancel(time: Date) async throws -> ScheduleCancelResponse {
    let transaction: [String: Any] = [
      "type": "scheduleCancel",
      "time": Int(time.timeIntervalSince1970 * 1000)
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .scheduleCancel, body: data)
    return try await apiClient.request(request) as ScheduleCancelResponse
  }
  
  public func setReferrer(referrer: String) async throws -> SetReferrerResponse {
    let transaction: [String: Any] = [
      "type": "setReferrer",
      "referrer": referrer
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .setReferrer, body: data)
    return try await apiClient.request(request) as SetReferrerResponse
  }
  
  public func convertToMultiSigUser() async throws -> ConvertToMultiSigResponse {
    let transaction: [String: Any] = ["type": "convertToMultiSig"]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .convertToMultiSig, body: data)
    return try await apiClient.request(request) as ConvertToMultiSigResponse
  }
  
  public func usdSend(destination: String, amount: Double) async throws -> UsdSendResponse {
    let transaction: [String: Any] = [
      "type": "usdSend",
      "destination": destination,
      "amount": amount
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .usdSend, body: data)
    return try await apiClient.request(request) as UsdSendResponse
  }
}
