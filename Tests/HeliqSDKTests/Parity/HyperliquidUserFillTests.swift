//
//  HyperliquidUserFillTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidUserFillTests {
  @Test func decodesOfficialUserFillWithoutDecimalCoercion() throws {
    let data = Data("""
    [{"closedPnl":"0.0","coin":"AVAX","crossed":false,"dir":"Open Long","hash":"0xa166e3fa63c25663024b03f2e0da011a00307e4017465df020210d3d432e7cb8","oid":90542681,"px":"18.435","side":"B","startPosition":"26.86","sz":"93.53","time":1681222254710,"fee":"0.01","feeToken":"USDC","builderFee":"0.01","tid":118906512037719}]
    """.utf8)

    let fills = try HyperliquidUserFill.decodeList(data)

    #expect(fills.count == 1)
    #expect(fills[0].coin == "AVAX")
    #expect(fills[0].price == "18.435")
    #expect(fills[0].size == "93.53")
    #expect(fills[0].tradeID == 118_906_512_037_719)
    #expect(fills[0].builderFee == "0.01")
  }
}
