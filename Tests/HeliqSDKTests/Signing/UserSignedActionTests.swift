//
//  UserSignedActionTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct UserSignedActionTests {
  @Test func signsOfficialUsdTransferFixture() async throws {
    let signer = try Signer(privateKey: "0x0123456789012345678901234567890123456789012345678901234567890123")
    let fields = [
      HyperliquidEIP712Field(name: "hyperliquidChain", type: "string"),
      HyperliquidEIP712Field(name: "destination", type: "string"),
      HyperliquidEIP712Field(name: "amount", type: "string"),
      HyperliquidEIP712Field(name: "time", type: "uint64")
    ]
    let signature = try await signer.signUserSigned(
      primaryType: "HyperliquidTransaction:UsdSend",
      fields: fields,
      action: [
        "destination": .string("0x5e9ee1089755c3435139848e47e6635505d5a13a"),
        "amount": .string("1"),
        "time": .number(1_687_816_341_423)
      ],
      isMainnet: false
    )

    #expect(signature.r == "0x637b37dd731507cdd24f46532ca8ba6eec616952c56218baeff04144e4a77073")
    #expect(signature.s == "0x11a6a24900e6e314136d2592e2f8d502cd89b7c15b198e1bee043c9589f9fad7")
    #expect(signature.v == 27)
  }
}
