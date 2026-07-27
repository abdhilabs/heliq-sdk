//
//  HyperliquidOrderStatus.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Typed response for Hyperliquid's `orderStatus` Info request.
public struct HyperliquidOrderStatus: Sendable, Equatable {
  /// Represents a value for order.
  public struct Order: Sendable, Equatable {
    /// The coin associated with this value.
    public let coin: String
    /// The side associated with this value.
    public let side: String
    /// The limit price associated with this value.
    public let limitPrice: String
    /// The size associated with this value.
    public let size: String
    /// The order i d associated with this value.
    public let orderID: Int64
    /// The timestamp associated with this value.
    public let timestamp: Date
    /// The trigger condition associated with this value.
    public let triggerCondition: String
    /// The is trigger associated with this value.
    public let isTrigger: Bool
    /// The trigger price associated with this value.
    public let triggerPrice: String
    /// The is position tpsl associated with this value.
    public let isPositionTpsl: Bool
    /// The reduce only associated with this value.
    public let reduceOnly: Bool
    /// The order type associated with this value.
    public let orderType: String
    /// The original size associated with this value.
    public let originalSize: String
    /// The time in force associated with this value.
    public let timeInForce: String
    /// The cloid associated with this value.
    public let cloid: String?

    fileprivate init(_ dto: OrderDTO) {
      coin = dto.coin
      side = dto.side
      limitPrice = dto.limitPrice
      size = dto.size
      orderID = dto.orderID
      timestamp = Date(timeIntervalSince1970: Double(dto.timestamp) / 1_000)
      triggerCondition = dto.triggerCondition
      isTrigger = dto.isTrigger
      triggerPrice = dto.triggerPrice
      isPositionTpsl = dto.isPositionTpsl
      reduceOnly = dto.reduceOnly
      orderType = dto.orderType
      originalSize = dto.originalSize
      timeInForce = dto.timeInForce
      cloid = dto.cloid
    }
  }

  /// The status associated with this value.
  public let status: String
  /// The order associated with this value.
  public let order: Order?
  /// The status timestamp associated with this value.
  public let statusTimestamp: Date?
  /// The is known order value.
  public var isKnownOrder: Bool { order != nil }

  /// Decodes this value from the supplied response data.
  public static func decode(_ data: Data) throws -> Self {
    let dto = try JSONDecoder().decode(DTO.self, from: data)
    guard let container = dto.order else {
      return Self(status: dto.status, order: nil, statusTimestamp: nil)
    }
    return Self(
      status: container.status,
      order: .init(container.order),
      statusTimestamp: Date(timeIntervalSince1970: Double(container.statusTimestamp) / 1_000)
    )
  }

  fileprivate struct DTO: Decodable {
    let status: String
    let order: Container?
  }

  fileprivate struct Container: Decodable {
    let order: OrderDTO
    let status: String
    let statusTimestamp: Int64
  }

  fileprivate struct OrderDTO: Decodable {
    let coin: String
    let side: String
    let limitPrice: String
    let size: String
    let orderID: Int64
    let timestamp: Int64
    let triggerCondition: String
    let isTrigger: Bool
    let triggerPrice: String
    let isPositionTpsl: Bool
    let reduceOnly: Bool
    let orderType: String
    let originalSize: String
    let timeInForce: String
    let cloid: String?

    enum CodingKeys: String, CodingKey {
      case coin, side, timestamp, triggerCondition, isTrigger, isPositionTpsl, reduceOnly, orderType, cloid
      case limitPrice = "limitPx"
      case size = "sz"
      case orderID = "oid"
      case triggerPrice = "triggerPx"
      case originalSize = "origSz"
      case timeInForce = "tif"
    }
  }

}
