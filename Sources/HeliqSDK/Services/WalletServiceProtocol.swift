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
  /// Signs the canonical L1 action without exposing private key material.
  func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws -> SignatureTypes
  /// Signs an official user action using its EIP-712 schema.
  func signUserSigned(primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue], isMainnet: Bool) async throws -> SignatureTypes
}

public extension WalletServiceProtocol {
  func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws -> SignatureTypes {
    throw SigningError.signingFailed(reason: "Wallet must implement Hyperliquid L1 signing")
  }
  func signUserSigned(primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue], isMainnet: Bool) async throws -> SignatureTypes {
    throw SigningError.signingFailed(reason: "Wallet must implement Hyperliquid EIP-712 signing")
  }
}
