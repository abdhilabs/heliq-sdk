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
  private func makeService() -> WebSocketService {
    let url = URL(string: Constants.WebSocket.url(for: .testnet))!
    return WebSocketService(url: url)
  }

  private func withConnectedService(
    _ body: (WebSocketService) async throws -> Void
  ) async throws {
    let service = makeService()
    await service.connect()
    try await Task.sleep(for: .seconds(2))
    defer {
      Task {
        await service.disconnect()
      }
    }
    try await body(service)
  }

  @Test func testIntegration_webSocketConnect_toTestnet_succeeds() async throws {
    try await withConnectedService { _ in }
  }

  @Test func testIntegration_subscribe_allMids() async throws {
    try await withConnectedService { service in
      try await service.subscribe(channel: "allMids")
      try await Task.sleep(for: .seconds(1.5))
      try await service.unsubscribe(channel: "allMids")
    }
  }

  @Test func testIntegration_subscribe_l2Book_BTC() async throws {
    try await withConnectedService { service in
      try await service.subscribe(channel: "l2Book", payload: ["coin": "BTC"])
      try await Task.sleep(for: .seconds(1.5))
      try await service.unsubscribe(channel: "l2Book")
    }
  }

  @Test func testIntegration_subscribe_trades_BTC() async throws {
    try await withConnectedService { service in
      try await service.subscribe(channel: "trades", payload: ["coin": "BTC"])
      try await Task.sleep(for: .seconds(1.5))
      try await service.unsubscribe(channel: "trades")
    }
  }

  @Test func testIntegration_subscribe_candle_BTC_1m() async throws {
    try await withConnectedService { service in
      try await service.subscribe(
        channel: "candle",
        payload: ["coin": "BTC", "interval": "1m"]
      )
      try await Task.sleep(for: .seconds(1.5))
      try await service.unsubscribe(channel: "candle")
    }
  }

  @Test func testIntegration_subscribe_bbo_BTC() async throws {
    try await withConnectedService { service in
      try await service.subscribe(channel: "bbo", payload: ["coin": "BTC"])
      try await Task.sleep(for: .seconds(1.5))
      try await service.unsubscribe(channel: "bbo")
    }
  }

  @Test func testIntegration_subscribe_activeAssetCtx_BTC() async throws {
    try await withConnectedService { service in
      try await service.subscribe(
        channel: "activeAssetCtx",
        payload: ["coin": "BTC"]
      )
      try await Task.sleep(for: .seconds(1.5))
      try await service.unsubscribe(channel: "activeAssetCtx")
    }
  }

  @Test func testIntegration_subscribe_userChannels_withZeroAddress() async throws {
    try await withConnectedService { service in
      try await service.subscribe(channel: "userEvents")
      try await service.subscribe(channel: "userFills")
      try await service.subscribe(channel: "orderUpdates")
      try await service.subscribe(channel: "userFundings")
      try await service.subscribe(channel: "userNonFundingLedgerUpdates")
      try await service.subscribe(channel: "webData2")
      try await Task.sleep(for: .seconds(1.5))
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
    await service.connect()
    try await Task.sleep(for: .seconds(1.5))
    await service.disconnect()
    try await Task.sleep(for: .milliseconds(500))
    await service.connect()
    try await Task.sleep(for: .seconds(1.5))
    await service.disconnect()
  }

  @Test func testIntegration_multipleSubscriptions() async throws {
    try await withConnectedService { service in
      try await service.subscribe(channel: "allMids")
      try await service.subscribe(channel: "l2Book", payload: ["coin": "BTC"])
      try await service.subscribe(channel: "trades", payload: ["coin": "BTC"])
      try await Task.sleep(for: .seconds(2))
    }
  }
}
