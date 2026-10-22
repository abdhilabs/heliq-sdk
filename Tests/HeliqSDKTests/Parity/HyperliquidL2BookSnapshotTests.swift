//
//  HyperliquidL2BookSnapshotTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidL2BookSnapshotTests {
  @Test func decodesOfficialBidAndAskSidesWithoutFlattening() throws {
    let data = Data("""
    {"coin":"BTC","time":1681222254710,"levels":[[{"px":"30000.0","sz":"1.5","n":2}],[{"px":"30001.0","sz":"2.5","n":3}]]}
    """.utf8)

    let snapshot = try HyperliquidL2BookSnapshot.decode(data)

    #expect(snapshot.coin == "BTC")
    #expect(snapshot.timestamp == Date(timeIntervalSince1970: 1_681_222_254.710))
    #expect(snapshot.bids.count == 1)
    #expect(snapshot.asks.count == 1)
    #expect(snapshot.bids[0].price == "30000.0")
    #expect(snapshot.bids[0].size == "1.5")
    #expect(snapshot.bids[0].orderCount == 2)
    #expect(snapshot.asks[0].price == "30001.0")
  }
}
