//
//  FastAssetCtxDecoderTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct FastAssetCtxDecoderTests {
  @Test func decodesOfficialRawDeflateFixture() throws {
    let payload = "q1ZyCnFWsqpWyk0syg6oULJSsjQ3NTDQM1Wq1VFyDfFAkTI2MzXQMwJLVVRWWfmFuTiiyBuamOoZKdXWAgA="

    let contexts = try FastAssetCtxDecoder.decode(payload)

    #expect(contexts["BTC"]?.markPx == "97500.5")
    #expect(contexts["ETH"]?.markPx == "3650.25")
    #expect(contexts["xyz:NVDA"]?.markPx == "145.2")
  }

  @Test func rejectsInvalidBase64() {
    #expect(throws: ValidationError.self) {
      _ = try FastAssetCtxDecoder.decode("not base64")
    }
  }
}
