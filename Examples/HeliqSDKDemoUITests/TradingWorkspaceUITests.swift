//
//  TradingWorkspaceUITests.swift
//  HeliqSDKDemoUITests
//
//  Created by Abdhilabs on 15/10/26.
//

import XCTest

@MainActor
final class TradingWorkspaceUITests: XCTestCase {
  private var app: XCUIApplication!

  /// Stops at the first failed UI assertion so later taps cannot trigger unintended actions.
  override func setUp() async throws {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
    app = XCUIApplication()
  }

  /// Launches an explicitly synthetic scenario; these flows never contact exchange endpoints.
  private func launch(_ scenario: String? = nil) {
    app.launchArguments = ["-ui-testing"]
    if let scenario { app.launchArguments += ["-demo-scenario", scenario] }
    app.launch()
  }

  /// Reaches an offscreen control without assuming a particular display size or text scale.
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

  /// Enters a sample form value and dismisses its keyboard using the shared toolbar.
  private func fill(_ identifier: String, _ value: String) {
    let field = app.textFields[identifier]
    reach(field)
    field.tap()
    field.typeText(value)
    if app.keyboards.firstMatch.exists { app.buttons["dismiss_keyboard"].tap() }
  }

  /// Captures the actual rendered screen for visual review.
  private func capture(_ name: String) {
    let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
    attachment.name = name
    attachment.lifetime = .keepAlways
    add(attachment)
  }

  /// Checks the four-tab shell and its safe disconnected entry paths.
  func testDisconnectedNavigation() {
    launch()
    for tab in ["Overview", "Perpetuals", "API Explorer", "Settings"] {
      XCTAssertTrue(app.tabBars.buttons[tab].exists)
    }
    XCTAssertTrue(app.navigationBars["Overview"].exists)
    app.tabBars.buttons["Perpetuals"].tap()
    XCTAssertTrue(app.buttons["connect_from_perps"].exists)
    app.buttons["connect_from_perps"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].exists)
    app.tabBars.buttons["API Explorer"].tap()
    XCTAssertFalse(app.buttons["nav_trading"].isEnabled)
    capture("disconnected-explorer")
  }

  /// Verifies shared collateral and missing withdrawal values remain distinct.
  func testPopulatedOverview() {
    launch("populated")
    XCTAssertTrue(app.staticTexts["balance_mode"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["balance_mode"].label, "Shared Spot / Perps collateral")
    let held = app.descendants(matching: .any)["amount_Held"]
    reach(held)
    XCTAssertTrue(held.exists)
    let withdrawal = app.descendants(matching: .any)["amount_Withdrawable"]
    reach(withdrawal)
    XCTAssertEqual(withdrawal.value as? String, "Unavailable")
    capture("overview-balances")
  }

  /// Verifies zero holdings display an informative empty state.
  func testEmptyStates() {
    launch("empty")
    reach(app.staticTexts["No Spot balances"])
    XCTAssertTrue(app.staticTexts["No Spot balances"].exists)
    app.tabBars.buttons["Perpetuals"].tap()
    app.buttons["Positions"].tap()
    XCTAssertTrue(app.staticTexts["No open positions"].waitForExistence(timeout: 5))
    app.buttons["Open Orders"].tap()
    XCTAssertTrue(app.staticTexts["No open orders"].exists)
    capture("empty-orders")
  }

  /// Verifies absent server availability is not rendered as zero.
  func testMissingAvailability() {
    launch("missing")
    XCTAssertTrue(app.staticTexts["balance_mode"].waitForExistence(timeout: 5))
    let available = app.descendants(matching: .any)["amount_Available after maintenance"]
    reach(available)
    XCTAssertEqual(available.value as? String, "Unavailable")
    capture("missing-availability")
  }

  /// Verifies loading and failures have explicit visible states.
  func testLoadingAndError() {
    launch("loading")
    XCTAssertTrue(app.descendants(matching: .any)["balances_loading"].waitForExistence(timeout: 5))
    capture("loading")
    app.terminate()
    launch("error")
    XCTAssertTrue(app.staticTexts["balance_error"].waitForExistence(timeout: 5))
    app.tabBars.buttons["Perpetuals"].tap()
    XCTAssertTrue(app.staticTexts["perps_read_error"].waitForExistence(timeout: 5))
    capture("read-error")
  }

  /// Checks row-specific actions and visible partial results without exchange mutations.
  func testPositionOrderActionsAndPartialFailure() {
    launch("partial")
    app.tabBars.buttons["Perpetuals"].tap()
    app.buttons["Positions"].tap()
    let close = app.buttons["close_position_BTC"]
    reach(close)
    XCTAssertTrue(close.exists)
    XCTAssertTrue(app.buttons["protect_position_BTC"].exists)
    close.tap()
    reach(app.staticTexts["perps_result"])
    XCTAssertTrue(app.staticTexts["perps_result"].label.contains("1 accepted; 1 rejected"))
    for _ in 0..<5 { app.swipeDown() }
    app.buttons["Open Orders"].tap()
    reach(app.buttons["cancel_order_42"])
    XCTAssertTrue(app.buttons["cancel_order_42"].exists)
    app.buttons["cancel_order_42"].tap()
    reach(app.staticTexts["perps_result"])
    XCTAssertTrue(app.staticTexts["perps_result"].label.contains("sample precision error"))
    capture("partial-order-result")
  }

  /// Exercises size validation and the searchable metadata picker.
  func testTicketValidationAndMarketSearch() {
    launch("populated")
    app.tabBars.buttons["Perpetuals"].tap()
    XCTAssertTrue(app.buttons["perps_coin"].waitForExistence(timeout: 5))
    fill("perps_size", "0.000001")
    reach(app.buttons["submit_perps_order"])
    XCTAssertFalse(app.buttons["submit_perps_order"].isEnabled)
    XCTAssertTrue(app.staticTexts["perps_validation"].label.contains("5 decimal"))
    reach(app.buttons["perps_coin"], scrollingDown: false)
    app.buttons["perps_coin"].tap()
    let search = app.searchFields.firstMatch
    XCTAssertTrue(search.waitForExistence(timeout: 5))
    search.tap()
    search.typeText("ETH")
    let market = app.buttons["market_ETH"]
    XCTAssertTrue(market.waitForExistence(timeout: 5))
    market.tap()
    XCTAssertTrue(app.buttons["perps_coin"].label.contains("ETH"))
    capture("selected-market")
  }

  /// Checks transfer eligibility in shared and standard account modes.
  func testTransferCompatibility() {
    launch("populated")
    app.tabBars.buttons["Perpetuals"].tap()
    let transfer = app.buttons["open_perps_transfer"]
    reach(transfer)
    transfer.tap()
    fill("perps_transfer_amount", "1")
    XCTAssertFalse(app.buttons["perps_class_transfer"].isEnabled)
    capture("shared-transfer")
    app.terminate()
    launch("standard")
    app.tabBars.buttons["Perpetuals"].tap()
    reach(app.buttons["open_perps_transfer"])
    app.buttons["open_perps_transfer"].tap()
    fill("perps_transfer_amount", "1")
    XCTAssertTrue(app.buttons["perps_class_transfer"].isEnabled)
    capture("standard-transfer")
  }

  /// Checks advanced order fields are scoped to the chosen action.
  func testAdvancedOrderFields() {
    launch("populated")
    app.tabBars.buttons["Perpetuals"].tap()
    let advanced = app.buttons["TP/SL, TWAP & trailing stop"]
    reach(advanced)
    advanced.tap()
    reach(app.textFields["perps_trigger"])
    XCTAssertTrue(app.textFields["perps_trigger"].exists)
    app.buttons["advanced_order_type"].tap()
    app.buttons["TWAP"].tap()
    reach(app.textFields["perps_minutes"])
    XCTAssertTrue(app.textFields["perps_minutes"].exists)
    XCTAssertFalse(app.textFields["perps_trigger"].exists)
    app.buttons["advanced_order_type"].tap()
    app.buttons["Trailing stop"].tap()
    reach(app.textFields["perps_retracement"])
    XCTAssertTrue(app.textFields["perps_retracement"].exists)
    capture("advanced-order")
  }

  /// Checks the workspace remains navigable in portrait and landscape at the current text size.
  func testAdaptiveLayout() {
    launch("populated")
    app.tabBars.buttons["Perpetuals"].tap()
    XCTAssertTrue(app.buttons["perps_coin"].waitForExistence(timeout: 5))
    capture("adaptive-portrait")
    reach(app.textFields["perps_size"])
    capture("adaptive-order-ticket")
    XCUIDevice.shared.orientation = .landscapeLeft
    defer { XCUIDevice.shared.orientation = .portrait }
    XCTAssertEqual(
      XCTWaiter.wait(
        for: [
          XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in self.app.frame.width > self.app.frame.height },
            object: nil)
        ], timeout: 5), .completed)
    app.tabBars.buttons["Overview"].tap()
    app.tabBars.buttons["Perpetuals"].tap()
    capture("adaptive-landscape")
  }

  /// Uses the saved testnet wallet for read-only market and balance verification.
  func testLiveTestnetReadOnlyWorkspace() throws {
    guard ProcessInfo.processInfo.environment["HELIQ_DEMO_READ_TESTS"] == "1" else {
      throw XCTSkip("Read-only testnet UI checks are opt-in")
    }
    launch()
    app.tabBars.buttons["Settings"].tap()
    app.buttons["environment_testnet"].tap()
    reach(app.buttons["initialize_sdk"])
    app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 10))
    app.alerts.buttons["OK"].tap()
    app.tabBars.buttons["Overview"].tap()
    XCTAssertTrue(app.staticTexts["balance_mode"].waitForExistence(timeout: 20))
    capture("live-testnet-overview")
    app.tabBars.buttons["Perpetuals"].tap()
    XCTAssertTrue(
      app.descendants(matching: .any)["amount_Mark price"].waitForExistence(timeout: 20))
    let market = app.buttons["perps_coin"]
    XCTAssertEqual(
      XCTWaiter.wait(
        for: [
          XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS 'BTC'"), object: market)
        ], timeout: 20), .completed)
    let mark = app.descendants(matching: .any)["amount_Mark price"]
    XCTAssertEqual(
      XCTWaiter.wait(
        for: [
          XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value != 'Unavailable'"), object: mark)
        ], timeout: 20), .completed)
    XCTAssertFalse(app.staticTexts["perps_error"].exists)
    XCTAssertFalse(app.staticTexts["perps_read_error"].exists)
    app.buttons["Positions"].tap()
    capture("live-testnet-positions")
    app.buttons["Open Orders"].tap()
    capture("live-testnet-orders")
  }
}
