//
//  InfoRepository.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines the interface for info repository operations.
public protocol InfoRepository: Sendable {
  /// Queries an official Perps endpoint using its typed request and response.
  func perps<Response: Sendable>(_ query: PerpsQuery<Response>) async throws -> Response
  /// Returns mode-aware Spot balances and Perps collateral summaries.
  func getBalances(address: String) async throws -> AccountBalances
  /// Reads balances for explicit DEXs; the default overload covers validator Perps only.
  func getBalances(address: String, dexes: [String]) async throws -> AccountBalances
  /// Returns coin-specific trading capacity from the exchange.
  func getActiveAssetData(address: String, coin: String) async throws -> PerpsActiveAssetData
  /// Performs the get user state repository operation.
  func getUserState(address: String) async throws -> UserState
  /// Performs the get spot user state repository operation.
  func getSpotUserState(address: String) async throws -> SpotUserState
  /// Performs the get all mids repository operation.
  func getAllMids() async throws -> AllMids
  /// Performs the get asset ctxs repository operation.
  func getAssetCtxs() async throws -> [AssetContext]
  /// Performs the get spot asset ctxs repository operation.
  func getSpotAssetCtxs() async throws -> [SpotAssetContext]
  /// Performs the get candle snapshot repository operation.
  func getCandleSnapshot(coin: String, interval: String, startTime: Date, endTime: Date) async throws -> [Candle]
  /// Performs the get l2 book repository operation.
  func getL2Book(coin: String) async throws -> L2Book
  /// Performs the query order by oid repository operation.
  func queryOrderByOid(orderId: String) async throws -> [Order]
  /// Looks up an order for the specified user; an unknown order returns an empty array.
  func queryOrderByOid(orderId: String, address: String) async throws -> [Order]
  /// Performs the query order by cloid repository operation.
  func queryOrderByCloid(cloid: String) async throws -> [Order]
  /// Looks up a client order ID for the specified user.
  func queryOrderByCloid(cloid: String, address: String) async throws -> [Order]
  /// Performs the query fills repository operation.
  func queryFills(address: String) async throws -> [Fill]
  /// Performs the query user fundings repository operation.
  func queryUserFundings(address: String) async throws -> [UserFunding]
  /// Performs the get meta repository operation.
  func getMeta() async throws -> Meta
  /// Performs the get spot meta repository operation.
  func getSpotMeta() async throws -> Meta
  /// Performs the get time repository operation.
  func getTime() async throws -> Date
  /// Performs the fetch builder fee repository operation.
  func fetchBuilderFee(builderAddress: String) async throws -> BuilderFee
  /// Retrieves a user's approved builder fee in basis points.
  func fetchBuilderFee(builderAddress: String, address: String) async throws -> BuilderFee
}

/// Represents a value for spot user state.
public struct SpotUserState: Sendable, Codable {
  /// The account address associated with this value.
  public let accountAddress: String
  /// The spot positions associated with this value.
  public let spotPositions: [SpotPosition]
  /// The total usdc associated with this value.
  public let totalUsdc: Double
  
  /// Creates an instance with the supplied values.
  public init(accountAddress: String, spotPositions: [SpotPosition], totalUsdc: Double) {
    self.accountAddress = accountAddress
    self.spotPositions = spotPositions
    self.totalUsdc = totalUsdc
  }
}

/// Represents a value for spot position.
public struct SpotPosition: Sendable, Codable {
  /// The asset associated with this value.
  public let asset: Int
  /// The total size associated with this value.
  public let totalSize: Double
  /// The hold associated with this value.
  public let hold: Double
  
  /// Creates an instance with the supplied values.
  public init(asset: Int, totalSize: Double, hold: Double) {
    self.asset = asset
    self.totalSize = totalSize
    self.hold = hold
  }
}

/// Represents a value for order.
public struct Order: Sendable, Codable, Identifiable {
  /// The id value.
  public var id: String { oid }
  
  /// The oid associated with this value.
  public let oid: String
  /// The cloid associated with this value.
  public let cloid: String?
  /// The asset associated with this value.
  public let asset: Int
  /// The side associated with this value.
  public let side: OrderSide
  /// The order type associated with this value.
  public let orderType: OrderType
  /// The size associated with this value.
  public let size: Double
  /// The price associated with this value.
  public let price: Double?
  /// The filled associated with this value.
  public let filled: Double
  /// The status associated with this value.
  public let status: OrderStatus
  /// The timestamp associated with this value.
  public let timestamp: Date
  
  /// Creates an instance with the supplied values.
  public init(
    oid: String,
    cloid: String? = nil,
    asset: Int,
    side: OrderSide,
    orderType: OrderType,
    size: Double,
    price: Double? = nil,
    filled: Double,
    status: OrderStatus,
    timestamp: Date
  ) {
    self.oid = oid
    self.cloid = cloid
    self.asset = asset
    self.side = side
    self.orderType = orderType
    self.size = size
    self.price = price
    self.filled = filled
    self.status = status
    self.timestamp = timestamp
  }
}

/// Represents a set of supported values for order status.
public enum OrderStatus: String, Sendable, Codable {
  /// The `open` case.
  case open
  /// The `filled` case.
  case filled
  /// The `cancelled` case.
  case cancelled
  /// The `rejected` case.
  case rejected
  /// The `triggered` case.
  case triggered
  /// The `marginCanceled` case.
  case marginCanceled
  /// The `vaultWithdrawalCanceled` case.
  case vaultWithdrawalCanceled
  /// The `openInterestCapCanceled` case.
  case openInterestCapCanceled
  /// The `selfTradeCanceled` case.
  case selfTradeCanceled
  /// The `reduceOnlyCanceled` case.
  case reduceOnlyCanceled
  /// The `siblingFilledCanceled` case.
  case siblingFilledCanceled
}

/// Represents a value for user funding.
public struct UserFunding: Sendable, Codable {
  /// The asset associated with this value.
  public let asset: Int
  /// The payment associated with this value.
  public let payment: Double
  /// The rate associated with this value.
  public let rate: Double
  /// The time associated with this value.
  public let time: Date
  
  /// Creates an instance with the supplied values.
  public init(asset: Int, payment: Double, rate: Double, time: Date) {
    self.asset = asset
    self.payment = payment
    self.rate = rate
    self.time = time
  }
}

/// Represents a value for builder fee.
public struct BuilderFee: Sendable, Codable {
  /// The builder address associated with this value.
  public let builderAddress: String
  /// Maximum approved fee in basis points, including fractional basis points.
  public let feeBps: Double
  
  /// Creates an instance with the supplied values.
  public init(builderAddress: String, feeBps: Double) {
    self.builderAddress = builderAddress
    self.feeBps = feeBps
  }
}

public extension InfoRepository {
  /// Reports unsupported functionality unless a custom repository implements this typed operation.
  func perps<Response: Sendable>(_ query: PerpsQuery<Response>) async throws -> Response {
    throw ValidationError.malformedData(reason: "Repository does not implement typed Perps queries")
  }
  /// Reports unsupported functionality unless a custom repository implements this typed operation.
  func getBalances(address: String) async throws -> AccountBalances {
    throw ValidationError.malformedData(reason: "Repository does not implement balances")
  }
  /// Reads leverage and trading capacity for the address and exact metadata coin name.
  func getActiveAssetData(address: String, coin: String) async throws -> PerpsActiveAssetData {
    try await perps(.activeAsset(address: address, coin: coin))
  }
}

public extension InfoRepository {
  /// Reports unsupported functionality unless a custom repository implements this typed operation.
  func getBalances(address: String, dexes: [String]) async throws -> AccountBalances {
    throw ValidationError.malformedData(reason: "Repository does not implement DEX-scoped balances")
  }
}
