//
//  VaultEntityTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct VaultEntityTests {
  @Test func testVaultTransfer_withOptionalAddress_encodeAndDecode_succeeds() throws {
    let transfer = VaultTransfer(
      fromVault: false,
      toVault: true,
      usdcAmount: 1000.0,
      vaultAddress: "0x1234567890123456789012345678901234567890"
    )
    
    let data = try JSONCoder.encode(transfer)
    let decoded = try JSONCoder.decode(VaultTransfer.self, from: data)
    
    #expect(decoded.fromVault == false)
    #expect(decoded.toVault == true)
    #expect(decoded.usdcAmount == 1000.0)
    #expect(decoded.vaultAddress == "0x1234567890123456789012345678901234567890")
  }
  
  @Test func testVaultTransfer_withoutAddress_encodeAndDecode_succeeds() throws {
    let transfer = VaultTransfer(
      fromVault: true,
      toVault: false,
      usdcAmount: 500.0,
      vaultAddress: nil
    )
    
    let data = try JSONCoder.encode(transfer)
    let decoded = try JSONCoder.decode(VaultTransfer.self, from: data)
    
    #expect(decoded.fromVault == true)
    #expect(decoded.toVault == false)
    #expect(decoded.usdcAmount == 500.0)
    #expect(decoded.vaultAddress == nil)
  }
  
  @Test func testMultiSigEnvelope_encodeAndDecode_succeeds() throws {
    let envelope = MultiSigEnvelope(
      threshold: 2,
      signers: [
        "0x1234567890123456789012345678901234567890",
        "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"
      ],
      destination: "0x5555555555555555555555555555555555555555",
      value: "1000000",
      data: "0xabcdef"
    )
    
    let data = try JSONCoder.encode(envelope)
    let decoded = try JSONCoder.decode(MultiSigEnvelope.self, from: data)
    
    #expect(decoded.threshold == 2)
    #expect(decoded.signers.count == 2)
    #expect(decoded.destination == "0x5555555555555555555555555555555555555555")
    #expect(decoded.value == "1000000")
    #expect(decoded.data == "0xabcdef")
  }
  
  @Test func testMultiSigEnvelope_withoutData_encodeAndDecode_succeeds() throws {
    let envelope = MultiSigEnvelope(
      threshold: 1,
      signers: ["0x1234567890123456789012345678901234567890"],
      destination: "0x5555555555555555555555555555555555555555",
      value: "500000",
      data: nil
    )
    
    let data = try JSONCoder.encode(envelope)
    let decoded = try JSONCoder.decode(MultiSigEnvelope.self, from: data)
    
    #expect(decoded.threshold == 1)
    #expect(decoded.signers.count == 1)
    #expect(decoded.data == nil)
  }
}
