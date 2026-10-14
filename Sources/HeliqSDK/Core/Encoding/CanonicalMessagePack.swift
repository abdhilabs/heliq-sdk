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

  static func json(_ object: Object) -> [String: JSONValue] {
    Dictionary(uniqueKeysWithValues: object.fields.map { ($0.0, json($0.1)) })
  }

  private static func json(_ value: Value) -> JSONValue {
    switch value {
    case .string(let v): return .string(v)
    case .bool(let v): return .bool(v)
    case .null: return .null
    case .number(let v): return .number(v)
    case .array(let v): return .array(v.map(json))
    case .object(let v): return .object(json(v))
    }
  }

  private static func encodeMap(_ fields: [(String, Value)], into output: inout Data) throws {
    try encodeCount(fields.count, fix: 0x80, wide16: 0xde, wide32: 0xdf, into: &output)
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
      try encodeCount(values.count, fix: 0x90, wide16: 0xdc, wide32: 0xdd, into: &output)
      for value in values {
        try encode(value, into: &output)
      }
    case .object(let object):
      try encodeMap(object.fields, into: &output)
    }
  }

  private static func encodeCount(_ count: Int, fix: UInt8, wide16: UInt8, wide32: UInt8, into output: inout Data) throws {
    if count <= 15 { output.append(fix | UInt8(count)) }
    else if count <= 65_535 { output.append(wide16); append(UInt16(count), into: &output) }
    else if count <= Int(UInt32.max) { output.append(wide32); append(UInt32(count), into: &output) }
    else { throw ValidationError.malformedData(reason: "MessagePack collection is too large") }
  }

  private static func encodeString(_ value: String, into output: inout Data) throws {
    let bytes = Array(value.utf8)
    if bytes.count <= 31 { output.append(UInt8(0xa0 | bytes.count)) }
    else if bytes.count <= 255 { output.append(0xd9); output.append(UInt8(bytes.count)) }
    else if bytes.count <= 65_535 { output.append(0xda); append(UInt16(bytes.count), into: &output) }
    else if bytes.count <= Int(UInt32.max) { output.append(0xdb); append(UInt32(bytes.count), into: &output) }
    else { throw ValidationError.malformedData(reason: "MessagePack string is too large") }
    output.append(contentsOf: bytes)
  }

  private static func encodeInteger(_ value: Double, into output: inout Data) throws {
    guard value.rounded() == value, value >= 0, value.isFinite, value < Double(UInt64.max) else {
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
