//
//  CoinAssetMapping.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct CoinAssetMapping: Sendable, Codable {
  public let coin: String
  public let assetId: Int
  
  public init(coin: String, assetId: Int) {
    self.coin = coin
    self.assetId = assetId
  }
}
