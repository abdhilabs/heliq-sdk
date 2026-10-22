//
//  PerpsWebSocketIntegrationTests.swift
//  HeliqSDKIntegrationTests
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import Testing

@testable import HeliqSDK

@Suite(
  .serialized, .enabled(if: ProcessInfo.processInfo.environment["HELIQ_PERPS_READ_TESTS"] == "1"))
struct PerpsWebSocketIntegrationTests {
  @Test func typedSnapshotsDecodeAndUnsubscribeThroughExistingTransport() async throws {
    let user = "0x444483eba5faa8a1499a4d2261c5e4e927b558cf"
    let specs: [PerpsSnapshotSpec] = [
      .capture(PerpsSubscription<PerpsAccountEvent>.account(user: user)),
      .capture(PerpsSubscription<PerpsSpotEvent>.spotState(user: user)),
      .capture(PerpsSubscription<PerpsAllDexsAccountEvent>.allAccounts(user: user)),
      .capture(PerpsSubscription<PerpsAllDexsContextsEvent>.allContexts()),
      .capture(PerpsSubscription<PerpsActiveAssetData>.activeAsset(user: user, coin: "BTC")),
      .capture(PerpsSubscription<PerpsAssetContextEvent>.assetContext(coin: "BTC")),
      .capture(PerpsSubscription<PerpsOpenOrdersEvent>.openOrders(user: user)),
      .capture(PerpsSubscription<PerpsFillsEvent>.fills(user: user)),
      .capture(PerpsSubscription<PerpsTwapSliceEvent>.twapSlices(user: user)),
      .capture(PerpsSubscription<PerpsTwapHistoryEvent>.twapHistory(user: user)),
      .capture(PerpsSubscription<PerpsTwapStatesEvent>.twapStates(user: user)),
      .capture(PerpsSubscription<PerpsMidsEvent>.mids()),
      .capture(PerpsSubscription<PerpsBbo>.bbo(coin: "BTC")),
      .capture(PerpsSubscription<[PerpsCandle]>.candles(coin: "BTC", interval: .minute)),
      .capture(PerpsSubscription<PerpsBook>.book(coin: "BTC")),
      .capture(PerpsSubscription<PerpsFundingsEvent>.funding(user: user)),
      .capture(PerpsSubscription<PerpsLedgerEvent>.ledger(user: user)),
      .capture(PerpsSubscription<PerpsWebData3>.webData(user: user)),
      .capture(PerpsSubscription<PerpsFastContexts>.fastContexts()),
    ]
    let collector = PerpsSnapshotCollector(specs: specs)
    let service = WebSocketService(
      url: URL(string: Constants.WebSocket.testnetURL)!,
      eventHandler: { event in
        Task { await collector.receive(event) }
      })
    await service.connect()
    for _ in 0..<100 {
      if await collector.connected { break }
      try await Task.sleep(for: .milliseconds(100))
    }
    guard await collector.connected else {
      await service.disconnect()
      throw APIError.invalidResponse
    }
    let manager = SubscriptionManager(webSocketService: service)
    do {
      for spec in specs { try await manager.subscribe(to: spec.raw) }
      for _ in 0..<200 {
        if await collector.finished { break }
        try await Task.sleep(for: .milliseconds(100))
      }
      let pending = await collector.pending
      for name in pending { Issue.record("No snapshot received for \(name)") }
      let failures = await collector.failures
      for (name, reason) in failures { Issue.record("\(name) snapshot decoding: \(reason)") }
      let passes = await collector.passes
      for name in passes.sorted() { print("PERPS WS PASS: \(name)") }
      for spec in specs {
        try await manager.unsubscribe(from: spec.raw)
        #expect(!manager.isSubscribed(to: spec.raw))
      }
      await service.disconnect()
    } catch {
      try? await manager.unsubscribeAll()
      await service.disconnect()
      throw error
    }
  }
}
private struct PerpsSnapshotSpec: Sendable {
  let channel: String
  let raw: HyperliquidWebSocketSubscription
  let decode: @Sendable (Data) throws -> Void
  static func capture<Event>(_ subscription: PerpsSubscription<Event>) -> Self {
    .init(
      channel: subscription.channel, raw: subscription.subscription,
      decode: { _ = try subscription.decode($0) })
  }
}
private actor PerpsSnapshotCollector {
  let specs: [PerpsSnapshotSpec]
  var connected = false
  var pending: Set<String>
  var passes: Set<String> = []
  var failures: [String: String] = [:]
  var finished: Bool { pending.isEmpty }
  init(specs: [PerpsSnapshotSpec]) {
    self.specs = specs
    pending = Set(specs.map(\.channel))
  }
  func receive(_ event: WebSocketEvent) {
    if case .stateChanged(.connected) = event { connected = true }
    guard case .message(let data) = event,
      let packet = try? JSONDecoder().decode([String: JSONValue].self, from: data),
      case .string(let channel)? = packet["channel"], pending.contains(channel),
      let spec = specs.first(where: { $0.channel == channel })
    else { return }
    do {
      try spec.decode(data)
      passes.insert(channel)
    } catch { failures[channel] = String(describing: error) }
    pending.remove(channel)
  }
}
