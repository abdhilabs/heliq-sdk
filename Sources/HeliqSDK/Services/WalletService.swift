//
//  WalletService.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Provides wallet service functionality.
public final class WalletService: WalletServiceProtocol, @unchecked Sendable {
  private let keyManager: KeyManager
  /// The address.
  public let address: String
  
  /// Creates a wallet service.
  public init(keyManager: KeyManager) async throws {
    self.keyManager = keyManager
    self.address = try await keyManager.getAddress()
  }
  
  /// Performs the sign operation.
  public func sign(message: String) async throws -> SignatureTypes {
    try await keyManager.sign(message: message)
  }
  /// Signs a canonical L1 payload with the selected network, vault, and expiration context.
  public func signL1Payload(_ payload: CanonicalMessagePack.Value, nonce: Int64,
    vaultAddress: String?, expiresAfter: Int64?, isMainnet: Bool) async throws -> SignatureTypes {
    try await keyManager.signL1Payload(payload, nonce: nonce, vaultAddress: vaultAddress,
      expiresAfter: expiresAfter, isMainnet: isMainnet)
  }
  /// Delegates canonical L1 action signing to the key manager for the selected network and nonce.
  public func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws -> SignatureTypes {
    try await keyManager.signL1(action: action, nonce: nonce, isMainnet: isMainnet)
  }
  /// Signs a user action using the caller's EIP-712 primary type and ordered field schema.
  public func signUserSigned(primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue], isMainnet: Bool) async throws -> SignatureTypes {
    try await keyManager.signUserSigned(primaryType: primaryType, fields: fields, action: action, isMainnet: isMainnet)
  }

}

/// Provides key manager functionality.
public actor KeyManager {
  private enum StorageType {
    case memory(Signer)
    case keychain(String, KeychainWalletStore)
    case agent(String)
  }

  private let storageType: StorageType
  private var boundAddress: String?

  /// Creates a key manager.
  public init(privateKey: String) throws {
    self.storageType = .memory(try Signer(privateKey: privateKey))
  }

  /// References a stored wallet without loading it. Address derivation and every signing
  /// operation read the Keychain afresh and may require authentication.
  public init(keychainKey: String, store: KeychainWalletStore = KeychainWalletStore()) throws {
    self.storageType = .keychain(keychainKey, store)
  }
  
  /// Creates a key manager.
  public init(agentAddress: String) throws {
    self.storageType = .agent(agentAddress)
  }
  
  /// Performs the get address operation.
  public func getAddress() async throws -> String {
    switch storageType {
    case .memory, .keychain:
      return try loadSigner().address
    case .agent(let address):
      return address
    }
  }
  
  /// Performs the sign operation.
  public func sign(message: String) async throws -> SignatureTypes {
    let signer = try loadSigner()
    return try await signer.sign(message: message)
  }
  /// Signs a canonical L1 payload with the selected network, vault, and expiration context.
  public func signL1Payload(_ payload: CanonicalMessagePack.Value, nonce: Int64,
    vaultAddress: String?, expiresAfter: Int64?, isMainnet: Bool) async throws -> SignatureTypes {
    let signer = try loadSigner()
    return try await signer.signL1Payload(payload, nonce: nonce, vaultAddress: vaultAddress,
      expiresAfter: expiresAfter, isMainnet: isMainnet)
  }
  /// Signs a canonical L1 action, throwing `keyNotFound` when no native signer is configured.
  public func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws -> SignatureTypes {
    let signer = try loadSigner()
    return try await signer.signL1(action: action, nonce: nonce, isMainnet: isMainnet)
  }
  /// Signs the supplied EIP-712 action schema, throwing `keyNotFound` without a native signer.
  public func signUserSigned(primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue], isMainnet: Bool) async throws -> SignatureTypes {
    let signer = try loadSigner()
    return try await signer.signUserSigned(primaryType: primaryType, fields: fields, action: action, isMainnet: isMainnet)
  }

  private func loadSigner() throws -> Signer {
    switch storageType {
    case .memory(let signer):
      return signer
    case .keychain(let key, let store):
      let signer = try store.loadSigner(for: key)
      // A live wallet must not silently sign for another account if its item is deleted/re-added.
      if let boundAddress, boundAddress != signer.address {
        throw SigningError.signingFailed(reason: "Stored wallet changed; create a new KeyManager")
      }
      boundAddress = signer.address
      return signer
    case .agent:
      throw SigningError.keyNotFound
    }
  }
}
