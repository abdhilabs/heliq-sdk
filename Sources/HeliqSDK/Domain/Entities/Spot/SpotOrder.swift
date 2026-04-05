//
//  SpotOrder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct SpotOrder: Sendable, Codable {
  public let asset: Int
  public let side: OrderSide
  public let size: Double
  public let price: Double?
  public let orderType: SpotOrderType
  public let cloid: String?
  
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

public enum SpotOrderType: String, Sendable, Codable {
  case market = "market"
  case limit = "limit"
}
