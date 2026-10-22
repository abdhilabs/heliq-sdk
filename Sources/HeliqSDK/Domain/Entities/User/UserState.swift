//
//  UserState.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for user state.
public struct UserState: Sendable, Codable {
  /// The account address associated with this value.
  public let accountAddress: String
  /// The asset positions associated with this value.
  public let assetPositions: [AssetPosition]
  /// The margin used associated with this value.
  public let marginUsed: Double
  /// The margin total associated with this value.
  public let marginTotal: Double
  /// Common position margin mode; nil when there are no positions or modes differ.
  public let marginMode: MarginMode?
  /// Common position leverage; nil when there are no positions or leverage values differ.
  public let leverage: Int?
  
  /// Creates an instance with the supplied values.
  public init(
    accountAddress: String,
    assetPositions: [AssetPosition],
    marginUsed: Double,
    marginTotal: Double,
    marginMode: MarginMode?,
    leverage: Int?
  ) {
    self.accountAddress = accountAddress
    self.assetPositions = assetPositions
    self.marginUsed = marginUsed
    self.marginTotal = marginTotal
    self.marginMode = marginMode
    self.leverage = leverage
  }
}

/// Represents a value for asset position.
public struct AssetPosition: Sendable, Codable {
  /// The asset associated with this value.
  public let asset: Int
  /// The position size associated with this value.
  public let positionSize: Double
  /// The entry price associated with this value.
  public let entryPrice: Double?
  /// The unrealized pnl associated with this value.
  public let unrealizedPnl: Double
  /// Realized PnL, when available. Clearinghouse responses do not supply this value.
  public let realizedPnl: Double?
  /// The margin used associated with this value.
  public let marginUsed: Double
  /// Margin mode of this position, when supplied by the exchange.
  public let marginMode: MarginMode?
  /// Configured leverage of this position, when supplied by the exchange.
  public let leverage: Int?

  /// Creates an instance with the supplied values.
  public init(
    asset: Int,
    positionSize: Double,
    entryPrice: Double?,
    unrealizedPnl: Double,
    realizedPnl: Double?,
    marginUsed: Double,
    marginMode: MarginMode? = nil,
    leverage: Int? = nil
  ) {
    self.asset = asset
    self.positionSize = positionSize
    self.entryPrice = entryPrice
    self.unrealizedPnl = unrealizedPnl
    self.realizedPnl = realizedPnl
    self.marginUsed = marginUsed
    self.marginMode = marginMode
    self.leverage = leverage
  }
}

/// Represents a set of supported values for margin mode.
public enum MarginMode: String, Sendable, Codable {
  /// The `cross` case.
  case cross = "cross"
  /// The `isolated` case.
  case isolated = "isolated"
}
