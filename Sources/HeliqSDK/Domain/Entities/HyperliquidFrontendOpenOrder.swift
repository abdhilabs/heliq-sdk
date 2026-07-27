//
//  HyperliquidFrontendOpenOrder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for hyperliquid frontend open order.
public struct HyperliquidFrontendOpenOrder: Sendable, Equatable {
  /// The coin associated with this value.
  public let coin: String
  /// The order i d associated with this value.
  public let orderID: Int64
  /// The side associated with this value.
  public let side: String
  /// The limit price associated with this value.
  public let limitPrice: String
  /// The original size associated with this value.
  public let originalSize: String
  /// The size associated with this value.
  public let size: String
  /// The timestamp associated with this value.
  public let timestamp: Int64
  /// The order type associated with this value.
  public let orderType: String
  /// The is trigger associated with this value.
  public let isTrigger: Bool
  /// The is position tpsl associated with this value.
  public let isPositionTpsl: Bool
  /// The reduce only associated with this value.
  public let reduceOnly: Bool
  /// The trigger condition associated with this value.
  public let triggerCondition: String
  /// The trigger price associated with this value.
  public let triggerPrice: String

  /// Decodes this value from the supplied response data.
  public static func decodeList(_ data: Data) throws -> [Self] {
    try JSONDecoder().decode([DTO].self, from: data).map(Self.init)
  }

  private struct DTO: Decodable {
    let coin: String
    let oid: Int64
    let side, limitPx, origSz, sz: String
    let timestamp: Int64
    let orderType: String
    let isTrigger, isPositionTpsl, reduceOnly: Bool
    let triggerCondition, triggerPx: String
  }

  private init(_ dto: DTO) {
    coin = dto.coin; orderID = dto.oid; side = dto.side; limitPrice = dto.limitPx
    originalSize = dto.origSz; size = dto.sz; timestamp = dto.timestamp; orderType = dto.orderType
    isTrigger = dto.isTrigger; isPositionTpsl = dto.isPositionTpsl; reduceOnly = dto.reduceOnly
    triggerCondition = dto.triggerCondition; triggerPrice = dto.triggerPx
  }
}
