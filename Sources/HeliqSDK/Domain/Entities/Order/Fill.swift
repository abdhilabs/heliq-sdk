//
//  Fill.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct Fill: Sendable, Codable, Identifiable {
  public let id: String
  public let orderId: String
  public let side: OrderSide
  public let price: Double
  public let size: Double
  public let fee: Double
  public let timestamp: Date
  public let symbol: String
  
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
