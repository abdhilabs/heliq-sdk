//
//  MockWalletService.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import HeliqSDK

final class MockWalletService: WalletServiceProtocol, @unchecked Sendable {
  let address: String
  
  private let privateKey: String
  
  init() {
    self.address = "0x1be31a94361a391bbafb2a4ccd704f57dc04d4bb"
    self.privateKey = "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
  }
  
  init(address: String, privateKey: String) {
    self.address = address
    self.privateKey = privateKey
  }
  
  func sign(message: String) async throws -> SignatureTypes {
    try await Task.sleep(nanoseconds: 100_000_000)
    
    let hash = message.data(using: .utf8)?.base64EncodedString() ?? ""
    
    let r = String(hash.prefix(64))
    let s = String(hash.dropFirst(64).prefix(64))
    let v = 27
    
    return SignatureTypes(
      r: r.padding(toLength: 64, withPad: "0", startingAt: 0),
      s: s.padding(toLength: 64, withPad: "0", startingAt: 0),
      v: v,
      signatureType: .eoa
    )
  }
}
