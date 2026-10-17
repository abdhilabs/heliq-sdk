//
//  CandleChartUITests.swift
//  HeliqSDKDemoUITests
//
//  Created by Abdhilabs on 17/10/26.
//

import XCTest

@MainActor final class CandleChartUITests: XCTestCase {
  private var app: XCUIApplication!

  /// Prevents follow-on taps after failure; no chart test submits an exchange action.
  override func setUp() async throws {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
    app = XCUIApplication()
  }

  /// Starts a deterministic chart fixture without needing a wallet or network.
  private func launch(_ scenario: String) {
    app.launchArguments = ["-ui-testing", "-demo-scenario", scenario]
    app.launch()
    app.tabBars.buttons["Perpetuals"].tap()
  }

  /// Scrolls a small distance while preserving the interactive chart's own pan gestures.
  private func reach(_ element: XCUIElement, scrollingDown: Bool = true) {
    var downward = scrollingDown
    var previousFrame: CGRect?
    for _ in 0..<25 {
      let top = app.navigationBars.firstMatch.frame.maxY
      let bottom = app.tabBars.firstMatch.exists
        ? app.tabBars.firstMatch.frame.minY : app.frame.maxY
      if element.exists && element.isHittable
        && element.frame.minY >= top && element.frame.maxY <= bottom { return }
      let first = app.collectionViews.firstMatch.cells.firstMatch
      let firstFrame = first.exists ? first.frame : .zero
      if element.exists {
        downward = element.frame.minY >= top
      } else if previousFrame == firstFrame {
        downward.toggle()
      }
      previousFrame = firstFrame
      let gutter = app.frame.width > app.frame.height ? 0.94 : 0.98
      let start = app.coordinate(withNormalizedOffset:
        CGVector(dx: gutter, dy: downward ? 0.8 : 0.4))
      let end = app.coordinate(withNormalizedOffset: CGVector(dx: gutter, dy: 0.6))
      start.press(forDuration: 0.05, thenDragTo: end)
    }
    XCTAssertTrue(element.isHittable, app.debugDescription)
  }

  /// Frames the canvas itself so screenshots verify the chart rather than only its footer.
  private func revealChart() {
    reach(
      app.descendants(matching: .any)["candle_chart"].firstMatch,
      scrollingDown: false)
  }

  /// Stores the actual rendered chart for appearance and compact-layout review.
  private func capture(_ name: String) {
    let image = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    image.name = name
    image.lifetime = .keepAlways
    add(image)
  }

  /// Verifies the bundled web renderer, candle data, interval changes, and market replacement.
  func testChartRenderingAndSelection() {
    launch("populated")
    reach(app.staticTexts["chart_ready"])
    XCTAssertTrue(app.staticTexts["chart_ready"].waitForExistence(timeout: 20))
    XCTAssertTrue(app.staticTexts["chart_ohlcv"].exists)
    XCTAssertEqual(app.staticTexts["chart_bar_count"].label, "60 bars")
    XCTAssertFalse(app.staticTexts["chart_error"].exists)
    revealChart()
    capture("chart-rendered")
    reach(app.segmentedControls["chart_interval"])
    app.segmentedControls["chart_interval"].buttons["1h"].tap()
    XCTAssertTrue(app.staticTexts["chart_status"].label.contains("1h"))
    app.segmentedControls["chart_interval"].buttons["1d"].tap()
    app.segmentedControls["chart_interval"].buttons["1m"].tap()
    XCTAssertTrue(app.staticTexts["chart_status"].label.contains("1m"))
    reach(app.buttons["perps_coin"], scrollingDown: false)
    app.buttons["perps_coin"].tap()
    XCTAssertTrue(app.buttons["market_ETH"].waitForExistence(timeout: 10))
    app.buttons["market_ETH"].tap()
    reach(app.staticTexts["chart_status"])
    XCTAssertTrue(app.staticTexts["chart_status"].label.contains("ETH"))
    app.tabBars.buttons["Overview"].tap()
    app.tabBars.buttons["Perpetuals"].tap()
    reach(app.staticTexts["chart_ready"])
    XCTAssertTrue(app.staticTexts["chart_ready"].waitForExistence(timeout: 20))
  }

  /// Empty history, pending history, and failed reads have distinct nearby feedback.
  func testEmptyAndErrorStates() {
    launch("empty")
    reach(app.staticTexts["chart_empty"])
    XCTAssertTrue(app.staticTexts["chart_empty"].exists)
    launch("error")
    openExample()
    reach(app.staticTexts["chart_error"])
    XCTAssertTrue(app.staticTexts["chart_error"].exists)
    capture("chart-error")
    reach(app.buttons["chart_reload"])
    app.buttons["chart_reload"].tap()
    XCTAssertTrue(app.staticTexts["chart_error"].waitForExistence(timeout: 5))
    launch("loading")
    openExample()
    reach(app.staticTexts["chart_status"])
    XCTAssertTrue(app.staticTexts["chart_status"].label.contains("loading"))
  }

  /// Checks the WebSocket example entry and back navigation with the shared renderer.
  func testWebSocketChartEntry() {
    launch("populated")
    initialize(testnet: false)
    app.tabBars.buttons["API Explorer"].tap()
    app.buttons["nav_websocket"].tap()
    app.buttons["open_live_chart"].tap()
    reach(app.staticTexts["chart_ready"])
    XCTAssertTrue(app.staticTexts["chart_ready"].waitForExistence(timeout: 20))
    capture("websocket-chart")
    app.navigationBars.buttons.element(boundBy: 0).tap()
    XCTAssertTrue(app.buttons["open_live_chart"].waitForExistence(timeout: 5))
  }

  /// Exercises dark appearance, accessibility text, and landscape using deterministic candles.
  func testAdaptiveChart() {
    app.launchArguments = ["-ui-testing", "-demo-scenario", "populated",
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL"]
    app.launch()
    app.tabBars.buttons["Perpetuals"].tap()
    reach(app.staticTexts["chart_ready"])
    XCTAssertTrue(app.staticTexts["chart_ready"].waitForExistence(timeout: 20))
    revealChart()
    capture("chart-large-text")
    XCUIDevice.shared.orientation = .landscapeLeft
    app.tabBars.buttons["Overview"].tap()
    app.tabBars.buttons["Perpetuals"].tap()
    reach(app.staticTexts["chart_ready"])
    revealChart()
    capture("chart-landscape")
    XCUIDevice.shared.orientation = .portrait
  }

  /// Verifies an actual testnet HTTP snapshot followed by a public candle WebSocket event.
  func testLiveTestnetCandles() throws {
    guard ProcessInfo.processInfo.environment["HELIQ_DEMO_READ_TESTS"] == "1" else {
      throw XCTSkip("Read-only network chart verification is opt-in")
    }
    app.launchArguments = ["-ui-testing"]
    app.launch()
    initialize(testnet: true)
    app.tabBars.buttons["API Explorer"].tap()
    app.buttons["nav_websocket"].tap()
    app.buttons["open_live_chart"].tap()
    waitForLiveChart()
    capture("chart-live-testnet")
    app.navigationBars.buttons.element(boundBy: 0).tap()
    XCTAssertTrue(app.buttons["open_live_chart"].exists)
  }

  /// Verifies public mainnet candles in both chart entry points without submitting an action.
  func testLiveMainnetCandles() throws {
    guard ProcessInfo.processInfo.environment["HELIQ_DEMO_READ_TESTS"] == "1" else {
      throw XCTSkip("Read-only network chart verification is opt-in")
    }
    app.launchArguments = ["-ui-testing"]
    app.launch()
    initialize(testnet: false)
    app.tabBars.buttons["API Explorer"].tap()
    app.buttons["nav_websocket"].tap()
    app.buttons["open_live_chart"].tap()
    waitForLiveChart()
    let count = Int(app.staticTexts["chart_bar_count"].label.split(separator: " ").first ?? "")
    XCTAssertGreaterThanOrEqual(try XCTUnwrap(count), 250)
    capture("chart-live-mainnet")
    reach(app.segmentedControls["chart_interval"], scrollingDown: false)
    app.segmentedControls["chart_interval"].buttons["15m"].tap()
    waitForLiveChart()
    XCTAssertTrue(app.staticTexts["chart_status"].label.contains("15m"))
    capture("chart-live-mainnet-15m")
    app.navigationBars.buttons.element(boundBy: 0).tap()
    XCTAssertTrue(app.buttons["open_live_chart"].exists)
    app.tabBars.buttons["Perpetuals"].tap()
    waitForLiveChart()
    capture("perpetuals-live-mainnet")
  }

  /// Requires renderer readiness, historical data, and a decoded real-time candle update.
  private func waitForLiveChart() {
    reach(app.staticTexts["chart_ready"])
    XCTAssertTrue(app.staticTexts["chart_ready"].waitForExistence(timeout: 20))
    let status = app.staticTexts["chart_status"]
    XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS '· Live'"), object: status)], timeout: 60), .completed)
    XCTAssertFalse(app.staticTexts["chart_error"].exists)
    XCTAssertTrue(app.staticTexts["chart_ohlcv"].exists)
    XCTAssertNotEqual(app.staticTexts["chart_bar_count"].label, "0 bars")
  }

  /// Reaches the standalone chart even when the fixture intentionally fails market metadata reads.
  private func openExample() {
    initialize(testnet: false)
    app.tabBars.buttons["API Explorer"].tap()
    app.buttons["nav_websocket"].tap()
    app.buttons["open_live_chart"].tap()
  }

  /// Initializes the existing demo connection; this helper never signs or submits an action.
  private func initialize(testnet: Bool) {
    app.tabBars.buttons["Settings"].tap()
    app.buttons[testnet ? "environment_testnet" : "environment_mainnet"].tap()
    reach(app.buttons["initialize_sdk"])
    app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 10))
    app.alerts.buttons["OK"].tap()
  }
}
