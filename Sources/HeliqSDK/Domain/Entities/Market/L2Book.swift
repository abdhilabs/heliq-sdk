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
