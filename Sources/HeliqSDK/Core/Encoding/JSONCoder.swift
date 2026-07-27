//
//  JSONCoder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Encodes and decodes JSON using snake-case keys.
public enum JSONCoder {
  private static var encoder: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    return encoder
  }
  
  private static var decoder: JSONDecoder {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }
  
  /// Encodes a value as JSON data.
  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    try encoder.encode(value)
  }
  
  /// Decodes JSON data into a specified type.
  public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try decoder.decode(type, from: data)
  }
  
  /// Decodes JSON data into an inferred type.
  public static func decode<T: Decodable>(from data: Data) throws -> T {
    try decoder.decode(T.self, from: data)
  }
  
  /// Encodes a value as a UTF-8 JSON string.
  public static func encodeToString<T: Encodable>(_ value: T) throws -> String {
    let data = try encode(value)
    guard let string = String(data: data, encoding: .utf8) else {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Failed to convert data to string"))
    }
    return string
  }
  
  /// Decodes a UTF-8 JSON string into a specified type.
  public static func decodeFromString<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
    guard let data = string.data(using: .utf8) else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to convert string to data"))
    }
    return try decode(type, from: data)
  }
}
