//
//  L2Book.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for l2 book.
public struct L2Book: Sendable, Codable {
  /// The coin associated with this value.
  public let coin: String
  /// The levels associated with this value.
  public let levels: [L2Level]
  /// The timestamp associated with this value.
  public let timestamp: Date
  
  /// Creates an instance with the supplied values.
  public init(coin: String, levels: [L2Level], timestamp: Date) {
    self.coin = coin
    self.levels = levels
    self.timestamp = timestamp
  }

  /// Decodes Hyperliquid's nested bid/ask L2 wire response.
  public static func decodeLiveWire(_ data: Data) throws -> Self {
    struct WireLevel: Decodable {
      let px: String
      let sz: String
    }
    struct WireBook: Decodable {
      let coin: String
      let time: Int
      let levels: [[WireLevel]]
    }

    let wire = try JSONDecoder().decode(WireBook.self, from: data)
    guard wire.levels.count == 2 else {
      throw ValidationError.malformedData(reason: "l2Book requires bid and ask levels")
    }
    let bids = try wire.levels[0].map { level -> L2Level in
      guard let price = Double(level.px), let size = Double(level.sz) else {
        throw ValidationError.malformedData(reason: "l2Book bid has invalid decimal values")
      }
      return L2Level(price: price, size: size, side: .buy)
    }
    let asks = try wire.levels[1].map { level -> L2Level in
      guard let price = Double(level.px), let size = Double(level.sz) else {
        throw ValidationError.malformedData(reason: "l2Book ask has invalid decimal values")
      }
      return L2Level(price: price, size: size, side: .sell)
    }
    return L2Book(
      coin: wire.coin,
      levels: bids + asks,
      timestamp: Date(timeIntervalSince1970: Double(wire.time) / 1_000)
    )
  }
}

/// Represents a value for l2 level.
public struct L2Level: Sendable, Codable, Identifiable {
  /// The id value.
  public var id: String { "\(price)-\(size)-\(side)" }
  
  /// The price associated with this value.
  public let price: Double
  /// The size associated with this value.
  public let size: Double
  /// The side associated with this value.
  public let side: OrderSide
  
  /// Creates an instance with the supplied values.
  public init(price: Double, size: Double, side: OrderSide) {
    self.price = price
    self.size = size
    self.side = side
  }
}
