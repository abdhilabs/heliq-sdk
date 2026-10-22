//
//  SpotOrder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for spot order.
public struct SpotOrder: Sendable, Codable {
  /// The asset associated with this value.
  public let asset: Int
  /// The side associated with this value.
  public let side: OrderSide
  /// The size associated with this value.
  public let size: Double
  /// The price associated with this value.
  public let price: Double?
  /// The order type associated with this value.
  public let orderType: SpotOrderType
  /// The cloid associated with this value.
  public let cloid: String?
  
  /// Creates an instance with the supplied values.
  public init(
    asset: Int,
    side: OrderSide,
    size: Double,
    price: Double? = nil,
    orderType: SpotOrderType = .market,
    cloid: String? = nil
  ) {
    self.asset = asset
    self.side = side
    self.size = size
    self.price = price
    self.orderType = orderType
    self.cloid = cloid
  }
}

/// Represents a set of supported values for spot order type.
public enum SpotOrderType: String, Sendable, Codable {
  /// The `market` case.
  case market = "market"
  /// The `limit` case.
  case limit = "limit"
}
