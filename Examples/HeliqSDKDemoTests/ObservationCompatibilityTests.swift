//
//  ObservationCompatibilityTests.swift
//  HeliqSDKDemoTests
//
//  Created by Abdhilabs on 22/10/26.
//

import Combine
import HeliqSDK
import XCTest

@testable import HeliqSDKDemo

@MainActor
final class ObservationCompatibilityTests: XCTestCase {
  func testConnectionPublishesInitializationAndDisconnect() async throws {
    let manager = SDKManager.shared
    manager.disconnect()
    defer { manager.disconnect() }
    var addresses: [String?] = []
    let observation = manager.$walletAddress.sink { addresses.append($0) }
    defer { observation.cancel() }

    try await manager.initialize(with: .mainnet)
    XCTAssertTrue(manager.isInitialized)
    XCTAssertNotNil(manager.client)
    let initializedAddress = try XCTUnwrap(addresses.last ?? nil)
    XCTAssertEqual(initializedAddress, manager.walletAddress)

    manager.disconnect()
    XCTAssertFalse(manager.isInitialized)
    XCTAssertNil(manager.client)
    XCTAssertNil(addresses.last ?? nil)
  }

  func testChartPublishesFixtureUpdates() async {
    let model = CandleChartModel()
    var counts: [Int] = []
    let observation = model.$updateCount.sink { counts.append($0) }
    defer { observation.cancel() }

    await model.run(coin: "BTC", interval: .minute, client: nil, scenario: .populated)

    XCTAssertEqual(model.buffer.candles.count, 60)
    XCTAssertEqual(counts.last, 1)
    XCTAssertNotNil(model.lastUpdate)
    XCTAssertNil(model.error)
  }
}
