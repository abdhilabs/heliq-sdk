//
//  CoinAssetMapping.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for coin asset mapping.
public struct CoinAssetMapping: Sendable, Codable {
  /// The coin associated with this value.
  public let coin: String
  /// The asset id associated with this value.
  public let assetId: Int
  
  /// Creates an instance with the supplied values.
  public init(coin: String, assetId: Int) {
    self.coin = coin
    self.assetId = assetId
  }
}
