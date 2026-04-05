//
//  L2Book.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct L2Book: Sendable, Codable {
  public let coin: String
  public let levels: [L2Level]
  public let timestamp: Date
  
  public init(coin: String, levels: [L2Level], timestamp: Date) {
    self.coin = coin
    self.levels = levels
    self.timestamp = timestamp
  }
}

public struct L2Level: Sendable, Codable, Identifiable {
  public var id: String { "\(price)-\(size)-\(side)" }
  
  public let price: Double
  public let size: Double
  public let side: OrderSide
  
  public init(price: Double, size: Double, side: OrderSide) {
    self.price = price
    self.size = size
    self.side = side
  }
}
