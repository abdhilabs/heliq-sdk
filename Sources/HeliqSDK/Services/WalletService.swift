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
}
