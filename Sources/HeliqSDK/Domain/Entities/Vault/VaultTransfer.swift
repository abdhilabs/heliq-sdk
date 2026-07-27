//
//  VaultTransfer.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for vault transfer.
public struct VaultTransfer: Sendable, Codable {
  /// The from vault associated with this value.
  public let fromVault: Bool
  /// The to vault associated with this value.
  public let toVault: Bool
  /// The usdc amount associated with this value.
  public let usdcAmount: Double
  /// The vault address associated with this value.
  public let vaultAddress: String?
  
  /// Creates an instance with the supplied values.
  public init(
    fromVault: Bool,
    toVault: Bool,
    usdcAmount: Double,
    vaultAddress: String? = nil
  ) {
    self.fromVault = fromVault
    self.toVault = toVault
    self.usdcAmount = usdcAmount
    self.vaultAddress = vaultAddress
  }
}
