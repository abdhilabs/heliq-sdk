//
//  CandleChartTests.swift
//  HeliqSDKDemoTests
//
//  Created by Abdhilabs on 17/10/26.
//

import HeliqSDK
import XCTest

@testable import HeliqSDKDemo

final class CandleChartTests: XCTestCase {
  /// Decodes exact protocol values without requiring a network or wallet.
  private func candle(
    _ time: Int64, close: String = "100.25", coin: String = "BTC", interval: String = "1m"
  ) throws -> PerpsCandle {
    let json = """
      {"t":\(time),"T":\(time + 59999),"s":"\(coin)","i":"\(interval)",
      "o":"100","c":"\(close)","h":"102","l":"99","v":"2.3456789","n":1}
      """
    return try JSONDecoder().decode(PerpsCandle.self, from: Data(json.utf8))
  }

  /// Live data buffered during a slow snapshot replaces its older version of the same bar.
  func testLiveWinsSnapshotAndUpdatesCurrentBar() throws {
    var buffer = CandleBuffer(coin: "BTC", interval: .minute)
    buffer.receive([try candle(60_000, close: "101")])
    XCTAssertTrue(buffer.candles.isEmpty)
    buffer.finishHistory([try candle(60_000)])
    XCTAssertEqual(buffer.candles.count, 1)
    XCTAssertEqual(buffer.candles[0].c, 101)
    buffer.receive([try candle(60_000, close: "101.5")])
    XCTAssertEqual(buffer.candles.count, 1)
    XCTAssertEqual(buffer.candles[0].c, Decimal(string: "101.5"))
    XCTAssertEqual(buffer.candles[0].v, Decimal(string: "2.3456789"))
    XCTAssertEqual(Double(buffer.candles[0].t) / 1_000, 60)
  }

  /// Bars stay sorted and unique even when delivery order differs from candle order.
  func testNewAndOutOfOrderBars() throws {
    var buffer = CandleBuffer(coin: "BTC", interval: .minute)
    buffer.finishHistory([try candle(120_000), try candle(0)])
    buffer.receive([try candle(180_000), try candle(60_000), try candle(120_000, close: "101")])
    XCTAssertEqual(buffer.candles.map(\.t), [0, 60_000, 120_000, 180_000])
    XCTAssertEqual(buffer.candles[2].c, 101)
  }

  /// Reconnect retains the visible chart while buffering and backfills the disconnected gap.
  func testReconnectBackfill() throws {
    var buffer = CandleBuffer(coin: "BTC", interval: .minute)
    buffer.finishHistory([try candle(0)])
    buffer.beginHistory()
    buffer.receive([try candle(120_000, close: "101")])
    XCTAssertEqual(buffer.candles.count, 1)
    buffer.finishHistory([try candle(60_000), try candle(120_000)])
    XCTAssertEqual(buffer.candles.map(\.t), [0, 60_000, 120_000])
    XCTAssertEqual(buffer.candles.last?.c, 101)
  }

  /// Initial history and long-running streams remain bounded, including buffered live traffic.
  func testRetention() throws {
    let values = try (0..<700).map { try candle(Int64($0) * 60_000) }
    var buffer = CandleBuffer(coin: "BTC", interval: .minute)
    buffer.finishHistory(Array(values.reversed()))
    XCTAssertEqual(buffer.candles.count, 300)
    XCTAssertEqual(buffer.candles.first?.t, values[400].t)
    buffer.receive(values)
    XCTAssertEqual(buffer.candles.count, 500)
    XCTAssertEqual(buffer.candles.first?.t, values[200].t)
    buffer.beginHistory()
    buffer.receive(values)
    buffer.finishHistory([])
    XCTAssertEqual(buffer.candles.count, 500)
  }

  /// Market changes, intervals, and invalid prices cannot leak into the selected series.
  func testFilteringAndEmptyHistory() throws {
    var buffer = CandleBuffer(coin: "sample:BTC", interval: .minute)
    buffer.finishHistory([])
    buffer.receive([
      try candle(0), try candle(0, coin: "sample:BTC", interval: "1h"),
      try candle(0, close: "999", coin: "sample:BTC"),
      try candle(-60_000, coin: "sample:BTC"), try candle(1, coin: "sample:BTC"),
    ])
    XCTAssertTrue(buffer.isReady)
    XCTAssertTrue(buffer.candles.isEmpty)
    buffer.receive([try candle(60_000, coin: "sample:BTC")])
    XCTAssertEqual(buffer.candles.count, 1)
  }
  /// A synthetic live tick changes the candle value without adding a duplicate bar.
  @MainActor func testSyntheticLiveTickChangesPrice() async throws {
    let model = CandleChartModel()
    let history = try CandleChartModel.fixtureCandles(coin: "BTC", interval: .minute)
    await model.run(coin: "BTC", interval: .minute, client: nil, scenario: .populated)
    XCTAssertEqual(model.buffer.candles.count, 60)
    XCTAssertEqual(model.buffer.candles.last?.c, history.last!.c + 1)
    XCTAssertEqual(model.updateCount, 1)
    XCTAssertNotNil(model.lastUpdate)
  }

  /// A superseded read cannot replace a newer market, even if its delayed update finishes later.
  @MainActor func testSupersededSessionAndCancellation() async {
    let model = CandleChartModel()
    let old = Task {
      await model.run(coin: "BTC", interval: .minute, client: nil, scenario: .populated)
    }
    while model.buffer.coin != "BTC" { await Task.yield() }
    await model.run(coin: "ETH", interval: .hour, client: nil, scenario: .empty)
    await old.value
    XCTAssertEqual(model.buffer.coin, "ETH")
    XCTAssertTrue(model.buffer.candles.isEmpty)
    XCTAssertNil(model.lastUpdate)
    let canceled = Task {
      await model.run(coin: "BTC", interval: .minute, client: nil, scenario: .populated)
    }
    while model.buffer.coin != "BTC" { await Task.yield() }
    canceled.cancel()
    await canceled.value
    XCTAssertNil(model.lastUpdate)
    XCTAssertEqual(model.updateCount, 0)
  }
}
