//
//  Meta.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for meta.
public struct Meta: Sendable, Codable {
  /// The universe associated with this value.
  public let universe: [MetaAsset]
  /// The spot asset configs associated with this value.
  public let spotAssetConfigs: [String: SpotAssetConfig]
  
  /// Creates an instance with the supplied values.
  public init(universe: [MetaAsset], spotAssetConfigs: [String: SpotAssetConfig]) {
    self.universe = universe
    self.spotAssetConfigs = spotAssetConfigs
  }
}

/// Represents a value for meta asset.
public struct MetaAsset: Sendable, Codable, Identifiable {
  /// The id value.
  public var id: Int { asset }
  
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
  /// The only isolated margin associated with this value.
  public let onlyIsolatedMargin: Bool
  
  /// Creates an instance with the supplied values.
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

/// Represents a value for spot asset config.
public struct SpotAssetConfig: Sendable, Codable {
  /// The token cfg associated with this value.
  public let tokenCfg: TokenConfig?
  
  /// Creates an instance with the supplied values.
  public init(tokenCfg: TokenConfig? = nil) {
    self.tokenCfg = tokenCfg
  }
}

/// Represents a value for token config.
public struct TokenConfig: Sendable, Codable {
  /// The name associated with this value.
  public let name: String
  /// The symbol associated with this value.
  public let symbol: String
  /// The decimals associated with this value.
  public let decimals: Int
  
  /// Creates an instance with the supplied values.
  public init(name: String, symbol: String, decimals: Int) {
    self.name = name
    self.symbol = symbol
    self.decimals = decimals
  }
}
