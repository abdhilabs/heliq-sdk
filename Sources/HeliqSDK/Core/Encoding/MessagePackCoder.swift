//
//  MessagePackCoder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Encodes and decodes the SDK's MessagePack-compatible payload data.
public enum MessagePackCoder {
  /// Encodes a value as payload data.
  public static func encode<T: Encodable>(_ value: T) throws -> Data {
    let encoder = JSONEncoder()
    return try encoder.encode(value)
  }
  
  /// Decodes payload data into a specified type.
  public static func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(type, from: data)
  }
  
  /// Decodes payload data into an inferred type.
  public static func decode<T: Decodable>(from data: Data) throws -> T {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
  }
}
