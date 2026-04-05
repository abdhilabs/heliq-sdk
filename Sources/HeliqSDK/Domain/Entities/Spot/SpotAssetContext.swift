//
//  SpotAssetContext.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct SpotAssetContext: Sendable, Codable {
  public let asset: Int
  public let name: String
  public let maxWithdraw: Double
  public let hold: Double
  public let spotAssetHash: String?
  
  public init(
    asset: Int,
    name: String,
    maxWithdraw: Double,
    hold: Double,
    spotAssetHash: String? = nil
  ) {
    self.asset = asset
    self.name = name
    self.maxWithdraw = maxWithdraw
    self.hold = hold
    self.spotAssetHash = spotAssetHash
  }
}
