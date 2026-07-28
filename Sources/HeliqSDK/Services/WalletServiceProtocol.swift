//
//  WalletServiceProtocol.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines the wallet operations required by signed Exchange API actions.
public protocol WalletServiceProtocol: Sendable {
  /// Wallet address used to identify the signing account.
  var address: String { get }

  /// Signs a message and returns its signature representation.
  func sign(message: String) async throws -> SignatureTypes
}
