//
//  AllMids.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct AllMids: Sendable, Codable {
  public let prices: [String: Double]
  
  public init(prices: [String: Double]) {
    self.prices = prices
  }
  
  public func price(for coin: String) -> Double? {
    prices[coin]
  }
}
