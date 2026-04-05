//
//  Data+Extensions.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public extension Data {
  var hexString: String {
    map { String(format: "%02x", $0) }.joined()
  }
  
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
  
  var prettyPrintedJSON: String? {
    guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
          let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
          let string = String(data: data, encoding: .utf8) else {
      return nil
    }
    return string
  }
  
  func toString(encoding: String.Encoding = .utf8) -> String? {
    String(data: self, encoding: encoding)
  }
}
