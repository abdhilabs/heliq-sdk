//
//  UserState.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct UserState: Sendable, Codable {
  public let accountAddress: String
  public let assetPositions: [AssetPosition]
  public let marginUsed: Double
  public let marginTotal: Double
  public let marginMode: MarginMode
  public let leverage: Int
  
  public init(
    accountAddress: String,
    assetPositions: [AssetPosition],
    marginUsed: Double,
    marginTotal: Double,
    marginMode: MarginMode,
    leverage: Int
  ) {
    self.accountAddress = accountAddress
    self.assetPositions = assetPositions
    self.marginUsed = marginUsed
    self.marginTotal = marginTotal
    self.marginMode = marginMode
    self.leverage = leverage
  }
}

public struct AssetPosition: Sendable, Codable {
  public let asset: Int
  public let positionSize: Double
  public let entryPrice: Double
  public let unrealizedPnl: Double
  public let realizedPnl: Double
  public let marginUsed: Double
  
  public init(
    asset: Int,
    positionSize: Double,
    entryPrice: Double,
    unrealizedPnl: Double,
    realizedPnl: Double,
    marginUsed: Double
  ) {
    self.asset = asset
    self.positionSize = positionSize
    self.entryPrice = entryPrice
    self.unrealizedPnl = unrealizedPnl
    self.realizedPnl = realizedPnl
    self.marginUsed = marginUsed
  }
}

public enum MarginMode: String, Sendable, Codable {
  case cross = "cross"
  case isolated = "isolated"
}
