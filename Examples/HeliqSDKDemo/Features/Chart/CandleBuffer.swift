//
//  CandleBuffer.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 17/10/26.
//

import Foundation
import HeliqSDK

/// Keeps protocol decimals intact until the chart renders, with the newest live value winning.
struct CandleBuffer {
  private(set) var candles: [PerpsCandle] = []
  private(set) var isReady = false
  private var pending: [Int64: PerpsCandle] = [:]
  let coin: String
  let interval: PerpsCandleInterval

  /// Starts buffering during initial history or reconnect backfill without clearing the chart.
  mutating func beginHistory() {
    isReady = false
    pending = [:]
  }

  /// Merges a snapshot with updates received while it was in flight, retaining 500 bars.
  mutating func finishHistory(_ history: [PerpsCandle]) {
    merge(Array(history.sorted { $0.t < $1.t }.suffix(300)))
    merge(Array(pending.values))
    pending = [:]
    isReady = true
  }

  /// Buffers or merges matching live bars; ignores other markets and malformed OHLCV data.
  @discardableResult mutating func receive(_ values: [PerpsCandle]) -> Bool {
    let valid = values.filter(accepts)
    guard !valid.isEmpty else { return false }
    if isReady {
      merge(valid)
    } else {
      for candle in valid { pending[candle.t] = candle }
      if pending.count > 500 {
        let keep = Set(pending.keys.sorted().suffix(500))
        pending = pending.filter { keep.contains($0.key) }
      }
    }
    return true
  }

  /// Rejects data that cannot safely be rendered as a finite, ordered OHLCV bar.
  private func accepts(_ candle: PerpsCandle) -> Bool {
    candle.s == coin && candle.i == interval.rawValue && candle.t >= 0
      && candle.t % 1_000 == 0 && candle.T >= candle.t
      && [candle.o, candle.h, candle.l, candle.c, candle.v].allSatisfy {
        !$0.isNaN && NSDecimalNumber(decimal: $0).doubleValue.isFinite
      }
      && candle.l > 0 && candle.l <= min(candle.o, candle.c)
      && candle.h >= max(candle.o, candle.c) && candle.v >= 0
  }

  /// Replaces bars by opening timestamp and bounds retained history after every merge.
  private mutating func merge(_ values: [PerpsCandle]) {
    var indexed = Dictionary(uniqueKeysWithValues: candles.map { ($0.t, $0) })
    for candle in values where accepts(candle) { indexed[candle.t] = candle }
    candles = indexed.values.sorted { $0.t < $1.t }.suffix(500).map { $0 }
  }
}
