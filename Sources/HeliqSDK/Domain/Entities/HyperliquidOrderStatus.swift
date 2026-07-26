//
//  HyperliquidOrderStatus.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Typed response for Hyperliquid's `orderStatus` Info request.
public struct HyperliquidOrderStatus: Sendable, Equatable {
  public struct Order: Sendable, Equatable {
    public let coin: String
    public let side: String
    public let limitPrice: String
    public let size: String
    public let orderID: Int64
    public let timestamp: Date
    public let triggerCondition: String
    public let isTrigger: Bool
    public let triggerPrice: String
    public let isPositionTpsl: Bool
    public let reduceOnly: Bool
    public let orderType: String
    public let originalSize: String
    public let timeInForce: String
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

  public let status: String
  public let order: Order?
  public let statusTimestamp: Date?
  public var isKnownOrder: Bool { order != nil }

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
