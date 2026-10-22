//
//  HyperliquidOrderStatusTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidOrderStatusTests {
  @Test func decodesOfficialNestedOrderStatusResponse() throws {
    let data = Data("""
    {"status":"order","order":{"order":{"coin":"ETH","side":"A","limitPx":"2412.7","sz":"0.0","oid":1,"timestamp":1724361546645,"triggerCondition":"N/A","isTrigger":false,"triggerPx":"0.0","children":[],"isPositionTpsl":false,"reduceOnly":true,"orderType":"Market","origSz":"0.0076","tif":"FrontendMarket","cloid":null},"status":"filled","statusTimestamp":1724361546645}}
    """.utf8)

    let result = try HyperliquidOrderStatus.decode(data)

    #expect(result.isKnownOrder)
    #expect(result.order?.coin == "ETH")
    #expect(result.order?.limitPrice == "2412.7")
    #expect(result.order?.originalSize == "0.0076")
    #expect(result.status == "filled")
    #expect(result.statusTimestamp == Date(timeIntervalSince1970: 1_724_361_546.645))
  }

  @Test func decodesOfficialUnknownOrderResponse() throws {
    let result = try HyperliquidOrderStatus.decode(Data(#"{"status":"unknownOid"}"#.utf8))

    #expect(!result.isKnownOrder)
    #expect(result.order == nil)
    #expect(result.status == "unknownOid")
  }
}
