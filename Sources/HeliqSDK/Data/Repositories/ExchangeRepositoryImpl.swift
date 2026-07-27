//
//  ExchangeRepositoryImpl.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents any codable data.
public struct AnyCodable: Encodable {
  /// The value.
  public let value: Any
  
  /// Creates a any codable.
  public init(_ value: Any) {
    self.value = value
  }
  
  /// Performs the encode operation.
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

/// Defines exchange endpoint values.
public enum ExchangeEndpoint: Sendable {
  /// The `placeOrder` option.
  case placeOrder
  /// The `bulkOrders` option.
  case bulkOrders
  /// The `cancel` option.
  case cancel
  /// The `cancelByCloid` option.
  case cancelByCloid
  /// The `cancelAll` option.
  case cancelAll
  /// The `modifyOrder` option.
  case modifyOrder
  /// The `modifyByCloid` option.
  case modifyByCloid
  /// The `setLeverage` option.
  case setLeverage
  /// The `setMarginMode` option.
  case setMarginMode
  /// The `transfer` option.
  case transfer
  /// The `sendToAddress` option.
  case sendToAddress
  /// The `spotTransfer` option.
  case spotTransfer
  /// The `vaultTransfer` option.
  case vaultTransfer
  /// The `updateBuilder` option.
  case updateBuilder
  /// The `scheduleCancel` option.
  case scheduleCancel
  /// The `setReferrer` option.
  case setReferrer
  /// The `convertToMultiSig` option.
  case convertToMultiSig
  /// The `usdSend` option.
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

/// Represents exchange apirequest data.
public struct ExchangeAPIRequest: APIRouterProtocol, Sendable {
  /// The endpoint.
  public let endpoint: ExchangeEndpoint
  private let _body: Data?
  
  /// The path.
  public var path: String { endpoint.path }
  /// The method.
  public var method: HTTPMethod { .post }
  /// The body.
  public var body: Data? { _body }
  
  /// Creates a exchange apirequest.
  public init(endpoint: ExchangeEndpoint, body: Data?) {
    self.endpoint = endpoint
    self._body = body
  }
}

/// Provides exchange repository impl functionality.
public final class ExchangeRepositoryImpl: ExchangeRepository, @unchecked Sendable {
  private let apiClient: APIClient
  private let transactionBuilder: TransactionBuilder
  
  /// Creates a exchange repository impl.
  public init(apiClient: APIClient, transactionBuilder: TransactionBuilder = TransactionBuilder()) {
    self.apiClient = apiClient
    self.transactionBuilder = transactionBuilder
  }
  
  /// Performs the place order operation.
  public func placeOrder(_ order: OrderRequest) async throws -> OrderResponse {
    let transaction = try transactionBuilder.buildOrderTransaction(order: order)
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .placeOrder, body: data)
    return try await apiClient.request(request) as OrderResponse
  }
  
  /// Performs the bulk orders operation.
  public func bulkOrders(_ orders: [OrderRequest]) async throws -> BulkOrderResponse {
    let transactions = try orders.map { try transactionBuilder.buildOrderTransaction(order: $0) }
    let wrapper: [String: Any] = ["type": "bulkOrders", "orders": transactions]
    let data = try JSONSerialization.data(withJSONObject: wrapper)
    let request = ExchangeAPIRequest(endpoint: .bulkOrders, body: data)
    return try await apiClient.request(request) as BulkOrderResponse
  }
  
  /// Performs the cancel order operation.
  public func cancelOrder(orderId: String, asset: Int) async throws -> CancelResponse {
    let transaction = transactionBuilder.buildCancelTransaction(orderId: orderId, asset: asset)
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .cancel, body: data)
    return try await apiClient.request(request) as CancelResponse
  }
  
  /// Performs the cancel by cloid operation.
  public func cancelByCloid(cloid: String, asset: Int) async throws -> CancelResponse {
    let transaction = transactionBuilder.buildCancelByCloidTransaction(cloid: cloid, asset: asset)
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .cancelByCloid, body: data)
    return try await apiClient.request(request) as CancelResponse
  }
  
  /// Performs the cancel all operation.
  public func cancelAll() async throws -> CancelAllResponse {
    let transaction = transactionBuilder.buildCancelAllTransaction()
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .cancelAll, body: data)
    return try await apiClient.request(request) as CancelAllResponse
  }
  
  /// Performs the modify order operation.
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
  
  /// Performs the modify by cloid operation.
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
  
  /// Performs the set leverage operation.
  public func setLeverage(asset: Int, leverage: Int) async throws -> SetLeverageResponse {
    let transaction = transactionBuilder.buildSetLeverageTransaction(asset: asset, leverage: leverage)
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .setLeverage, body: data)
    return try await apiClient.request(request) as SetLeverageResponse
  }
  
  /// Performs the set margin mode operation.
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
  
  /// Performs the transfer operation.
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
  
  /// Performs the send to address operation.
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
  
  /// Performs the spot transfer operation.
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
  
  /// Performs the vault transfer operation.
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
  
  /// Performs the update builder operation.
  public func updateBuilder(builderAddress: String) async throws -> UpdateBuilderResponse {
    let transaction: [String: Any] = [
      "type": "updateBuilder",
      "builderAddress": builderAddress
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .updateBuilder, body: data)
    return try await apiClient.request(request) as UpdateBuilderResponse
  }
  
  /// Performs the schedule cancel operation.
  public func scheduleCancel(time: Date) async throws -> ScheduleCancelResponse {
    let transaction: [String: Any] = [
      "type": "scheduleCancel",
      "time": Int(time.timeIntervalSince1970 * 1000)
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .scheduleCancel, body: data)
    return try await apiClient.request(request) as ScheduleCancelResponse
  }
  
  /// Performs the set referrer operation.
  public func setReferrer(referrer: String) async throws -> SetReferrerResponse {
    let transaction: [String: Any] = [
      "type": "setReferrer",
      "referrer": referrer
    ]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .setReferrer, body: data)
    return try await apiClient.request(request) as SetReferrerResponse
  }
  
  /// Performs the convert to multi sig user operation.
  public func convertToMultiSigUser() async throws -> ConvertToMultiSigResponse {
    let transaction: [String: Any] = ["type": "convertToMultiSig"]
    let data = try JSONSerialization.data(withJSONObject: transaction)
    let request = ExchangeAPIRequest(endpoint: .convertToMultiSig, body: data)
    return try await apiClient.request(request) as ConvertToMultiSigResponse
  }
  
  /// Performs the usd send operation.
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
