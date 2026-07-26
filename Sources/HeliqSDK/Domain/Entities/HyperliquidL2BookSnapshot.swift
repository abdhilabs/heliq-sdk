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
  public struct Level: Sendable, Equatable {
    public let price: String
    public let size: String
    public let orderCount: Int

    fileprivate init(price: String, size: String, orderCount: Int) {
      self.price = price
      self.size = size
      self.orderCount = orderCount
    }
  }

  public let coin: String
  public let timestamp: Date
  public let bids: [Level]
  public let asks: [Level]

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
