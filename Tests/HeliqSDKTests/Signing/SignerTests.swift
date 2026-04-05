//
//  SignerTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct SignerTests {
  
  @Test
  func testSignerInitialization_withValidKey_succeeds() throws {
    let privateKey = "0x" + String(repeating: "ab", count: 32)
    let signer = try Signer(privateKey: privateKey)
    
    #expect(!signer.address.isEmpty)
  }
  
  @Test
  func testSignerInitialization_withInvalidKey_throws() {
    #expect(throws: SigningError.self) {
      try Signer(privateKey: "invalid")
    }
  }
  
  @Test
  func testSignerAddress_isDerivedFromKey() throws {
    let privateKey = "0x" + String(repeating: "ab", count: 32)
    let signer = try Signer(privateKey: privateKey)
    
    #expect(signer.address.count == 64)
  }
}
