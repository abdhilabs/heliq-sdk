//
//  Signer.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class Signer: @unchecked Sendable {
  private let privateKeyData: Data
  
  public init(privateKey: String) throws {
    let cleanedKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
    guard let keyData = Data(hexString: cleanedKey), keyData.count == 32 else {
      throw SigningError.invalidPrivateKey
    }
    self.privateKeyData = keyData
  }
  
  public func sign(message: String) async throws -> SignatureTypes {
    throw SigningError.signingFailed(reason: "Stub implementation")
  }
  
  public var address: String {
    privateKeyData.hexString
  }
}
