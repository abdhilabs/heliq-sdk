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
    let signature = try await signer.signUserSigned(
      primaryType: "HyperliquidTransaction:UsdSend",
      fields: transferFields,
      action: transferAction,
      isMainnet: false
    )

    #expect(signature.r == "0x637b37dd731507cdd24f46532ca8ba6eec616952c56218baeff04144e4a77073")
    #expect(signature.s == "0x11a6a24900e6e314136d2592e2f8d502cd89b7c15b198e1bee043c9589f9fad7")
    #expect(signature.v == 27)
  }

  @Test func signsOfficialWithdrawFixture() async throws {
    let signer = try Signer(privateKey: "0x0123456789012345678901234567890123456789012345678901234567890123")
    let signature = try await signer.signUserSigned(
      primaryType: "HyperliquidTransaction:Withdraw",
      fields: transferFields,
      action: transferAction,
      isMainnet: false
    )

    #expect(signature.r == "0x8363524c799e90ce9bc41022f7c39b4e9bdba786e5f9c72b20e43e1462c37cf9")
    #expect(signature.s == "0x58b1411a775938b83e29182e8ef74975f9054c8e97ebf5ec2dc8d51bfc893881")
    #expect(signature.v == 28)
  }

  @Test func signsOfficialL1OrderFixture() async throws {
    let signer = try Signer(privateKey: "0x0123456789012345678901234567890123456789012345678901234567890123")
    let action = CanonicalMessagePack.Object([
      ("type", .string("order")),
      ("orders", .array([
        .object(.init([
          ("a", .number(1)),
          ("b", .bool(true)),
          ("p", .string("100")),
          ("s", .string("100")),
          ("r", .bool(false)),
          ("t", .object(.init([
            ("limit", .object(.init([("tif", .string("Gtc"))])))
          ])))
        ]))
      ])),
      ("grouping", .string("na"))
    ])

    let signature = try await signer.signL1(action: action, nonce: 0, isMainnet: true)

    #expect(signature.r == "0xd65369825a9df5d80099e513cce430311d7d26ddf477f5b3a33d2806b100d78e")
    #expect(signature.s == "0x2b54116ff64054968aa237c20ca9ff68000f977c93289157748a3162b6ea940e")
    #expect(signature.v == 28)
  }

  // Reference: eth-account encode_typed_data with Hyperliquid's sign_agent schema.
  @Test func signsAgentApprovalReferenceFixture() async throws {
    let signer = try Signer(privateKey: "0x0123456789012345678901234567890123456789012345678901234567890123")
    let signature = try await signer.signUserSigned(
      primaryType: "HyperliquidTransaction:ApproveAgent",
      fields: [
        .init(name: "hyperliquidChain", type: "string"),
        .init(name: "agentAddress", type: "address"),
        .init(name: "agentName", type: "string"),
        .init(name: "nonce", type: "uint64")
      ],
      action: [
        "agentAddress": .string("0x5e9ee1089755c3435139848e47e6635505d5a13a"),
        "agentName": .string("heliq"),
        "nonce": .number(1_687_816_341_423)
      ],
      isMainnet: false
    )

    #expect(signature.r == "0x3e422bea121040458499157fd86864f05dff1040ae8cdea353baf6a009e5657c")
    #expect(signature.s == "0x5d444545fc63e2f086fb463578db80f4df9938b60b689521a27e783236566d8a")
    #expect(signature.v == 27)
  }

  private var transferFields: [HyperliquidEIP712Field] {
    [
      HyperliquidEIP712Field(name: "hyperliquidChain", type: "string"),
      HyperliquidEIP712Field(name: "destination", type: "string"),
      HyperliquidEIP712Field(name: "amount", type: "string"),
      HyperliquidEIP712Field(name: "time", type: "uint64")
    ]
  }

  private var transferAction: [String: JSONValue] {
    [
      "destination": .string("0x5e9ee1089755c3435139848e47e6635505d5a13a"),
      "amount": .string("1"),
      "time": .number(1_687_816_341_423)
    ]
  }
}
