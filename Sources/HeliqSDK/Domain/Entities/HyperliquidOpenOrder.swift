//
//  HyperliquidOpenOrder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// A stable typed projection of Hyperliquid's `openOrders` response.
/// Decimal protocol values remain strings to preserve server precision.
public struct HyperliquidOpenOrder: Sendable, Equatable {
  /// Represents a set of supported values for side.
  public enum Side: String, Sendable, Equatable {
    /// The `bid` case.
    case bid
    /// The `ask` case.
    case ask
  }

  /// The coin associated with this value.
  public let coin: String
  /// The limit price associated with this value.
  public let limitPrice: String
  /// The order i d associated with this value.
  public let orderID: Int64
  /// The side associated with this value.
  public let side: Side
  /// The size associated with this value.
  public let size: String
  /// The timestamp associated with this value.
  public let timestamp: Date

  /// Decodes this value from the supplied response data.
  public static func decodeList(_ data: Data) throws -> [Self] {
    try JSONDecoder().decode([DTO].self, from: data).map(Self.init)
  }

  private init(_ dto: DTO) {
    coin = dto.coin
    limitPrice = dto.limitPrice
    orderID = dto.orderID
    side = dto.side == "A" ? .ask : .bid
    size = dto.size
    timestamp = Date(timeIntervalSince1970: Double(dto.timestamp) / 1_000)
  }

  private struct DTO: Decodable {
    let coin: String
    let limitPrice: String
    let orderID: Int64
    let side: String
    let size: String
    let timestamp: Int64

    enum CodingKeys: String, CodingKey {
      case coin
      case limitPrice = "limitPx"
      case orderID = "oid"
      case side
      case size = "sz"
      case timestamp
    }
  }
}
