//
//  HyperliquidOpenOrderTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidOpenOrderTests {
  @Test func decodesOfficialOpenOrderWireShapeWithoutDecimalCoercion() throws {
    let data = Data("""
    [{"coin":"BTC","limitPx":"29792.0","oid":91490942,"side":"A","sz":"0.0","timestamp":1681247412573}]
    """.utf8)

    let orders = try HyperliquidOpenOrder.decodeList(data)

    #expect(orders.count == 1)
    #expect(orders[0].coin == "BTC")
    #expect(orders[0].limitPrice == "29792.0")
    #expect(orders[0].size == "0.0")
    #expect(orders[0].orderID == 91_490_942)
    #expect(orders[0].side == .ask)
    #expect(orders[0].timestamp == Date(timeIntervalSince1970: 1_681_247_412.573))
  }
}
