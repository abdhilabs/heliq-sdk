//
//  Fill.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for fill.
public struct Fill: Sendable, Codable, Identifiable {
  /// The id associated with this value.
  public let id: String
  /// The order id associated with this value.
  public let orderId: String
  /// The side associated with this value.
  public let side: OrderSide
  /// The price associated with this value.
  public let price: Double
  /// The size associated with this value.
  public let size: Double
  /// The fee associated with this value.
  public let fee: Double
  /// The timestamp associated with this value.
  public let timestamp: Date
  /// The symbol associated with this value.
  public let symbol: String
  
  /// Creates an instance with the supplied values.
  public init(
    id: String,
    orderId: String,
    side: OrderSide,
    price: Double,
    size: Double,
    fee: Double,
    timestamp: Date,
    symbol: String
  ) {
    self.id = id
    self.orderId = orderId
    self.side = side
    self.price = price
    self.size = size
    self.fee = fee
    self.timestamp = timestamp
    self.symbol = symbol
  }
}
