//
//  WebSocketMessageParserTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct WebSocketMessageParserTests {
  @Test func testParse_subscribeMessage_returnsSubscribe() throws {
    let parser = WebSocketMessageParser()
    let jsonData = "{\"method\":\"subscribe\",\"channel\":\"allMids\",\"payload\":{}}".data(using: .utf8)!
    
    let result = try parser.parse(jsonData)
    
    var isSubscribe = false
    var channelName = ""
    if case .subscribe(let channel, _) = result {
      isSubscribe = true
      channelName = channel
    }
    #expect(isSubscribe == true)
    #expect(channelName == "allMids")
  }
  
  @Test func testParse_unsubscribeMessage_returnsUnsubscribe() throws {
    let parser = WebSocketMessageParser()
    let jsonData = "{\"method\":\"unsubscribe\",\"channel\":\"allMids\"}".data(using: .utf8)!
    
    let result = try parser.parse(jsonData)
    
    var isUnsubscribe = false
    var channelName = ""
    if case .unsubscribe(let channel) = result {
      isUnsubscribe = true
      channelName = channel
    }
    #expect(isUnsubscribe == true)
    #expect(channelName == "allMids")
  }
  
  @Test func testParse_dataMessage_returnsData() throws {
    let parser = WebSocketMessageParser()
    let jsonData = "{\"some\":\"data\"}".data(using: .utf8)!
    
    let result = try parser.parse(jsonData)
    
    var isData = false
    if case .data = result { isData = true }
    #expect(isData == true)
  }
  
  @Test func testParse_invalidJSON_throwsValidationError() throws {
    let parser = WebSocketMessageParser()
    let invalidData = Data([0xFF, 0xFE])
    
    var threwError = false
    do {
      _ = try parser.parse(invalidData)
    } catch {
      threwError = true
    }
    #expect(threwError == true)
  }
  
  @Test func testEncode_subscribeMessage_returnsData() throws {
    let parser = WebSocketMessageParser()
    let message = WebSocketMessage.subscribe(channel: "allMids", payload: nil)
    
    let data = try parser.encode(message)
    let jsonString = String(data: data, encoding: .utf8) ?? ""
    
    #expect(jsonString.contains("subscribe"))
    #expect(jsonString.contains("allMids"))
  }
  
  @Test func testEncode_unsubscribeMessage_returnsData() throws {
    let parser = WebSocketMessageParser()
    let message = WebSocketMessage.unsubscribe(channel: "l2Book")
    
    let data = try parser.encode(message)
    let jsonString = String(data: data, encoding: .utf8) ?? ""
    
    #expect(jsonString.contains("unsubscribe"))
    #expect(jsonString.contains("l2Book"))
  }
}

struct WebSocketMessageRouterTests {
  @Test func testRegisterHandler_storesHandler() async throws {
    let router = WebSocketMessageRouter()
    var handlerCallCount = 0
    let handler: (Data) -> Void = { _ in handlerCallCount += 1 }
    
    router.registerHandler(handler, for: "allMids")
    
    let jsonData = "{\"method\":\"subscribe\",\"channel\":\"allMids\"}".data(using: .utf8)!
    router.route(jsonData)
    
    try await Task.sleep(nanoseconds: 50_000_000)
    
    #expect(handlerCallCount == 1)
  }
  
  @Test func testUnregisterHandler_removesHandler() throws {
    let router = WebSocketMessageRouter()
    var handlerCallCount = 0
    let handler: (Data) -> Void = { _ in handlerCallCount += 1 }
    
    router.registerHandler(handler, for: "allMids")
    router.unregisterHandler(for: "allMids")
    
    let jsonData = "{\"method\":\"subscribe\",\"channel\":\"allMids\"}".data(using: .utf8)!
    router.route(jsonData)
    
    #expect(handlerCallCount == 0)
  }
  
  @Test func testClearAllHandlers_removesAllHandlers() throws {
    let router = WebSocketMessageRouter()
    var handlerCallCount = 0
    let handler: (Data) -> Void = { _ in handlerCallCount += 1 }
    
    router.registerHandler(handler, for: "allMids")
    router.registerHandler(handler, for: "l2Book")
    router.clearAllHandlers()
    
    let jsonData = "{\"method\":\"subscribe\",\"channel\":\"allMids\"}".data(using: .utf8)!
    router.route(jsonData)
    
    #expect(handlerCallCount == 0)
  }
}

struct WebSocketReconnectionHandlerTests {
  @Test func testShouldReconnect_withinFailureLimit_returnsTrue() async throws {
    let handler = WebSocketReconnectionHandler()
    
    let result = await handler.shouldReconnect()
    
    #expect(result == true)
  }
  
  @Test func testShouldReconnect_atMaxFailures_returnsFalse() async throws {
    let handler = WebSocketReconnectionHandler()
    
    for _ in 0..<5 {
      await handler.recordFailure()
    }
    
    let result = await handler.shouldReconnect()
    
    #expect(result == false)
  }
  
  @Test func testRecordFailure_incrementsCounter() async throws {
    let handler = WebSocketReconnectionHandler()
    
    await handler.recordFailure()
    await handler.recordFailure()
    
    let shouldReconnect = await handler.shouldReconnect()
    
    #expect(shouldReconnect == true)
  }
  
  @Test func testRecordSuccess_resetsCounter() async throws {
    let handler = WebSocketReconnectionHandler()
    
    for _ in 0..<3 {
      await handler.recordFailure()
    }
    await handler.recordSuccess()
    
    let shouldReconnect = await handler.shouldReconnect()
    
    #expect(shouldReconnect == true)
  }
  
  @Test func testReset_clearsCounter() async throws {
    let handler = WebSocketReconnectionHandler()
    
    for _ in 0..<3 {
      await handler.recordFailure()
    }
    await handler.reset()
    
    let shouldReconnect = await handler.shouldReconnect()
    
    #expect(shouldReconnect == true)
  }
}

struct WebSocketHealthMonitorTests {
  @Test func testRecordPing_setsLastPingTime() throws {
    let monitor = WebSocketHealthMonitor()
    
    monitor.recordPing()
    let status = monitor.getHealthStatus()
    
    #expect(status.lastPingTime != nil)
  }
  
  @Test func testRecordPong_setsLastPongTimeAndHealth() throws {
    let monitor = WebSocketHealthMonitor()
    
    monitor.recordPing()
    monitor.recordPong()
    let status = monitor.getHealthStatus()
    
    #expect(status.lastPongTime != nil)
    #expect(status.isHealthy == true)
  }
  
  @Test func testRecordConnection_resetsHealthState() throws {
    let monitor = WebSocketHealthMonitor()
    
    monitor.recordPing()
    monitor.recordConnection()
    let status = monitor.getHealthStatus()
    
    #expect(status.lastPingTime == nil)
    #expect(status.lastPongTime == nil)
    #expect(status.isHealthy == true)
  }
  
  @Test func testRecordDisconnection_setsUnhealthy() throws {
    let monitor = WebSocketHealthMonitor()
    
    monitor.recordDisconnection()
    
    #expect(monitor.shouldReportUnhealthy() == false)
  }
  
  @Test func testShouldReportUnhealthy_whenPingTimeExceededAndDisconnected_returnsTrue() async throws {
    let monitor = WebSocketHealthMonitor(pingInterval: 0.01)
    
    monitor.recordPing()
    monitor.recordDisconnection()
    
    try await Task.sleep(nanoseconds: 30_000_000)
    
    #expect(monitor.shouldReportUnhealthy() == true)
  }
}

struct SubscriptionManagerTests {
  @Test func testSubscribe_newChannel_addsToActive() async throws {
    let manager = SubscriptionManager()
    
    try await manager.subscribe(to: .allMids)
    let isSubscribed = manager.isSubscribed(to: .allMids)
    
    #expect(isSubscribed == true)
  }
  
  @Test func testSubscribe_duplicateChannel_ignores() async throws {
    let manager = SubscriptionManager()
    
    try await manager.subscribe(to: .allMids)
    try await manager.subscribe(to: .allMids)
    
    let activeSubscriptions = manager.getActiveSubscriptions()
    
    #expect(activeSubscriptions.count == 1)
  }
  
  @Test func testUnsubscribe_existingChannel_removesFromActive() async throws {
    let manager = SubscriptionManager()
    
    try await manager.subscribe(to: .allMids)
    try await manager.unsubscribe(from: .allMids)
    
    let isSubscribed = manager.isSubscribed(to: .allMids)
    
    #expect(isSubscribed == false)
  }
  
  @Test func testUnsubscribe_nonExistingChannel_ignores() async throws {
    let manager = SubscriptionManager()
    
    try await manager.unsubscribe(from: .allMids)
    
    #expect(manager.isSubscribed(to: .allMids) == false)
  }
  
  @Test func testUnsubscribeAll_removesAll() async throws {
    let manager = SubscriptionManager()
    
    try await manager.subscribe(to: .allMids)
    try await manager.subscribe(to: .l2Book(coin: "BTC"))
    try await manager.unsubscribeAll()
    
    let activeSubscriptions = manager.getActiveSubscriptions()
    
    #expect(activeSubscriptions.count == 0)
  }
  
  @Test func testIsSubscribed_withActiveChannel_returnsTrue() async throws {
    let manager = SubscriptionManager()
    
    try await manager.subscribe(to: .allMids)
    
    #expect(manager.isSubscribed(to: .allMids) == true)
    #expect(manager.isSubscribed(to: .l2Book(coin: "BTC")) == false)
  }
}
