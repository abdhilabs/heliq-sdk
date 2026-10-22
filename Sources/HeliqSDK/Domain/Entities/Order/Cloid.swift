//
//  Cloid.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for cloid.
public struct Cloid: Sendable, Codable, Hashable {
  /// The value associated with this value.
  public let value: String
  
  /// Creates an instance with the supplied values.
  public init(value: String) {
    self.value = value
  }
  
  /// Creates an instance with the supplied values.
  public init?(hexString: String) {
    let cleaned = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
    guard cleaned.count == 16 else { return nil }
    self.value = cleaned
  }
  
  /// The hex string value.
  public var hexString: String {
    "0x" + value
  }
}
