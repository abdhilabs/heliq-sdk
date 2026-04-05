//
//  AssetInfo.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct AssetInfo: Sendable, Codable {
  public let name: String
  public let asset: Int
  public let isSpot: Bool
  
  public init(name: String, asset: Int, isSpot: Bool) {
    self.name = name
    self.asset = asset
    self.isSpot = isSpot
  }
}
