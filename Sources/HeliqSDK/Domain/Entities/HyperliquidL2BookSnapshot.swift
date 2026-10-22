//
//  HyperliquidL2BookSnapshot.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// A side-preserving projection of Hyperliquid's `l2Book` response.
/// Price and size remain protocol strings to preserve server precision.
public struct HyperliquidL2BookSnapshot: Sendable, Equatable {
  /// Represents a value for level.
  public struct Level: Sendable, Equatable {
    /// The price associated with this value.
    public let price: String
    /// The size associated with this value.
    public let size: String
    /// The order count associated with this value.
    public let orderCount: Int

    fileprivate init(price: String, size: String, orderCount: Int) {
      self.price = price
      self.size = size
      self.orderCount = orderCount
    }
  }

  /// The coin associated with this value.
  public let coin: String
  /// The timestamp associated with this value.
  public let timestamp: Date
  /// The bids associated with this value.
  public let bids: [Level]
  /// The asks associated with this value.
  public let asks: [Level]

  /// Decodes this value from the supplied response data.
  public static func decode(_ data: Data) throws -> Self {
    let dto = try JSONDecoder().decode(DTO.self, from: data)
    guard dto.levels.count == 2 else {
      throw ValidationError.malformedData(reason: "l2Book requires bid and ask level arrays")
    }
    return Self(
      coin: dto.coin,
      timestamp: Date(timeIntervalSince1970: Double(dto.timestamp) / 1_000),
      bids: dto.levels[0].map { Level(price: $0.price, size: $0.size, orderCount: $0.orderCount) },
      asks: dto.levels[1].map { Level(price: $0.price, size: $0.size, orderCount: $0.orderCount) }
    )
  }

  private init(coin: String, timestamp: Date, bids: [Level], asks: [Level]) {
    self.coin = coin
    self.timestamp = timestamp
    self.bids = bids
    self.asks = asks
  }

  private struct DTO: Decodable {
    let coin: String
    let timestamp: Int64
    let levels: [[LevelDTO]]

    enum CodingKeys: String, CodingKey {
      case coin
      case timestamp = "time"
      case levels
    }
  }

  private struct LevelDTO: Decodable {
    let price: String
    let size: String
    let orderCount: Int

    enum CodingKeys: String, CodingKey {
      case price = "px"
      case size = "sz"
      case orderCount = "n"
    }
  }

}
