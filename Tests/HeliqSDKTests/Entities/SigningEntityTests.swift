//
//  SigningEntityTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct SigningEntityTests {
  @Test func testSignatureType_eoa_isCaseZero() throws {
    let sigType: SignatureType = .eoa
    #expect(sigType == .eoa)
  }
  
  @Test func testSignatureType_contract_isCaseOne() throws {
    let sigType: SignatureType = .contract
    #expect(sigType == .contract)
  }
  
  @Test func testSignatureTypes_encodeAndDecode_preservesAllFields() throws {
    let sigTypes = SignatureTypes(
      r: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
      s: "0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
      v: 27,
      signatureType: .eoa
    )
    
    let data = try JSONCoder.encode(sigTypes)
    let decoded = try JSONCoder.decode(SignatureTypes.self, from: data)
    
    #expect(decoded.r == sigTypes.r)
    #expect(decoded.s == sigTypes.s)
    #expect(decoded.v == 27)
    #expect(decoded.signatureType == .eoa)
  }
  
  @Test func testSignedMessage_encodeAndDecode_succeeds() throws {
    let signedMsg = SignedMessage(
      message: "Test message to sign",
      signature: SignatureTypes(
        r: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
        s: "0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321",
        v: 28,
        signatureType: .contract
      ),
      signer: "0x1234567890123456789012345678901234567890"
    )
    
    let data = try JSONCoder.encode(signedMsg)
    let decoded = try JSONCoder.decode(SignedMessage.self, from: data)
    
    #expect(decoded.message == "Test message to sign")
    #expect(decoded.signature.v == 28)
    #expect(decoded.signature.signatureType == .contract)
    #expect(decoded.signer == "0x1234567890123456789012345678901234567890")
  }
  
  @Test func testSignatureTypes_withContractType_encodeAndDecode_succeeds() throws {
    let sigTypes = SignatureTypes(
      r: "0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      s: "0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
      v: 28,
      signatureType: .contract
    )
    
    let data = try JSONCoder.encode(sigTypes)
    let decoded = try JSONCoder.decode(SignatureTypes.self, from: data)
    
    #expect(decoded.v == 28)
    #expect(decoded.signatureType == .contract)
  }
}
