//
//  HyperliquidUserRateLimitTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidUserRateLimitTests {
  @Test func decodesOfficialUserRateLimitResponse() throws {
    let data = Data("""
    {"cumVlm":"2854574.593578","nRequestsUsed":2890,"nRequestsCap":2864574,"nRequestsSurplus":0}
    """.utf8)

    let value = try HyperliquidUserRateLimit.decode(data)

    #expect(value.cumulativeVolume == "2854574.593578")
    #expect(value.requestsUsed == 2_890)
    #expect(value.requestsCap == 2_864_574)
    #expect(value.requestsSurplus == 0)
  }
}
