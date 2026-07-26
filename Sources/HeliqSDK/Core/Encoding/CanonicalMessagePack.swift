//
//  CanonicalMessagePack.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Order-preserving MessagePack encoder for Hyperliquid L1 action hashes.
/// Hyperliquid hashes MessagePack bytes, so signing callers must supply fields
/// in official wire order through `Object` rather than an unordered dictionary.
public enum CanonicalMessagePack {
  public struct Object: Sendable {
    public let fields: [(String, JSONValue)]
    public init(_ fields: [(String, JSONValue)]) { self.fields = fields }
  }

  public static func encode(_ object: Object) throws -> Data {
    var output = Data()
    try encodeMap(object.fields, into: &output)
    return output
  }

  private static func encodeMap(_ fields: [(String, JSONValue)], into output: inout Data) throws {
    guard fields.count <= 15 else { throw ValidationError.malformedData(reason: "MessagePack maps over 15 fields are not supported") }
    output.append(UInt8(0x80 | fields.count))
    for (key, value) in fields {
      try encodeString(key, into: &output)
      try encode(value, into: &output)
    }
  }

  private static func encode(_ value: JSONValue, into output: inout Data) throws {
    switch value {
    case .string(let value): try encodeString(value, into: &output)
    case .bool(let value): output.append(value ? 0xc3 : 0xc2)
    case .null: output.append(0xc0)
    case .number(let value): try encodeInteger(value, into: &output)
    case .array(let values):
      guard values.count <= 15 else { throw ValidationError.malformedData(reason: "MessagePack arrays over 15 values are not supported") }
      output.append(UInt8(0x90 | values.count))
      for value in values { try encode(value, into: &output) }
    case .object(let values):
      try encodeMap(values.map { ($0.key, $0.value) }, into: &output)
    }
  }

  private static func encodeString(_ value: String, into output: inout Data) throws {
    let bytes = Array(value.utf8)
    guard bytes.count <= 31 else { throw ValidationError.malformedData(reason: "MessagePack strings over 31 bytes are not supported") }
    output.append(UInt8(0xa0 | bytes.count))
    output.append(contentsOf: bytes)
  }

  private static func encodeInteger(_ value: Double, into output: inout Data) throws {
    guard value.rounded() == value, value >= 0, value <= Double(UInt32.max) else {
      throw ValidationError.malformedData(reason: "MessagePack signing values must be non-negative integral numbers")
    }
    let integer = UInt32(value)
    if integer <= 0x7f { output.append(UInt8(integer)) }
    else if integer <= UInt32(UInt8.max) { output.append(0xcc); output.append(UInt8(integer)) }
    else if integer <= UInt32(UInt16.max) { output.append(0xcd); append(UInt16(integer), into: &output) }
    else { output.append(0xce); append(integer, into: &output) }
  }

  private static func append<T: FixedWidthInteger>(_ value: T, into output: inout Data) {
    var bigEndian = value.bigEndian
    withUnsafeBytes(of: &bigEndian) { output.append(contentsOf: $0) }
  }
}
