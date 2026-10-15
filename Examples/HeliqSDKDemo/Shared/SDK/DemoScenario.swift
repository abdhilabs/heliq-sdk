//
//  DemoScenario.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import HeliqSDK

/// Synthetic UI states, enabled only by explicit UI-test launch arguments. No exchange is contacted.
enum DemoScenario: String {
  case populated, empty, missing, standard, loading, error, partial

  static var current: Self? {
    let args = ProcessInfo.processInfo.arguments
    guard args.contains("-ui-testing"), let index = args.firstIndex(of: "-demo-scenario"),
      args.indices.contains(index + 1)
    else { return nil }
    return Self(rawValue: args[index + 1])
  }
  static let address = "0x1234567890123456789012345678901234567890"

  /// Decodes synthetic endpoint responses through the same typed query decoder as network data.
  func response<T>(_ query: PerpsQuery<T>) throws -> T {
    if self == .error {
      throw ValidationError.malformedData(
        reason: "Sample read failed. Pull to refresh to try again.")
    }
    let payload: String
    switch query.request.type.rawValue {
    case "metaAndAssetCtxs":
      payload = """
        [{"universe":[{"name":"BTC","szDecimals":5,"maxLeverage":50},{"name":"ETH","szDecimals":4,"maxLeverage":20}],"collateralToken":0},[{"dayNtlVlm":"100","funding":"0.0001","markPx":"50000","openInterest":"1","oraclePx":"50000","prevDayPx":"49000"},{"dayNtlVlm":"100","funding":"0.0002","markPx":"3000","openInterest":"1","oraclePx":"3000","prevDayPx":"2900"}]]
        """
    case "activeAssetData":
      payload = """
        {"user":"\(Self.address)","coin":"BTC","leverage":{"type":"isolated","value":2},"maxTradeSzs":["1","2"],"availableToTrade":["90","80"],"markPx":"50000"}
        """
    case "openOrders":
      payload =
        self == .empty
        ? "[]"
        : """
        [{"coin":"BTC","side":"B","limitPx":"49000","sz":"0.001","oid":42,"timestamp":1700000000123}]
        """
    default: throw ValidationError.malformedData(reason: "Unsupported synthetic endpoint")
    }
    return try query.decode(Data(payload.utf8))
  }

  /// Builds distinct synthetic ledgers without estimating absent server availability.
  func balances() throws -> AccountBalances {
    if self == .error {
      throw ValidationError.malformedData(
        reason: "Sample read failed. Pull to refresh to try again.")
    }
    let position = try JSONDecoder().decode(
      PerpsPositionEntry.self,
      from: Data(
        """
        {"type":"oneWay","position":{"coin":"BTC","szi":"0.001","entryPx":"50000","unrealizedPnl":"-2","marginUsed":"15","leverage":{"type":"isolated","value":2},"liquidationPx":null}}
        """.utf8))
    return AccountBalances(
      address: Self.address, abstraction: self == .standard ? .disabled : .unifiedAccount,
      spot: self == .empty
        ? []
        : [
          .init(
            coin: "USDC", token: 0, total: 100, held: 10,
            availableAfterMaintenance: self == .missing ? nil : 80)
        ],
      perps: [
        .init(
          dex: "", collateralToken: 0, accountValue: self == .standard ? 50 : nil,
          marginUsed: self == .standard ? 15 : nil, withdrawable: self == .standard ? 35 : nil,
          positions: self == .empty ? [] : [position])
      ])
  }
}
