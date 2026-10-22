//
//  HyperliquidFrontendOpenOrderTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidFrontendOpenOrderTests {
  @Test func decodesOfficialFrontendOpenOrder() throws {
    let data = Data("""
    [{
      "coin":"BTC", "isPositionTpsl":false, "isTrigger":true,
      "limitPx":"29792.0", "oid":91490942, "orderType":"Stop Market",
      "origSz":"5.0", "reduceOnly":true, "side":"A", "sz":"5.0",
      "timestamp":1681247412573, "triggerCondition":"Price below 30000",
      "triggerPx":"30000.0"
    }]
    """.utf8)

    let orders = try HyperliquidFrontendOpenOrder.decodeList(data)

    #expect(orders.count == 1)
    #expect(orders[0].orderID == 91_490_942)
    #expect(orders[0].isTrigger)
    #expect(orders[0].reduceOnly)
    #expect(orders[0].limitPrice == "29792.0")
    #expect(orders[0].triggerPrice == "30000.0")
  }
}
