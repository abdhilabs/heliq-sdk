//
//  JSONCoder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

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
  
  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    try encoder.encode(value)
  }
  
  public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    try decoder.decode(type, from: data)
  }
  
  public static func decode<T: Decodable>(from data: Data) throws -> T {
    try decoder.decode(T.self, from: data)
  }
  
  public static func encodeToString<T: Encodable>(_ value: T) throws -> String {
    let data = try encode(value)
    guard let string = String(data: data, encoding: .utf8) else {
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Failed to convert data to string"))
    }
    return string
  }
  
  public static func decodeFromString<T: Decodable>(_ type: T.Type, from string: String) throws -> T {
    guard let data = string.data(using: .utf8) else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Failed to convert string to data"))
    }
    return try decode(type, from: data)
  }
}
