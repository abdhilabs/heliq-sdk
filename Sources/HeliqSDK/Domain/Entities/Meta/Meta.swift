//
//  Meta.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct Meta: Sendable, Codable {
  public let universe: [MetaAsset]
  public let spotAssetConfigs: [String: SpotAssetConfig]
  
  public init(universe: [MetaAsset], spotAssetConfigs: [String: SpotAssetConfig]) {
    self.universe = universe
    self.spotAssetConfigs = spotAssetConfigs
  }
}

public struct MetaAsset: Sendable, Codable, Identifiable {
  public var id: Int { asset }
  
  public let asset: Int
  public let name: String
  public let szDecimals: Int
  public let weiDecimals: Int
  public let isPerpetual: Bool
  public let onlyIsolatedMargin: Bool
  
  public init(
    asset: Int,
    name: String,
    szDecimals: Int,
    weiDecimals: Int,
    isPerpetual: Bool,
    onlyIsolatedMargin: Bool = false
  ) {
    self.asset = asset
    self.name = name
    self.szDecimals = szDecimals
    self.weiDecimals = weiDecimals
    self.isPerpetual = isPerpetual
    self.onlyIsolatedMargin = onlyIsolatedMargin
  }
}

public struct SpotAssetConfig: Sendable, Codable {
  public let tokenCfg: TokenConfig?
  
  public init(tokenCfg: TokenConfig? = nil) {
    self.tokenCfg = tokenCfg
  }
}

public struct TokenConfig: Sendable, Codable {
  public let name: String
  public let symbol: String
  public let decimals: Int
  
  public init(name: String, symbol: String, decimals: Int) {
    self.name = name
    self.symbol = symbol
    self.decimals = decimals
  }
}
