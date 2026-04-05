//
//  WebSocketDataParserTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct WebSocketDataParserTests {
  @Test func testParse_allMidsChannel_returnsAllMids() throws {
    let parser = WebSocketDataParser()
    let json = "{\"BTC\":50000.0,\"ETH\":3000.0}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "allMids", data: json)
    
    var isAllMids = false
    if case .allMids(let allMids) = result {
      isAllMids = true
      #expect(allMids.price(for: "BTC") == 50000.0)
      #expect(allMids.price(for: "ETH") == 3000.0)
    }
    #expect(isAllMids == true)
  }
  
  @Test func testParse_allMidsChannel_withStringPrices_parsesCorrectly() throws {
    let parser = WebSocketDataParser()
    let json = "{\"BTC\":\"50000.0\",\"ETH\":\"3000.0\"}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "allMids", data: json)
    
    var isAllMids = false
    if case .allMids(let allMids) = result {
      isAllMids = true
      #expect(allMids.price(for: "BTC") == 50000.0)
      #expect(allMids.price(for: "ETH") == 3000.0)
    }
    #expect(isAllMids == true)
  }
  
  @Test func testParse_l2BookChannel_returnsL2Book() throws {
    let parser = WebSocketDataParser()
    let json = "{\"coin\":\"BTC\",\"bids\":[[50000.0,1.0],[49900.0,0.5]],\"asks\":[[50100.0,0.8]]}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "l2Book", data: json)
    
    var isL2Book = false
    if case .l2Book(let book) = result {
      isL2Book = true
      #expect(book.coin == "BTC")
      #expect(book.levels.count == 3)
    }
    #expect(isL2Book == true)
  }
  
  @Test func testParse_l2BookChannel_withBidsAndAsks_parsesCorrectly() throws {
    let parser = WebSocketDataParser()
    let json = "{\"coin\":\"ETH\",\"bids\":[[3000.0,2.0]],\"asks\":[[3010.0,1.5]]}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "l2Book", data: json)
    
    var isL2Book = false
    var bidCount = 0
    var askCount = 0
    if case .l2Book(let book) = result {
      isL2Book = true
      bidCount = book.levels.filter { $0.side == .buy }.count
      askCount = book.levels.filter { $0.side == .sell }.count
    }
    #expect(isL2Book == true)
    #expect(bidCount == 1)
    #expect(askCount == 1)
  }
  
  @Test func testParse_tradesChannel_returnsTradeArray() throws {
    let parser = WebSocketDataParser()
    let json = "{\"trades\":[{\"price\":50000.0,\"size\":1.0,\"side\":\"buy\",\"time\":1700000000000,\"hash\":\"0xabc\"}]}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "trades", data: json)
    
    var isTrades = false
    var tradeCount = 0
    if case .trades(let trades) = result {
      isTrades = true
      tradeCount = trades.count
    }
    #expect(isTrades == true)
    #expect(tradeCount == 1)
  }
  
  @Test func testParse_tradesChannel_withMissingFields_handlesGracefully() throws {
    let parser = WebSocketDataParser()
    let json = "{\"trades\":[{\"price\":50000.0}]}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "trades", data: json)
    
    var isTrades = false
    var tradeCount = 0
    if case .trades(let trades) = result {
      isTrades = true
      tradeCount = trades.count
    }
    #expect(isTrades == true)
    #expect(tradeCount == 0)
  }
  
  @Test func testParse_userFillsChannel_returnsFill() throws {
    let parser = WebSocketDataParser()
    let json = "{\"orderId\":\"123\",\"side\":\"buy\",\"price\":50000.0,\"size\":1.0,\"fee\":25.0,\"time\":1700000000000,\"symbol\":\"BTC\"}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "userFills", data: json)
    
    var isUserFill = false
    var orderId = ""
    var sideIsBuy = false
    if case .userFill(let fill) = result {
      isUserFill = true
      orderId = fill.orderId
      sideIsBuy = fill.side == .buy
    }
    #expect(isUserFill == true)
    #expect(orderId == "123")
    #expect(sideIsBuy == true)
  }
  
  @Test func testParse_userEventsChannel_returnsUserEvent() throws {
    let parser = WebSocketDataParser()
    let json = "{\"type\":\"orderFilled\",\"orderId\":\"123\",\"filledSize\":1.0,\"filledPx\":50000.0}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "userEvents", data: json)
    
    var isUserEvent = false
    var orderId: String? = nil
    if case .userEvent(let event) = result {
      isUserEvent = true
      orderId = event.orderId
      #expect(event.type == .orderFilled)
    }
    #expect(isUserEvent == true)
    #expect(orderId == "123")
  }
  
  @Test func testParse_userEventsChannel_withUnknownType_returnsUnknown() throws {
    let parser = WebSocketDataParser()
    let json = "{\"type\":\"unknownEvent\"}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "userEvents", data: json)
    
    var isUnknown = false
    if case .unknown = result { isUnknown = true }
    #expect(isUnknown == true)
  }
  
  @Test func testParse_candleChannel_returnsCandle() throws {
    let parser = WebSocketDataParser()
    let json = "{\"open\":49000.0,\"high\":51000.0,\"low\":48000.0,\"close\":50000.0,\"volume\":1000.0,\"time\":1700000000000}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "candle", data: json)
    
    var isCandle = false
    if case .candle(let candle) = result {
      isCandle = true
      #expect(candle.open == 49000.0)
      #expect(candle.high == 51000.0)
      #expect(candle.low == 48000.0)
    }
    #expect(isCandle == true)
  }
  
  @Test func testParse_candleChannel_withStringPrices_parsesCorrectly() throws {
    let parser = WebSocketDataParser()
    let json = "{\"open\":\"49000.0\",\"high\":\"51000.0\",\"low\":\"48000.0\",\"close\":\"50000.0\",\"volume\":\"1000.0\",\"time\":1700000000000}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "candle", data: json)
    
    var isCandle = false
    if case .candle(let candle) = result {
      isCandle = true
      #expect(candle.open == 49000.0)
    }
    #expect(isCandle == true)
  }
  
  @Test func testParse_orderUpdatesChannel_returnsOrder() throws {
    let parser = WebSocketDataParser()
    let json = "{\"oid\":\"123\",\"asset\":0,\"side\":\"buy\",\"size\":1.0,\"filled\":0.5,\"status\":\"open\",\"time\":1700000000000}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "orderUpdates", data: json)
    
    var isOrderUpdate = false
    var oid = ""
    if case .orderUpdate(let order) = result {
      isOrderUpdate = true
      oid = order.oid
    }
    #expect(isOrderUpdate == true)
    #expect(oid == "123")
  }
  
  @Test func testParse_userFundingsChannel_returnsUserFunding() throws {
    let parser = WebSocketDataParser()
    let json = "{\"asset\":0,\"payment\":10.5,\"rate\":0.0001,\"time\":1700000000000}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "userFundings", data: json)
    
    var isUserFunding = false
    var payment = 0.0
    if case .userFunding(let funding) = result {
      isUserFunding = true
      payment = funding.payment
    }
    #expect(isUserFunding == true)
    #expect(payment == 10.5)
  }
  
  @Test func testParse_unknownChannel_returnsUnknown() throws {
    let parser = WebSocketDataParser()
    let json = "{\"some\":\"data\"}".data(using: .utf8)!
    
    let result = try parser.parse(channel: "unknownChannel", data: json)
    
    var isUnknown = false
    if case .unknown = result { isUnknown = true }
    #expect(isUnknown == true)
  }
  
  @Test func testParse_invalidJSON_throwsValidationError() throws {
    let parser = WebSocketDataParser()
    let invalidData = Data([0xFF, 0xFE])
    
    var threwError = false
    do {
      _ = try parser.parse(channel: "allMids", data: invalidData)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
}

struct RetryPolicyTests {
  @Test func testRetryPolicy_defaultHas3Retries() throws {
    let policy = RetryPolicy.default
    
    #expect(policy.maxRetries == 3)
    #expect(policy.baseDelay == 1.0)
    #expect(policy.multiplier == 2.0)
  }
  
  @Test func testDelay_forAttempt1_returns1Second() throws {
    let policy = RetryPolicy.default
    
    let delay = policy.delay(for: 0)
    
    #expect(delay == 1.0)
  }
  
  @Test func testDelay_forAttempt2_returns2Seconds() throws {
    let policy = RetryPolicy.default
    
    let delay = policy.delay(for: 1)
    
    #expect(delay == 2.0)
  }
  
  @Test func testDelay_forAttempt3_returns4Seconds() throws {
    let policy = RetryPolicy.default
    
    let delay = policy.delay(for: 2)
    
    #expect(delay == 4.0)
  }
  
  @Test func testShouldRetry_withDefaultPolicy_returnsTrue() throws {
    let policy = RetryPolicy.default
    
    #expect(policy.shouldRetry == true)
  }
  
  @Test func testShouldRetry_withNoRetryPolicy_returnsFalse() throws {
    let policy = RetryPolicy.noRetry
    
    #expect(policy.shouldRetry == false)
  }
  
  @Test func testCustomPolicy_works() throws {
    let policy = RetryPolicy(maxRetries: 5, baseDelay: 0.5, multiplier: 3.0)
    
    #expect(policy.maxRetries == 5)
    #expect(policy.baseDelay == 0.5)
    #expect(policy.multiplier == 3.0)
    #expect(policy.delay(for: 0) == 0.5)
    #expect(policy.delay(for: 1) == 1.5)
  }
}
