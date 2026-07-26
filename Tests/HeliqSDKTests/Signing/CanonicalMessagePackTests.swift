//
//  CanonicalMessagePackTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct CanonicalMessagePackTests {
  @Test func encodesOfficialL1ActionInInsertionOrder() throws {
    let action = CanonicalMessagePack.Object([
      ("type", .string("cancel")),
      ("cancels", .array([.number(12345)]))
    ])

    let encoded = try CanonicalMessagePack.encode(action)

    #expect(encoded.hexString == "82a474797065a663616e63656ca763616e63656c7391cd3039")
  }

  @Test func rejectsNonIntegralNumbersForMessagePackIntegerFields() {
    #expect(throws: ValidationError.self) {
      _ = try CanonicalMessagePack.encode(.init([("nonce", .number(1.5))]))
    }
  }
}
