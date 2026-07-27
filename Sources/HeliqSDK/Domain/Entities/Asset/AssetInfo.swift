//
//  AssetInfo.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for asset info.
public struct AssetInfo: Sendable, Codable {
  /// The name associated with this value.
  public let name: String
  /// The asset associated with this value.
  public let asset: Int
  /// The is spot associated with this value.
  public let isSpot: Bool
  
  /// Creates an instance with the supplied values.
  public init(name: String, asset: Int, isSpot: Bool) {
    self.name = name
    self.asset = asset
    self.isSpot = isSpot
  }
}
