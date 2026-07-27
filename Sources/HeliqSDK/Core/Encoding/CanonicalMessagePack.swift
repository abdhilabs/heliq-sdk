//
//  CanonicalMessagePack.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Order-preserving MessagePack encoder for Hyperliquid L1 action hashes.
/// Every map uses `Object`, not a Swift dictionary, because its byte order is signed.
public enum CanonicalMessagePack {
  /// A value supported by the canonical MessagePack encoder.
  public indirect enum Value: Sendable {
    /// A UTF-8 string value.
    case string(String)
    /// A Boolean value.
    case bool(Bool)
    /// A null value.
    case null
    /// A non-negative integral numeric value.
    case number(Double)
    /// An ordered collection of values.
    case array([Value])
    /// An order-preserving object value.
    case object(Object)
  }

  /// An ordered collection of named MessagePack values.
  public struct Object: Sendable {
    /// Object fields in their encoded order.
    public let fields: [(String, Value)]

    /// Creates an object with fields in encoding order.
    public init(_ fields: [(String, Value)]) {
      self.fields = fields
    }
  }

  /// Encodes an ordered object as canonical MessagePack data.
  public static func encode(_ object: Object) throws -> Data {
    var output = Data()
    try encodeMap(object.fields, into: &output)
    return output
  }

  private static func encodeMap(_ fields: [(String, Value)], into output: inout Data) throws {
    guard fields.count <= 15 else {
      throw ValidationError.malformedData(reason: "MessagePack maps over 15 fields are not supported")
    }
    output.append(UInt8(0x80 | fields.count))
    for (key, value) in fields {
      try encodeString(key, into: &output)
      try encode(value, into: &output)
    }
  }

  private static func encode(_ value: Value, into output: inout Data) throws {
    switch value {
    case .string(let value):
      try encodeString(value, into: &output)
    case .bool(let value):
      output.append(value ? 0xc3 : 0xc2)
    case .null:
      output.append(0xc0)
    case .number(let value):
      try encodeInteger(value, into: &output)
    case .array(let values):
      guard values.count <= 15 else {
        throw ValidationError.malformedData(reason: "MessagePack arrays over 15 values are not supported")
      }
      output.append(UInt8(0x90 | values.count))
      for value in values {
        try encode(value, into: &output)
      }
    case .object(let object):
      try encodeMap(object.fields, into: &output)
    }
  }

  private static func encodeString(_ value: String, into output: inout Data) throws {
    let bytes = Array(value.utf8)
    guard bytes.count <= 31 else {
      throw ValidationError.malformedData(reason: "MessagePack strings over 31 bytes are not supported")
    }
    output.append(UInt8(0xa0 | bytes.count))
    output.append(contentsOf: bytes)
  }

  private static func encodeInteger(_ value: Double, into output: inout Data) throws {
    guard value.rounded() == value, value >= 0, value <= Double(UInt64.max) else {
      throw ValidationError.malformedData(reason: "MessagePack signing values must be non-negative integral numbers")
    }
    let integer = UInt64(value)
    if integer <= 0x7f { output.append(UInt8(integer)) }
    else if integer <= UInt64(UInt8.max) { output.append(0xcc); output.append(UInt8(integer)) }
    else if integer <= UInt64(UInt16.max) { output.append(0xcd); append(UInt16(integer), into: &output) }
    else if integer <= UInt64(UInt32.max) { output.append(0xce); append(UInt32(integer), into: &output) }
    else { output.append(0xcf); append(integer, into: &output) }
  }

  private static func append<T: FixedWidthInteger>(_ value: T, into output: inout Data) {
    var bigEndian = value.bigEndian
    withUnsafeBytes(of: &bigEndian) { output.append(contentsOf: $0) }
  }
}
