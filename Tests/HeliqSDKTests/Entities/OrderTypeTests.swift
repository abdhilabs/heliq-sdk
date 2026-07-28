//
//  OrderTypeTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct OrderTypeTests {
  @Test func testOrderSide_buy_rawValueIsCorrect() throws {
    #expect(OrderSide.buy.rawValue == "Buy")
  }
  
  @Test func testOrderSide_sell_rawValueIsCorrect() throws {
    #expect(OrderSide.sell.rawValue == "Sell")
  }
  
  @Test func testOrderType_market_encodeAndDecode_succeeds() throws {
    let orderType = OrderType.market
    let data = try JSONCoder.encode(orderType)
    let decoded = try JSONCoder.decode(OrderType.self, from: data)
    
    var isMarket = false
    if case .market = decoded { isMarket = true }
    #expect(isMarket == true)
  }
  
  @Test func testOrderType_limit_encodeAndDecode_succeeds() throws {
    let orderType = OrderType.limit
    let data = try JSONCoder.encode(orderType)
    let decoded = try JSONCoder.decode(OrderType.self, from: data)
    
    var isLimit = false
    if case .limit = decoded { isLimit = true }
    #expect(isLimit == true)
  }
  
  @Test func testOrderType_triggerMarket_withTriggerParams_encodeAndDecode_succeeds() throws {
    let trigger = TriggerParams(triggerPx: 50000.0, tpsl: "tp")
    let orderType = OrderType.triggerMarket(trigger)
    let data = try JSONCoder.encode(orderType)
    let decoded = try JSONCoder.decode(OrderType.self, from: data)
    
    var match = false
    var decodedTriggerPx: Double = 0
    var decodedTpsl: String = ""
    if case .triggerMarket(let t) = decoded {
      match = true
      decodedTriggerPx = t.triggerPx
      decodedTpsl = t.tpsl
    }
    #expect(match == true)
    #expect(decodedTriggerPx == 50000.0)
    #expect(decodedTpsl == "tp")
  }
  
  @Test func testOrderType_triggerLimit_withTriggerParams_encodeAndDecode_succeeds() throws {
    let trigger = TriggerParams(triggerPx: 45000.0, tpsl: "sl")
    let orderType = OrderType.triggerLimit(trigger)
    let data = try JSONCoder.encode(orderType)
    let decoded = try JSONCoder.decode(OrderType.self, from: data)
    
    var match = false
    var decodedTriggerPx: Double = 0
    var decodedTpsl: String = ""
    if case .triggerLimit(let t) = decoded {
      match = true
      decodedTriggerPx = t.triggerPx
      decodedTpsl = t.tpsl
    }
    #expect(match == true)
    #expect(decodedTriggerPx == 45000.0)
    #expect(decodedTpsl == "sl")
  }
  
  @Test func testTriggerParams_encodeAndDecode_preservesValues() throws {
    let params = TriggerParams(triggerPx: 50000.0, tpsl: "tp")
    let data = try JSONCoder.encode(params)
    let decoded = try JSONCoder.decode(TriggerParams.self, from: data)
    
    #expect(decoded.triggerPx == 50000.0)
    #expect(decoded.tpsl == "tp")
  }
  
  @Test func testTriggerOrderType_marketIfMarket_encodeAndDecodeCorrectly() throws {
    let triggerType = TriggerOrderType.marketIfMarket
    #expect(triggerType.rawValue == "marketIfMarket")
    
    let data = try JSONCoder.encode(triggerType)
    let decoded = try JSONCoder.decode(TriggerOrderType.self, from: data)
    #expect(decoded.rawValue == "marketIfMarket")
  }
  
  @Test func testTriggerOrderType_marketIfLimit_encodeAndDecodeCorrectly() throws {
    let triggerType = TriggerOrderType.marketIfLimit
    #expect(triggerType.rawValue == "marketIfLimit")
    
    let data = try JSONCoder.encode(triggerType)
    let decoded = try JSONCoder.decode(TriggerOrderType.self, from: data)
    #expect(decoded.rawValue == "marketIfLimit")
  }
  
  @Test func testTriggerOrderType_limitIfMarket_encodeAndDecodeCorrectly() throws {
    let triggerType = TriggerOrderType.limitIfMarket
    #expect(triggerType.rawValue == "limitIfMarket")
    
    let data = try JSONCoder.encode(triggerType)
    let decoded = try JSONCoder.decode(TriggerOrderType.self, from: data)
    #expect(decoded.rawValue == "limitIfMarket")
  }
  
  @Test func testTriggerOrderType_limitIfLimit_encodeAndDecodeCorrectly() throws {
    let triggerType = TriggerOrderType.limitIfLimit
    #expect(triggerType.rawValue == "limitIfLimit")
    
    let data = try JSONCoder.encode(triggerType)
    let decoded = try JSONCoder.decode(TriggerOrderType.self, from: data)
    #expect(decoded.rawValue == "limitIfLimit")
  }
  
  @Test func decodingUnknownOrderTypeThrows() throws {
    let data = Data("{\"type\":\"unsupported\"}".utf8)

    #expect(throws: DecodingError.self) {
      _ = try JSONCoder.decode(OrderType.self, from: data)
    }
  }

  @Test func decodingUnknownTriggerOrderTypeThrows() throws {
    let data = Data("{\"type\":\"unsupported\"}".utf8)

    #expect(throws: DecodingError.self) {
      _ = try JSONCoder.decode(TriggerOrderType.self, from: data)
    }
  }

  @Test func testOrderRequest_marketOrder_encodeAndDecode_succeeds() throws {
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 1.0,
      price: nil,
      reduceOnly: false,
      cloid: nil
    )
    
    let data = try JSONCoder.encode(order)
    let decoded = try JSONCoder.decode(OrderRequest.self, from: data)
    
    #expect(decoded.asset == 0)
    #expect(decoded.side == .buy)
    #expect(decoded.size == 1.0)
    #expect(decoded.reduceOnly == false)
  }
  
  @Test func testOrderRequest_limitOrder_withOptionalFields_encodeAndDecode_succeeds() throws {
    let order = OrderRequest(
      asset: 1,
      side: .sell,
      orderType: .limit,
      size: 0.5,
      price: 50000.0,
      reduceOnly: true,
      cloid: "0x1234567890abcdef"
    )
    
    let data = try JSONCoder.encode(order)
    let decoded = try JSONCoder.decode(OrderRequest.self, from: data)
    
    #expect(decoded.asset == 1)
    #expect(decoded.side == .sell)
    #expect(decoded.size == 0.5)
    #expect(decoded.price == 50000.0)
    #expect(decoded.reduceOnly == true)
    #expect(decoded.cloid == "0x1234567890abcdef")
  }
  
  @Test func testFill_encodeAndDecode_preservesAllFields() throws {
    let fill = Fill(
      id: "fill-123",
      orderId: "order-456",
      side: .buy,
      price: 50000.0,
      size: 1.0,
      fee: 25.0,
      timestamp: Date(timeIntervalSince1970: 1700000000),
      symbol: "BTC"
    )
    
    let data = try JSONCoder.encode(fill)
    let decoded = try JSONCoder.decode(Fill.self, from: data)
    
    #expect(decoded.id == "fill-123")
    #expect(decoded.orderId == "order-456")
    #expect(decoded.side == .buy)
    #expect(decoded.price == 50000.0)
    #expect(decoded.size == 1.0)
    #expect(decoded.fee == 25.0)
    #expect(decoded.symbol == "BTC")
  }
  
  @Test func testCloid_withValidHexString_createsCorrectly() throws {
    let hexString = "0x1234567890abcdef"
    let cloid = Cloid(hexString: hexString)
    
    #expect(cloid != nil)
    #expect(cloid?.hexString == hexString)
    #expect(cloid?.value == "1234567890abcdef")
  }
  
  @Test func testCloid_withInvalidLength_returnsNil() throws {
    let hexString = "0x1234"
    let cloid = Cloid(hexString: hexString)
    
    #expect(cloid == nil)
  }
  
  @Test func testCloid_withValidNoPrefix_createsCorrectly() throws {
    let hexString = "1234567890abcdef"
    let cloid = Cloid(hexString: hexString)
    
    #expect(cloid != nil)
    #expect(cloid?.value == "1234567890abcdef")
  }
}
