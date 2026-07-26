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
  
  @Test func signsOfficialL1Fixture() async throws {
    let signer = try Signer(privateKey: "0x0123456789012345678901234567890123456789012345678901234567890123")
    let action = CanonicalMessagePack.Object([("type", .string("dummy")), ("num", .number(100_000_000_000))])

    let hash = try Signer.actionHash(action: action, nonce: 0)
    #expect(hash.hexString == "f528daee6a0bd11407b483cfcd9a48c56884180b70ee86f124053e5fc1bf4d57")

    let mainnet = try await signer.signL1(action: action, nonce: 0, isMainnet: true)
    #expect(mainnet.r == "0x53749d5b30552aeb2fca34b530185976545bb22d0b3ce6f62e31be961a59298")
    #expect(mainnet.s == "0x755c40ba9bf05223521753995abb2f73ab3229be8ec921f350cb447e384d8ed8")
    #expect(mainnet.v == 27)

    let testnet = try await signer.signL1(action: action, nonce: 0, isMainnet: false)
    #expect(testnet.r == "0x542af61ef1f429707e3c76c5293c80d01f74ef853e34b76efffcb57e574f9510")
    #expect(testnet.s == "0x17b8b32f086e8cdede991f1e2c529f5dd5297cbe8128500e00cbaf766204a613")
    #expect(testnet.v == 28)
  }

  @Test func testSignerAddress_isDerivedFromKey() throws {
    let privateKey = "0x" + String(repeating: "ab", count: 32)
    let signer = try Signer(privateKey: privateKey)
    
    #expect(signer.address.count == 42)
    #expect(signer.address.hasPrefix("0x"))
  }
}
