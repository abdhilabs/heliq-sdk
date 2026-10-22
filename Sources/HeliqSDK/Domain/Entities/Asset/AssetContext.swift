//
//  AssetContext.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for asset context.
public struct AssetContext: Sendable, Codable, Hashable {
  /// The asset associated with this value.
  public let asset: Int
  /// The name associated with this value.
  public let name: String
  /// The sz decimals associated with this value.
  public let szDecimals: Int
  /// The wei decimals associated with this value.
  public let weiDecimals: Int
  /// The is perpetual associated with this value.
  public let isPerpetual: Bool
  /// The is spot associated with this value.
  public let isSpot: Bool
  
  /// Creates an instance with the supplied values.
  public init(asset: Int, name: String, szDecimals: Int, weiDecimals: Int, isPerpetual: Bool, isSpot: Bool) {
    self.asset = asset
    self.name = name
    self.szDecimals = szDecimals
    self.weiDecimals = weiDecimals
    self.isPerpetual = isPerpetual
    self.isSpot = isSpot
  }
}
