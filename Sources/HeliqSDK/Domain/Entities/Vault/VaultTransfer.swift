//
//  VaultTransfer.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct VaultTransfer: Sendable, Codable {
  public let fromVault: Bool
  public let toVault: Bool
  public let usdcAmount: Double
  public let vaultAddress: String?
  
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
