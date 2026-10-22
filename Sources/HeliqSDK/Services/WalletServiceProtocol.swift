//
//  WalletServiceProtocol.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines the wallet operations required by signed Exchange API actions.
public protocol WalletServiceProtocol: Sendable {
  /// Signs an L1 payload with vault/expiry context, including multisig array payloads.
  func signL1Payload(_ payload: CanonicalMessagePack.Value, nonce: Int64,
    vaultAddress: String?, expiresAfter: Int64?, isMainnet: Bool) async throws -> SignatureTypes
  /// Wallet address used to identify the signing account.
  var address: String { get }

  /// Signs a message and returns its signature representation.
  func sign(message: String) async throws -> SignatureTypes
  /// Signs the canonical L1 action without exposing private key material.
  func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws -> SignatureTypes
  /// Signs an official user action using its EIP-712 schema.
  func signUserSigned(primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue], isMainnet: Bool) async throws -> SignatureTypes
}

/// Explicit unsupported-signing defaults for wallet adapters that only implement message signing.
public extension WalletServiceProtocol {
  /// Throws a signing error unless the wallet adapter implements canonical L1 action signing.
  func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws -> SignatureTypes {
    throw SigningError.signingFailed(reason: "Wallet must implement Hyperliquid L1 signing")
  }
  /// Throws a signing error unless the wallet adapter implements user-action EIP-712 signing.
  func signUserSigned(primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue], isMainnet: Bool) async throws -> SignatureTypes {
    throw SigningError.signingFailed(reason: "Wallet must implement Hyperliquid EIP-712 signing")
  }
}

/// Compatibility signing for object payloads without vault or expiration context.
public extension WalletServiceProtocol {
  /// Delegates a plain object to `signL1`; rejects arrays, vault context, and expiration context.
  func signL1Payload(_ payload: CanonicalMessagePack.Value, nonce: Int64,
    vaultAddress: String?, expiresAfter: Int64?, isMainnet: Bool) async throws -> SignatureTypes {
    guard case .object(let action) = payload, vaultAddress == nil, expiresAfter == nil else {
      throw SigningError.signingFailed(reason: "Wallet must implement contextual L1 signing")
    }
    return try await signL1(action: action, nonce: nonce, isMainnet: isMainnet)
  }
}
