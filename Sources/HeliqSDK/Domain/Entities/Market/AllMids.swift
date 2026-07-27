//
//  AllMids.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for all mids.
public struct AllMids: Sendable, Codable {
  /// The prices associated with this value.
  public let prices: [String: Double]

  /// Creates an instance with the supplied values.
  public init(prices: [String: Double]) {
    self.prices = prices
  }

  /// Creates an instance with the supplied values.
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let wrapped = try? container.decode(Wrapped.self) {
      prices = wrapped.prices
      return
    }

    let raw = try container.decode([String: String].self)
    var parsed: [String: Double] = [:]
    for (coin, price) in raw {
      guard let value = Double(price) else {
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid mid price for \(coin)")
      }
      parsed[coin] = value
    }
    prices = parsed
  }

  /// Encodes this value into the supplied encoder.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(Wrapped(prices: prices))
  }

  /// Performs the price operation.
  public func price(for coin: String) -> Double? {
    prices[coin]
  }

  private struct Wrapped: Codable {
    let prices: [String: Double]
  }
}
