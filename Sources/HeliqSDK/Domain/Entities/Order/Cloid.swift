//
//  Cloid.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct Cloid: Sendable, Codable, Hashable {
  public let value: String
  
  public init(value: String) {
    self.value = value
  }
  
  public init?(hexString: String) {
    let cleaned = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
    guard cleaned.count == 16 else { return nil }
    self.value = cleaned
  }
  
  public var hexString: String {
    "0x" + value
  }
}
