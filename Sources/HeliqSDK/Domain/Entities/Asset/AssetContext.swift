//
//  AssetContext.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct AssetContext: Sendable, Codable, Hashable {
  public let asset: Int
  public let name: String
  public let szDecimals: Int
  public let weiDecimals: Int
  public let isPerpetual: Bool
  public let isSpot: Bool
  
  public init(asset: Int, name: String, szDecimals: Int, weiDecimals: Int, isPerpetual: Bool, isSpot: Bool) {
    self.asset = asset
    self.name = name
    self.szDecimals = szDecimals
    self.weiDecimals = weiDecimals
    self.isPerpetual = isPerpetual
    self.isSpot = isSpot
  }
}
