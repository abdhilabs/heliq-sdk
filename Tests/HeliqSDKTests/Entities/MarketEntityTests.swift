//
//  MarketEntityTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct MarketEntityTests {
  @Test func testAllMids_priceForCoin_returnsPrice() throws {
    let allMids = AllMids(prices: ["BTC": 50000.0, "ETH": 3000.0])
    
    #expect(allMids.price(for: "BTC") == 50000.0)
    #expect(allMids.price(for: "ETH") == 3000.0)
  }
  
  @Test func testAllMids_priceForNonExistentCoin_returnsNil() throws {
    let allMids = AllMids(prices: ["BTC": 50000.0])
    
    #expect(allMids.price(for: "DOGE") == nil)
  }
  
  @Test func testAllMids_encodeAndDecode_succeeds() throws {
    let allMids = AllMids(prices: ["BTC": 50000.0, "ETH": 3000.0])
    let data = try JSONCoder.encode(allMids)
    let decoded = try JSONCoder.decode(AllMids.self, from: data)
    
    #expect(decoded.price(for: "BTC") == 50000.0)
    #expect(decoded.price(for: "ETH") == 3000.0)
  }
  
  @Test func testL2Book_encodeAndDecode_succeeds() throws {
    let level1 = L2Level(price: 50000.0, size: 1.0, side: .buy)
    let level2 = L2Level(price: 50100.0, size: 0.5, side: .sell)
    let l2Book = L2Book(coin: "BTC", levels: [level1, level2], timestamp: Date())
    
    let data = try JSONCoder.encode(l2Book)
    let decoded = try JSONCoder.decode(L2Book.self, from: data)
    
    #expect(decoded.coin == "BTC")
    #expect(decoded.levels.count == 2)
  }
  
  @Test func testL2Level_id_isUniqueForDifferentValues() throws {
    let level1 = L2Level(price: 50000.0, size: 1.0, side: .buy)
    let level2 = L2Level(price: 50000.0, size: 1.0, side: .sell)
    
    #expect(level1.id != level2.id)
  }
  
  @Test func testL2Level_id_isSameForSameValues() throws {
    let level1 = L2Level(price: 50000.0, size: 1.0, side: .buy)
    let level2 = L2Level(price: 50000.0, size: 1.0, side: .buy)
    
    #expect(level1.id == level2.id)
  }
  
  @Test func testCandle_encodeAndDecode_preservesAllFields() throws {
    let candle = Candle(
      timestamp: Date(timeIntervalSince1970: 1700000000),
      open: 49000.0,
      high: 51000.0,
      low: 48000.0,
      close: 50000.0,
      volume: 1000.0
    )
    
    let data = try JSONCoder.encode(candle)
    let decoded = try JSONCoder.decode(Candle.self, from: data)
    
    #expect(decoded.open == 49000.0)
    #expect(decoded.high == 51000.0)
    #expect(decoded.low == 48000.0)
    #expect(decoded.close == 50000.0)
    #expect(decoded.volume == 1000.0)
  }
  
  @Test func testCandle_id_usesTimestamp() throws {
    let candle1 = Candle(
      timestamp: Date(timeIntervalSince1970: 1700000000),
      open: 49000.0,
      high: 51000.0,
      low: 48000.0,
      close: 50000.0,
      volume: 1000.0
    )
    let candle2 = Candle(
      timestamp: Date(timeIntervalSince1970: 1700000001),
      open: 49000.0,
      high: 51000.0,
      low: 48000.0,
      close: 50000.0,
      volume: 1000.0
    )
    
    #expect(candle1.id != candle2.id)
  }
}
