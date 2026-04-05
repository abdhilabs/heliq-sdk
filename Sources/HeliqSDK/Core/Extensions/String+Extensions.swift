//
//  String+Extensions.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public extension String {
  var isValidHex: Bool {
    let hex = hasPrefix("0x") ? String(dropFirst(2)) : self
    return hex.allSatisfy { $0.isHexDigit }
  }
  
  var isValidEthereumAddress: Bool {
    let hex = hasPrefix("0x") ? String(dropFirst(2)) : self
    return hex.count == 40 && isValidHex
  }
  
  var isValidPrivateKey: Bool {
    let hex = hasPrefix("0x") ? String(dropFirst(2)) : self
    return hex.count == 64 && isValidHex
  }
  
  var without0xPrefix: String {
    hasPrefix("0x") ? String(dropFirst(2)) : self
  }
  
  var with0xPrefix: String {
    hasPrefix("0x") ? self : "0x" + self
  }
  
  func leftPadding(toLength length: Int, withPad character: Character) -> String {
    let padCount = length - count
    guard padCount > 0 else { return self }
    return String(repeating: character, count: padCount) + self
  }
  
  func rightPadding(toLength length: Int, withPad character: Character) -> String {
    let padCount = length - count
    guard padCount > 0 else { return self }
    return self + String(repeating: character, count: padCount)
  }
}
