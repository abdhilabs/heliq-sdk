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
public final class KeyManager: @unchecked Sendable {
  private enum StorageType {
    case memory(Data)
    case keychain(String)
    case agent(String)
  }
  
  private let storageType: StorageType
  private let signer: Signer?
  
  /// Creates a key manager.
  public init(privateKey: String) throws {
    self.storageType = .memory(Data())
    self.signer = try Signer(privateKey: privateKey)
  }
  
  /// Creates a key manager.
  public init(keychainKey: String) throws {
    self.storageType = .keychain(keychainKey)
    self.signer = nil
  }
  
  /// Creates a key manager.
  public init(agentAddress: String) throws {
    self.storageType = .agent(agentAddress)
    self.signer = nil
  }
  
  /// Performs the get address operation.
  public func getAddress() async throws -> String {
    switch storageType {
    case .memory:
      if let signer = signer {
        return signer.address
      }
      throw SigningError.keyNotFound
    case .keychain:
      throw SigningError.keyNotFound
    case .agent(let address):
      return address
    }
  }
  
  /// Performs the sign operation.
  public func sign(message: String) async throws -> SignatureTypes {
    guard let signer = signer else {
      throw SigningError.keyNotFound
    }
    return try await signer.sign(message: message)
  }
  /// Signs a canonical L1 payload with the selected network, vault, and expiration context.
  public func signL1Payload(_ payload: CanonicalMessagePack.Value, nonce: Int64,
    vaultAddress: String?, expiresAfter: Int64?, isMainnet: Bool) async throws -> SignatureTypes {
    guard let signer else { throw SigningError.keyNotFound }
    return try await signer.signL1Payload(payload, nonce: nonce, vaultAddress: vaultAddress,
      expiresAfter: expiresAfter, isMainnet: isMainnet)
  }
  /// Signs a canonical L1 action, throwing `keyNotFound` when no native signer is configured.
  public func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws -> SignatureTypes {
    guard let signer else { throw SigningError.keyNotFound }
    return try await signer.signL1(action: action, nonce: nonce, isMainnet: isMainnet)
  }
  /// Signs the supplied EIP-712 action schema, throwing `keyNotFound` without a native signer.
  public func signUserSigned(primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue], isMainnet: Bool) async throws -> SignatureTypes {
    guard let signer else { throw SigningError.keyNotFound }
    return try await signer.signUserSigned(primaryType: primaryType, fields: fields, action: action, isMainnet: isMainnet)
  }

}
