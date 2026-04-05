//
//  Candle.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct Candle: Sendable, Codable, Identifiable {
  public var id: String { "\(timestamp.timeIntervalSince1970)" }
  
  public let timestamp: Date
  public let open: Double
  public let high: Double
  public let low: Double
  public let close: Double
  public let volume: Double
  
  public init(
    timestamp: Date,
    open: Double,
    high: Double,
    low: Double,
    close: Double,
    volume: Double
  ) {
    self.timestamp = timestamp
    self.open = open
    self.high = high
    self.low = low
    self.close = close
    self.volume = volume
  }
}
