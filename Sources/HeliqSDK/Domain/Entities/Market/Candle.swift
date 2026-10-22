//
//  Candle.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for candle.
public struct Candle: Sendable, Codable, Identifiable {
  /// The id value.
  public var id: String { "\(timestamp.timeIntervalSince1970)" }
  
  /// The timestamp associated with this value.
  public let timestamp: Date
  /// The open associated with this value.
  public let open: Double
  /// The high associated with this value.
  public let high: Double
  /// The low associated with this value.
  public let low: Double
  /// The close associated with this value.
  public let close: Double
  /// The volume associated with this value.
  public let volume: Double
  
  /// Creates an instance with the supplied values.
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
