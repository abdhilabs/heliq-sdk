//
//  WalletService.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class WalletService: WalletServiceProtocol, @unchecked Sendable {
  private let keyManager: KeyManager
  public let address: String
  
  public init(keyManager: KeyManager) async throws {
    self.keyManager = keyManager
    self.address = try await keyManager.getAddress()
  }
  
  public func sign(message: String) async throws -> SignatureTypes {
    try await keyManager.sign(message: message)
  }
}

public final class KeyManager: @unchecked Sendable {
  private enum StorageType {
    case memory(Data)
    case keychain(String)
    case agent(String)
  }
  
  private let storageType: StorageType
  private let signer: Signer?
  
  public init(privateKey: String) throws {
    self.storageType = .memory(Data())
    self.signer = try Signer(privateKey: privateKey)
  }
  
  public init(keychainKey: String) throws {
    self.storageType = .keychain(keychainKey)
    self.signer = nil
  }
  
  public init(agentAddress: String) throws {
    self.storageType = .agent(agentAddress)
    self.signer = nil
  }
  
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
  
  public func sign(message: String) async throws -> SignatureTypes {
    guard let signer = signer else {
      throw SigningError.keyNotFound
    }
    return try await signer.sign(message: message)
  }
}
