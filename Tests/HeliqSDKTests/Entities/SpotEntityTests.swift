//
//  SpotEntityTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct SpotEntityTests {
  @Test func testSpotOrder_market_encodeAndDecode_succeeds() throws {
    let order = SpotOrder(asset: 10_000, side: .buy, size: 1.5, price: nil, orderType: .market)
    let data = try JSONCoder.encode(order)
    let decoded = try JSONCoder.decode(SpotOrder.self, from: data)
    #expect(decoded.asset == 10_000)
    #expect(decoded.side == .buy)
    #expect(decoded.size == 1.5)
    #expect(decoded.price == nil)
    #expect(decoded.orderType == .market)
  }

  @Test func testSpotOrder_limit_withPriceAndCloid_encodeAndDecode_succeeds() throws {
    let order = SpotOrder(
      asset: 10_001,
      side: .sell,
      size: 2.0,
      price: 1.25,
      orderType: .limit,
      cloid: "0xabcdef0123456789abcdef0123456789"
    )
    let data = try JSONCoder.encode(order)
    let decoded = try JSONCoder.decode(SpotOrder.self, from: data)
    #expect(decoded.orderType == .limit)
    #expect(decoded.price == 1.25)
    #expect(decoded.cloid == "0xabcdef0123456789abcdef0123456789")
  }

  @Test func testSpotOrderType_allCases_rawValuesMatch() {
    #expect(SpotOrderType.market.rawValue == "market")
    #expect(SpotOrderType.limit.rawValue == "limit")
  }

  @Test func testSpotAssetContext_encodeAndDecode_succeeds() throws {
    let ctx = SpotAssetContext(asset: 0, name: "PURR/USDC", maxWithdraw: 100, hold: 1.5, spotAssetHash: "0xabc")
    let data = try JSONCoder.encode(ctx)
    let decoded = try JSONCoder.decode(SpotAssetContext.self, from: data)
    #expect(decoded.asset == 0)
    #expect(decoded.name == "PURR/USDC")
    #expect(decoded.maxWithdraw == 100)
    #expect(decoded.hold == 1.5)
    #expect(decoded.spotAssetHash == "0xabc")
  }

  @Test func testSpotUserState_encodeAndDecode_succeeds() throws {
    let state = SpotUserState(
      accountAddress: "0x0000000000000000000000000000000000000001",
      spotPositions: [SpotPosition(asset: 0, totalSize: 10, hold: 1)],
      totalUsdc: 100.5
    )
    let data = try JSONCoder.encode(state)
    let decoded = try JSONCoder.decode(SpotUserState.self, from: data)
    #expect(decoded.accountAddress.hasPrefix("0x"))
    #expect(decoded.spotPositions.count == 1)
    #expect(decoded.totalUsdc == 100.5)
  }

  @Test func testSpotPosition_encodeAndDecode_succeeds() throws {
    let pos = SpotPosition(asset: 150, totalSize: 42.5, hold: 0.5)
    let data = try JSONCoder.encode(pos)
    let decoded = try JSONCoder.decode(SpotPosition.self, from: data)
    #expect(decoded.asset == 150)
    #expect(decoded.totalSize == 42.5)
    #expect(decoded.hold == 0.5)
  }
}
