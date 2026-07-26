//
//  InfoRepository.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public protocol InfoRepository: Sendable {
  func getUserState(address: String) async throws -> UserState
  func getSpotUserState(address: String) async throws -> SpotUserState
  func getAllMids() async throws -> AllMids
  func getAssetCtxs() async throws -> [AssetContext]
  func getSpotAssetCtxs() async throws -> [SpotAssetContext]
  func getCandleSnapshot(coin: String, interval: String, startTime: Date, endTime: Date) async throws -> [Candle]
  func getL2Book(coin: String) async throws -> L2Book
  func queryOrderByOid(orderId: String) async throws -> [Order]
  func queryOrderByCloid(cloid: String) async throws -> [Order]
  func queryFills(address: String) async throws -> [Fill]
  func queryUserFundings(address: String) async throws -> [UserFunding]
  func getMeta() async throws -> Meta
  func getSpotMeta() async throws -> Meta
  func getTime() async throws -> Date
  func fetchBuilderFee(builderAddress: String) async throws -> BuilderFee
}

public struct SpotUserState: Sendable, Codable {
  public let accountAddress: String
  public let spotPositions: [SpotPosition]
  public let totalUsdc: Double
  
  public init(accountAddress: String, spotPositions: [SpotPosition], totalUsdc: Double) {
    self.accountAddress = accountAddress
    self.spotPositions = spotPositions
    self.totalUsdc = totalUsdc
  }
}

public struct SpotPosition: Sendable, Codable {
  public let asset: Int
  public let totalSize: Double
  public let hold: Double
  
  public init(asset: Int, totalSize: Double, hold: Double) {
    self.asset = asset
    self.totalSize = totalSize
    self.hold = hold
  }
}

public struct Order: Sendable, Codable, Identifiable {
  public var id: String { oid }
  
  public let oid: String
  public let cloid: String?
  public let asset: Int
  public let side: OrderSide
  public let orderType: OrderType
  public let size: Double
  public let price: Double?
  public let filled: Double
  public let status: OrderStatus
  public let timestamp: Date
  
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

public enum OrderStatus: String, Sendable, Codable {
  case open, filled, cancelled, rejected, triggered
  case marginCanceled, vaultWithdrawalCanceled, openInterestCapCanceled
  case selfTradeCanceled, reduceOnlyCanceled, siblingFilledCanceled
}

public struct UserFunding: Sendable, Codable {
  public let asset: Int
  public let payment: Double
  public let rate: Double
  public let time: Date
  
  public init(asset: Int, payment: Double, rate: Double, time: Date) {
    self.asset = asset
    self.payment = payment
    self.rate = rate
    self.time = time
  }
}

public struct BuilderFee: Sendable, Codable {
  public let builderAddress: String
  public let feeBps: Int
  
  public init(builderAddress: String, feeBps: Int) {
    self.builderAddress = builderAddress
    self.feeBps = feeBps
  }
}
