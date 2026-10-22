//
//  ExchangeRepository.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines the interface for exchange repository operations.
public protocol ExchangeRepository: Sendable {
  /// Executes a typed official Perps action using the SDK signer.
  func executePerps(_ action: PerpsAction, context: PerpsExecutionContext) async throws -> PerpsActionResult
  /// Freezes the resolved action, network, nonce, and context for all multisig signers.
  func preparePerpsMultisig(action: PerpsAction, user: String, leader: String, nonce: Int64,
    context: PerpsExecutionContext) async throws -> PerpsMultisigPayload
  /// Signs the prepared payload with the configured wallet without resolving the action again.
  func signPerpsMultisig(_ payload: PerpsMultisigPayload) async throws -> PerpsMultisigSignature
  /// Submits a multisig action with signatures bound to one nonce and leader.
  func executeMultisig(_ request: PerpsMultisigRequest) async throws -> PerpsActionResult
  /// Performs the place order repository operation.
  func placeOrder(_ order: OrderRequest) async throws -> OrderResponse
  /// Performs the bulk orders repository operation.
  func bulkOrders(_ orders: [OrderRequest]) async throws -> BulkOrderResponse
  /// Performs the cancel order repository operation.
  func cancelOrder(orderId: String, asset: Int) async throws -> CancelResponse
  /// Performs the cancel by cloid repository operation.
  func cancelByCloid(cloid: String, asset: Int) async throws -> CancelResponse
  /// Performs the cancel all repository operation.
  func cancelAll() async throws -> CancelAllResponse
  /// Performs the modify order repository operation.
  func modifyOrder(orderId: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse
  /// Performs the modify by cloid repository operation.
  func modifyByCloid(cloid: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse
  /// Performs the set leverage repository operation.
  func setLeverage(asset: Int, leverage: Int) async throws -> SetLeverageResponse
  /// Performs the set margin mode repository operation.
  func setMarginMode(asset: Int, mode: MarginMode) async throws -> SetMarginModeResponse
  /// Performs the transfer repository operation.
  func transfer(fromAddress: String, toAddress: String, amount: Double, asset: Int) async throws -> TransferResponse
  /// Performs the send to address repository operation.
  func sendToAddress(address: String, amount: Double, asset: Int) async throws -> SendToAddressResponse
  /// Performs the spot transfer repository operation.
  func spotTransfer(toAddress: String, amount: Double, asset: Int) async throws -> SpotTransferResponse
  /// Performs the vault transfer repository operation.
  func vaultTransfer(vaultTransfer: VaultTransfer) async throws -> VaultTransferResponse
  /// Performs the update builder repository operation.
  func updateBuilder(builderAddress: String) async throws -> UpdateBuilderResponse
  /// Approves the caller's explicit maximum builder fee percentage.
  func updateBuilder(builderAddress: String, maxFeeRate: String) async throws -> UpdateBuilderResponse
  /// Performs the schedule cancel repository operation.
  func scheduleCancel(time: Date) async throws -> ScheduleCancelResponse
  /// Performs the set referrer repository operation.
  func setReferrer(referrer: String) async throws -> SetReferrerResponse
  /// Performs the convert to multi sig user repository operation.
  func convertToMultiSigUser() async throws -> ConvertToMultiSigResponse
  /// Converts the account using explicit signer addresses and approval threshold.
  func convertToMultiSigUser(authorizedUsers: [String], threshold: Int) async throws -> ConvertToMultiSigResponse
  /// Performs the usd send repository operation.
  func usdSend(destination: String, amount: Double) async throws -> UsdSendResponse
}

/// Defaults that reject permission-changing operations unsupported by a custom repository.
public extension ExchangeRepository {
  /// Throws a validation error unless the repository implements explicit builder-fee approval.
  func updateBuilder(builderAddress: String, maxFeeRate: String) async throws -> UpdateBuilderResponse {
    throw ValidationError.malformedData(reason: "Repository does not implement builder fee approval")
  }
  /// Throws a validation error unless the repository implements explicit multisig conversion.
  func convertToMultiSigUser(authorizedUsers: [String], threshold: Int) async throws -> ConvertToMultiSigResponse {
    throw ValidationError.malformedData(reason: "Repository does not implement multisig conversion")
  }
}

/// Represents a value for order response.
public struct OrderResponse: Sendable, Codable {
  /// The order id associated with this value.
  public let orderId: String?
  /// The status associated with this value.
  public let status: String
  /// The error associated with this value.
  public let error: String?
  /// The filled size associated with this value.
  public let filledSize: Double?
  /// The filled px associated with this value.
  public let filledPx: Double?
  
  /// Creates an instance with the supplied values.
  public init(orderId: String?, status: String, error: String? = nil, filledSize: Double? = nil, filledPx: Double? = nil) {
    self.orderId = orderId
    self.status = status
    self.error = error
    self.filledSize = filledSize
    self.filledPx = filledPx
  }
}

/// Represents a value for bulk order response.
public struct BulkOrderResponse: Sendable, Codable {
  /// The responses associated with this value.
  public let responses: [OrderResponse]
  
  /// Creates an instance with the supplied values.
  public init(responses: [OrderResponse]) {
    self.responses = responses
  }
}

/// Represents a value for cancel response.
public struct CancelResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  /// The error associated with this value.
  public let error: String?
  
  /// Creates an instance with the supplied values.
  public init(status: String, error: String? = nil) {
    self.status = status
    self.error = error
  }
}

/// Represents a value for cancel all response.
public struct CancelAllResponse: Sendable, Codable {
  /// The cancelled orders associated with this value.
  public let cancelledOrders: [String]
  /// The failed cancels associated with this value.
  public let failedCancels: [FailedCancel]
  
  /// Creates an instance with the supplied values.
  public init(cancelledOrders: [String], failedCancels: [FailedCancel]) {
    self.cancelledOrders = cancelledOrders
    self.failedCancels = failedCancels
  }
}

/// Represents a value for failed cancel.
public struct FailedCancel: Sendable, Codable {
  /// The order id associated with this value.
  public let orderId: String
  /// The error associated with this value.
  public let error: String
  
  /// Creates an instance with the supplied values.
  public init(orderId: String, error: String) {
    self.orderId = orderId
    self.error = error
  }
}

/// Represents a value for set leverage response.
public struct SetLeverageResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  /// The leverage associated with this value.
  public let leverage: Int
  
  /// Creates an instance with the supplied values.
  public init(status: String, leverage: Int) {
    self.status = status
    self.leverage = leverage
  }
}

/// Represents a value for set margin mode response.
public struct SetMarginModeResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  
  /// Creates an instance with the supplied values.
  public init(status: String) {
    self.status = status
  }
}

/// Represents a value for transfer response.
public struct TransferResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  /// The hash associated with this value.
  public let hash: String?
  
  /// Creates an instance with the supplied values.
  public init(status: String, hash: String? = nil) {
    self.status = status
    self.hash = hash
  }
}

/// Represents a value for send to address response.
public struct SendToAddressResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  /// The hash associated with this value.
  public let hash: String?
  
  /// Creates an instance with the supplied values.
  public init(status: String, hash: String? = nil) {
    self.status = status
    self.hash = hash
  }
}

/// Represents a value for spot transfer response.
public struct SpotTransferResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  
  /// Creates an instance with the supplied values.
  public init(status: String) {
    self.status = status
  }
}

/// Represents a value for vault transfer response.
public struct VaultTransferResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  
  /// Creates an instance with the supplied values.
  public init(status: String) {
    self.status = status
  }
}

/// Represents a value for update builder response.
public struct UpdateBuilderResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  
  /// Creates an instance with the supplied values.
  public init(status: String) {
    self.status = status
  }
}

/// Represents a value for schedule cancel response.
public struct ScheduleCancelResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  /// The scheduled time associated with this value.
  public let scheduledTime: Date
  
  /// Creates an instance with the supplied values.
  public init(status: String, scheduledTime: Date) {
    self.status = status
    self.scheduledTime = scheduledTime
  }
}

/// Represents a value for set referrer response.
public struct SetReferrerResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  
  /// Creates an instance with the supplied values.
  public init(status: String) {
    self.status = status
  }
}

/// Represents a value for convert to multi sig response.
public struct ConvertToMultiSigResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  
  /// Creates an instance with the supplied values.
  public init(status: String) {
    self.status = status
  }
}

/// Represents a value for usd send response.
public struct UsdSendResponse: Sendable, Codable {
  /// The status associated with this value.
  public let status: String
  /// The hash associated with this value.
  public let hash: String?
  
  /// Creates an instance with the supplied values.
  public init(status: String, hash: String? = nil) {
    self.status = status
    self.hash = hash
  }
}

/// Typed action conveniences and explicit unsupported-operation defaults for custom repositories.
public extension ExchangeRepository {
  /// Reports unsupported functionality unless a custom repository implements this typed operation.
  func executePerps(_ action: PerpsAction, context: PerpsExecutionContext) async throws -> PerpsActionResult {
    throw ValidationError.malformedData(reason: "Repository does not implement typed Perps actions")
  }
  /// Validates, signs, and submits one typed exchange action without automatic retries.
  func executePerps(_ action: PerpsAction) async throws -> PerpsActionResult {
    try await executePerps(action, context: .init())
  }
  /// Reports unsupported functionality unless a custom repository implements this typed operation.
  func executeMultisig(_ request: PerpsMultisigRequest) async throws -> PerpsActionResult {
    throw ValidationError.malformedData(reason: "Repository does not implement multisig submission")
  }
  /// Transfers exact USDC between Spot and Perps for standard accounts; shared or unresolved modes
  /// throw.
  func usdClassTransfer(amount: Decimal, toPerp: Bool) async throws -> PerpsActionResult {
    try await executePerps(.usdClassTransfer(amount: amount, toPerp: toPerp))
  }
  /// Transfers an exact token amount between explicit supported ledgers, including HIP-3 DEXs.
  func sendAsset(destination: String, source: PerpsLedger, destinationLedger: PerpsLedger,
    token: String, amount: Decimal, fromSubAccount: String = "") async throws -> PerpsActionResult {
    try await executePerps(.sendAsset(destination: destination, source: source,
      destinationLedger: destinationLedger, token: token, amount: amount, fromSubAccount: fromSubAccount))
  }
}

/// Multisig preparation and signing defaults that require an implementation from the repository.
public extension ExchangeRepository {
  /// Reports unsupported functionality unless a custom repository implements this typed operation.
  func preparePerpsMultisig(action: PerpsAction, user: String, leader: String, nonce: Int64,
    context: PerpsExecutionContext) async throws -> PerpsMultisigPayload {
    throw ValidationError.malformedData(reason: "Repository does not implement multisig preparation")
  }
  /// Reports unsupported functionality unless a custom repository implements this typed operation.
  func signPerpsMultisig(_ payload: PerpsMultisigPayload) async throws -> PerpsMultisigSignature {
    throw ValidationError.malformedData(reason: "Repository does not implement multisig signing")
  }
}
