//
//  SpotAssetContext.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for spot asset context.
public struct SpotAssetContext: Sendable, Codable {
  /// The asset associated with this value.
  public let asset: Int
  /// The name associated with this value.
  public let name: String
  /// The max withdraw associated with this value.
  public let maxWithdraw: Double
  /// The hold associated with this value.
  public let hold: Double
  /// The spot asset hash associated with this value.
  public let spotAssetHash: String?
  
  /// Creates an instance with the supplied values.
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
