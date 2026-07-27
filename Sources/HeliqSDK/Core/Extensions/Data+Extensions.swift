//
//  Data+Extensions.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Adds SDK-oriented conversion utilities to `Data`.
public extension Data {
  /// Lowercase hexadecimal representation of the data.
  var hexString: String {
    map { String(format: "%02x", $0) }.joined()
  }
  
  /// Creates data from a hexadecimal string with an optional `0x` prefix.
  init?(hexString: String) {
    let hex = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
    let length = hex.count / 2
    var data = Data(capacity: length)
    var index = hex.startIndex
    
    for _ in 0..<length {
      let nextIndex = hex.index(index, offsetBy: 2)
      guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else {
        return nil
      }
      data.append(byte)
      index = nextIndex
    }
    
    self = data
  }
  
  /// Pretty-printed JSON representation, if the data contains valid JSON.
  var prettyPrintedJSON: String? {
    guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
          let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
          let string = String(data: data, encoding: .utf8) else {
      return nil
    }
    return string
  }
  
  /// Decodes the data as a string using the specified encoding.
  func toString(encoding: String.Encoding = .utf8) -> String? {
    String(data: self, encoding: encoding)
  }
}
