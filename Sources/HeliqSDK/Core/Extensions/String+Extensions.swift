//
//  String+Extensions.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Adds validation and formatting utilities for Ethereum-related strings.
public extension String {
  /// Whether the string contains only hexadecimal digits after an optional `0x` prefix.
  var isValidHex: Bool {
    let hex = hasPrefix("0x") ? String(dropFirst(2)) : self
    return hex.allSatisfy { $0.isHexDigit }
  }
  
  /// Whether the string is a 20-byte hexadecimal Ethereum address.
  var isValidEthereumAddress: Bool {
    let hex = hasPrefix("0x") ? String(dropFirst(2)) : self
    return hex.count == 40 && isValidHex
  }
  
  /// Whether the string is a 32-byte hexadecimal private key.
  var isValidPrivateKey: Bool {
    let hex = hasPrefix("0x") ? String(dropFirst(2)) : self
    return hex.count == 64 && isValidHex
  }
  
  /// String with a leading `0x` prefix removed.
  var without0xPrefix: String {
    hasPrefix("0x") ? String(dropFirst(2)) : self
  }
  
  /// String with a leading `0x` prefix added when absent.
  var with0xPrefix: String {
    hasPrefix("0x") ? self : "0x" + self
  }
  
  /// Left-pads the string to a minimum length.
  func leftPadding(toLength length: Int, withPad character: Character) -> String {
    let padCount = length - count
    guard padCount > 0 else { return self }
    return String(repeating: character, count: padCount) + self
  }
  
  /// Right-pads the string to a minimum length.
  func rightPadding(toLength length: Int, withPad character: Character) -> String {
    let padCount = length - count
    guard padCount > 0 else { return self }
    return self + String(repeating: character, count: padCount)
  }
}
