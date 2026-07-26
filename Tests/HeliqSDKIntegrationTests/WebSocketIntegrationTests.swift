//
//  WebSocketIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Live Hyperliquid testnet coverage for every SubscriptionChannel.
//

import Foundation
import Testing
import HeliqSDK

struct WebSocketIntegrationTests {
  private func makeService() -> WebSocketService {
    let url = URL(string: Constants.WebSocket.url(for: .testnet))!
    return WebSocketService(url: url)
  }

  private func withConnectedService(_ body: (WebSocketService) async throws -> Void) async throws {
    let service = makeService()
    service.connect()
    try await Task.sleep(nanoseconds: 2_000_000_000)
    defer { service.disconnect() }
    try await body(service)
  }

  @Test func testIntegration_webSocketConnect_toTestnet_succeeds() async throws {
    try await withConnectedService { _ in }
  }

  @Test func testIntegration_subscribe_allMids() async throws {
    try await withConnectedService { service in
      try service.subscribe(channel: "allMids")
      try await Task.sleep(nanoseconds: 1_500_000_000)
      try service.unsubscribe(channel: "allMids")
    }
  }

  @Test func testIntegration_subscribe_l2Book_BTC() async throws {
    try await withConnectedService { service in
      try service.subscribe(channel: "l2Book", payload: ["coin": "BTC"])
      try await Task.sleep(nanoseconds: 1_500_000_000)
      try service.unsubscribe(channel: "l2Book")
    }
  }

  @Test func testIntegration_subscribe_trades_BTC() async throws {
    try await withConnectedService { service in
      try service.subscribe(channel: "trades", payload: ["coin": "BTC"])
      try await Task.sleep(nanoseconds: 1_500_000_000)
      try service.unsubscribe(channel: "trades")
    }
  }

  @Test func testIntegration_subscribe_candle_BTC_1m() async throws {
    try await withConnectedService { service in
      try service.subscribe(channel: "candle", payload: ["coin": "BTC", "interval": "1m"])
      try await Task.sleep(nanoseconds: 1_500_000_000)
      try service.unsubscribe(channel: "candle")
    }
  }

  @Test func testIntegration_subscribe_bbo_BTC() async throws {
    try await withConnectedService { service in
      try service.subscribe(channel: "bbo", payload: ["coin": "BTC"])
      try await Task.sleep(nanoseconds: 1_500_000_000)
      try service.unsubscribe(channel: "bbo")
    }
  }

  @Test func testIntegration_subscribe_activeAssetCtx_BTC() async throws {
    try await withConnectedService { service in
      try service.subscribe(channel: "activeAssetCtx", payload: ["coin": "BTC"])
      try await Task.sleep(nanoseconds: 1_500_000_000)
      try service.unsubscribe(channel: "activeAssetCtx")
    }
  }

  @Test func testIntegration_subscribe_userChannels_withZeroAddress() async throws {
    // user* channels require a user address in official HL protocol; SDK currently
    // does not attach user in SubscriptionChannel.payload — this documents the gap.
    try await withConnectedService { service in
      try service.subscribe(channel: "userEvents")
      try service.subscribe(channel: "userFills")
      try service.subscribe(channel: "orderUpdates")
      try service.subscribe(channel: "userFundings")
      try service.subscribe(channel: "userNonFundingLedgerUpdates")
      try service.subscribe(channel: "webData2")
      try await Task.sleep(nanoseconds: 1_500_000_000)
    }
  }

  @Test func testIntegration_subscriptionManager_tracksChannels() async throws {
    let manager = SubscriptionManager(webSocketService: nil)
    try await manager.subscribe(to: .allMids)
    try await manager.subscribe(to: .l2Book(coin: "BTC"))
    try await manager.subscribe(to: .trades(coin: "ETH"))
    try await manager.subscribe(to: .candle(coin: "BTC", interval: "1m"))
    try await manager.subscribe(to: .bbo(coin: "SOL"))
    try await manager.subscribe(to: .activeAssetCtx(coin: "BTC"))
    try await manager.subscribe(to: .activeAssetData(coin: "BTC"))
    try await manager.subscribe(to: .userEvents)
    try await manager.subscribe(to: .userFills)
    try await manager.subscribe(to: .orderUpdates)
    try await manager.subscribe(to: .userFundings)
    try await manager.subscribe(to: .userNonFundingLedgerUpdates)
    try await manager.subscribe(to: .webData2)

    #expect(manager.getActiveSubscriptions().count == 13)
    try await manager.unsubscribeAll()
    #expect(manager.getActiveSubscriptions().isEmpty)
  }

  @Test func testIntegration_webSocketReconnect_afterDisconnect() async throws {
    let service = makeService()
    service.connect()
    try await Task.sleep(nanoseconds: 1_500_000_000)
    service.disconnect()
    try await Task.sleep(nanoseconds: 500_000_000)
    service.connect()
    try await Task.sleep(nanoseconds: 1_500_000_000)
    service.disconnect()
  }

  @Test func testIntegration_multipleSubscriptions() async throws {
    try await withConnectedService { service in
      try service.subscribe(channel: "allMids")
      try service.subscribe(channel: "l2Book", payload: ["coin": "BTC"])
      try service.subscribe(channel: "trades", payload: ["coin": "BTC"])
      try await Task.sleep(nanoseconds: 2_000_000_000)
    }
  }
}
