//
//  CandleChartModel.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 17/10/26.
//

import Foundation
import HeliqSDK
import Observation

/// Owns one screen's candle stream using the SDK transport, typed routing, and query APIs.
@MainActor @Observable
final class CandleChartModel {
  private(set) var buffer = CandleBuffer(coin: "", interval: .minute)
  private(set) var status = "Disconnected"
  private(set) var error: String?
  private(set) var lastUpdate: Date?
  private(set) var updateCount = 0
  private var streamCurrent = false
  private var generation = UUID()
  private var historyTask: Task<Void, Never>?

  /// Runs until its SwiftUI task is canceled; every session owns and cleans up its socket.
  func run(
    coin: String, interval: PerpsCandleInterval, client: HeliqClient?,
    scenario: DemoScenario? = DemoScenario.current
  ) async {
    let session = UUID()
    historyTask?.cancel()
    historyTask = nil
    generation = session
    buffer = CandleBuffer(coin: coin, interval: interval)
    error = nil
    lastUpdate = nil
    updateCount = 0
    guard !coin.isEmpty else { status = "Choose market"; return }
    if let scenario {
      await runFixture(scenario, coin: coin, interval: interval, session: session)
      return
    }
    guard let client,
      let url = URL(string: Constants.WebSocket.url(for: client.environment))
    else { status = "Initialize SDK in Settings"; return }
    status = "Connecting…"
    let (events, continuation) = AsyncStream<WebSocketEvent>.makeStream()
    let service = WebSocketService(url: url) { continuation.yield($0) }
    let router = WebSocketMessageRouter()
    let subscription = PerpsSubscription<[PerpsCandle]>.candles(coin: coin, interval: interval)
    do {
      try router.registerPerpsHandler(for: subscription) { [weak self] result in
        Task { @MainActor [weak self] in
          guard let self, self.generation == session else { return }
          switch result {
          case .success(let values):
            guard self.buffer.receive(values) else { return }
            self.streamCurrent = true
            self.lastUpdate = Date()
            self.updateCount += 1
            if self.buffer.isReady { self.status = "Live" }
          case .failure(let error): self.error = error.demoDescription
          }
        }
      }
    } catch { self.error = error.demoDescription; continuation.finish(); return }
    var manager: SubscriptionManager?
    defer {
      if generation == session {
        historyTask?.cancel()
        historyTask = nil
      }
      router.unregisterPerpsHandler(for: subscription)
      continuation.finish()
      let cleanup = manager
      Task {
        try? await cleanup?.unsubscribe(from: subscription)
        await service.disconnect()
      }
      if generation == session { generation = UUID() }
    }
    await service.connect()
    for await event in events {
      guard !Task.isCancelled, generation == session else { break }
      switch event {
      case .stateChanged(.connected):
        // A new manager re-registers subscriptions on the transport's new connection.
        let subscriptions = SubscriptionManager(webSocketService: service)
        manager = subscriptions
        streamCurrent = false
        buffer.beginHistory()
        status = "Loading history · waiting for live candles"
        do {
          try await subscriptions.subscribe(to: subscription)
          loadHistory(client: client, session: session)
        } catch { self.error = error.demoDescription }
      case .stateChanged(let state):
        historyTask?.cancel()
        switch state {
        case .connecting: status = "Connecting…"
        case .reconnecting: status = "Reconnecting · showing saved candles"
        default: status = "Disconnected · showing saved candles"
        }
      case .message(let data): router.route(data)
      case .failed(let reason): error = reason
      @unknown default: status = "Unknown connection state"
      }
    }
  }

  /// Backfills after subscribing, so live updates received during HTTP loading win the merge.
  private func loadHistory(client: HeliqClient, session: UUID) {
    historyTask?.cancel()
    let coin = buffer.coin
    let interval = buffer.interval
    historyTask = Task { [weak self] in
      do {
        let end = Date()
        let seconds: TimeInterval = switch interval {
        case .fifteenMinutes: 900
        case .hour: 3_600
        case .day: 86_400
        default: 60
        }
        let values = try await client.info.perps(.candles(
          coin: coin, interval: interval,
          page: .init(startTime: end.addingTimeInterval(-seconds * 300), endTime: end)))
        try Task.checkCancellation()
        guard let self, self.generation == session else { return }
        self.buffer.finishHistory(values)
        self.error = nil
        self.status = !self.streamCurrent ? "History loaded · waiting for live candles" : "Live"
      } catch is CancellationError {
      } catch {
        guard !Task.isCancelled, let self, self.generation == session else { return }
        self.buffer.finishHistory([])
        self.status = "History unavailable"
        self.error = error.demoDescription
      }
    }
  }

  /// Provides deterministic chart states only under the existing explicit UI-test scenario flags.
  private func runFixture(
    _ scenario: DemoScenario, coin: String, interval: PerpsCandleInterval, session: UUID
  ) async {
    status = "Synthetic chart · loading"
    guard scenario != .loading else { return }
    guard scenario != .error else {
      status = "Unavailable"
      error = "Synthetic candle read failed. Retry to reload."
      return
    }
    do {
      let values = try Self.fixtureCandles(coin: coin, interval: interval)
      buffer.finishHistory(scenario == .empty ? [] : values)
      status = "Synthetic history · no exchange requests"
      if scenario != .empty {
        try await Task.sleep(for: .milliseconds(500))
        guard generation == session else { return }
        buffer.receive(Array(try Self.fixtureCandles(
          coin: coin, interval: interval, updatingLast: true).suffix(1)))
        lastUpdate = Date()
        updateCount = 1
        status = "Synthetic live update · no exchange requests"
      }
    } catch is CancellationError {} catch { self.error = error.demoDescription }
  }

  /// Decodes a small repeatable price series through the same protocol model used by the SDK.
  static func fixtureCandles(
    coin: String, interval: PerpsCandleInterval, updatingLast: Bool = false
  ) throws -> [PerpsCandle] {
    let seconds: Int64 = switch interval {
    case .fifteenMinutes: 900
    case .hour: 3_600
    case .day: 86_400
    default: 60
    }
    let payload: [[String: Any]] = (0..<60).map { index in
      let time = Int64(1_760_000_000) / seconds * seconds + Int64(index) * seconds
      let price = 50_000 + index * 5 + (index % 7) * 10
      return ["t": time * 1_000, "T": (time + seconds) * 1_000 - 1, "s": coin,
        "i": interval.rawValue, "o": "\(price)",
        "c": "\(price + (updatingLast && index == 59 ? 11 : 10))",
        "h": "\(price + 20)", "l": "\(price - 20)", "v": "\(index + 1)", "n": 3]
    }
    return try JSONDecoder().decode(
      [PerpsCandle].self, from: JSONSerialization.data(withJSONObject: payload))
  }
}
