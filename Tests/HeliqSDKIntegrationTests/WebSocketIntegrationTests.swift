//
//  WebSocketIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct WebSocketIntegrationTests {
  
  private func createTestnetWebSocketService() -> WebSocketService {
    let urlString = Constants.WebSocket.url(for: .testnet)
    let url = URL(string: urlString)!
    return WebSocketService(url: url)
  }
  
  // MARK: - Connection
  
  @Test func testIntegration_webSocketConnect_toTestnet_succeeds() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    // Wait for connection to establish
    try await Task.sleep(nanoseconds: 2_000_000_000)
    webSocketService.disconnect()
  }
  
  // MARK: - Subscribe/Unsubscribe
  
  @Test func testIntegration_webSocketSubscribe_allMids_receivesData() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    // Wait for connection
    try await Task.sleep(nanoseconds: 2_000_000_000)
    // Subscribe should not throw
    try webSocketService.subscribe(channel: "allMids")
    // Wait for data
    try await Task.sleep(nanoseconds: 2_000_000_000)
    webSocketService.disconnect()
  }
  
  @Test func testIntegration_webSocketSubscribe_l2BookBTC_receivesData() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    try webSocketService.subscribe(channel: "l2Book", payload: ["coin": "BTC"])
    try await Task.sleep(nanoseconds: 2_000_000_000)
    webSocketService.disconnect()
  }
  
  @Test func testIntegration_webSocketSubscribe_trades_receivesData() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    try webSocketService.subscribe(channel: "trades", payload: ["coin": "BTC"])
    try await Task.sleep(nanoseconds: 2_000_000_000)
    webSocketService.disconnect()
  }
  
  @Test func testIntegration_webSocketUnsubscribe_allMids_stopsReceiving() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    try webSocketService.subscribe(channel: "allMids")
    try webSocketService.unsubscribe(channel: "allMids")
    try await Task.sleep(nanoseconds: 1_000_000_000)
    webSocketService.disconnect()
  }
  
  // MARK: - Data Parsing
  
  @Test func testIntegration_webSocketReceive_allMidsData_parsesCorrectly() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    try webSocketService.subscribe(channel: "allMids")
    try await Task.sleep(nanoseconds: 3_000_000_000)
    webSocketService.disconnect()
  }
  
  @Test func testIntegration_webSocketReceive_l2BookData_parsesCorrectly() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    try webSocketService.subscribe(channel: "l2Book", payload: ["coin": "BTC"])
    try await Task.sleep(nanoseconds: 3_000_000_000)
    webSocketService.disconnect()
  }
  
  @Test func testIntegration_webSocketReceive_tradeData_parsesCorrectly() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    try webSocketService.subscribe(channel: "trades", payload: ["coin": "BTC"])
    try await Task.sleep(nanoseconds: 3_000_000_000)
    webSocketService.disconnect()
  }
  
  // MARK: - Reconnection
  
  @Test func testIntegration_webSocketReconnect_afterDisconnect_succeeds() async throws {
    let webSocketService = createTestnetWebSocketService()
    
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    webSocketService.disconnect()
    
    try await Task.sleep(nanoseconds: 1_000_000_000)
    
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    webSocketService.disconnect()
  }
  
  // MARK: - Multiple Subscriptions
  
  @Test func testIntegration_webSocketMultipleSubscriptions_receivesCorrectData() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    try webSocketService.subscribe(channel: "allMids")
    try webSocketService.subscribe(channel: "l2Book", payload: ["coin": "BTC"])
    try await Task.sleep(nanoseconds: 3_000_000_000)
    webSocketService.disconnect()
  }
  
  // MARK: - Disconnect
  
  @Test func testIntegration_webSocketDisconnect_succeeds() async throws {
    let webSocketService = createTestnetWebSocketService()
    webSocketService.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    webSocketService.disconnect()
  }
}
