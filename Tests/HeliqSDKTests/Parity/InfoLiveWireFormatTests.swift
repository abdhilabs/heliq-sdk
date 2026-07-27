//
//  InfoLiveWireFormatTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct InfoLiveWireFormatTests {
  @Test func perpetualMetaAndAssetContextsMapToDemoAssetContexts() throws {
    let json = #"""
    [
      {"universe":[{"name":"BTC","szDecimals":5,"maxLeverage":40}]},
      [{"funding":"0.0001","markPx":"65000.5","openInterest":"1"}]
    ]
    """#

    let decoded = try HyperliquidMetaAndAssetCtxs.decode(Data(json.utf8))

    #expect(decoded.sdkAssetContexts == [
      AssetContext(asset: 0, name: "BTC", szDecimals: 5, weiDecimals: 8, isPerpetual: true, isSpot: false)
    ])
  }

  @Test func spotMetaAndAssetContextsMapToDemoSpotAssetContexts() throws {
    let json = #"""
    [
      {"universe":[{"name":"PURR/USDC","index":0}]},
      [{"coin":"PURR/USDC","markPx":"0.067"}]
    ]
    """#

    let decoded = try HyperliquidSpotMetaAndAssetCtxs.decode(Data(json.utf8))

    #expect(decoded.sdkAssetContexts.count == 1)
    #expect(decoded.sdkAssetContexts[0].asset == 0)
    #expect(decoded.sdkAssetContexts[0].name == "PURR/USDC")
    #expect(decoded.sdkAssetContexts[0].maxWithdraw == 0)
    #expect(decoded.sdkAssetContexts[0].hold == 0)
  }

  @Test func l2BookDecodesLiveNestedBidAndAskLevels() throws {
    let json = #"""
    {
      "coin":"BTC",
      "time":1700000000123,
      "levels":[
        [{"px":"65000.5","sz":"1.25","n":2}],
        [{"px":"65001.0","sz":"0.75","n":1}]
      ]
    }
    """#

    let book = try L2Book.decodeLiveWire(Data(json.utf8))

    #expect(book.coin == "BTC")
    #expect(book.timestamp == Date(timeIntervalSince1970: 1_700_000_000.123))
    #expect(book.levels.count == 2)
    #expect(book.levels[0].price == 65000.5)
    #expect(book.levels[0].size == 1.25)
    #expect(book.levels[0].side == .buy)
    #expect(book.levels[1].price == 65001)
    #expect(book.levels[1].size == 0.75)
    #expect(book.levels[1].side == .sell)
  }
}
