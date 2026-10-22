//
//  HeliqSDKDemoUITests.swift
//  HeliqSDKDemoUITests
//
//  Created by Abdhilabs on 05/04/26.
//

import XCTest

@MainActor
final class HeliqSDKDemoUITests: XCTestCase {
  var app: XCUIApplication!

  override func setUpWithError() throws {
    continueAfterFailure = false
    XCUIDevice.shared.orientation = .portrait
    app = XCUIApplication()
    app.launchArguments += ["-ui-testing", "-fresh-testnet-wallet"]
    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  func testTestnetWalletPersistsAcrossDisconnectAndRelaunch() throws {
    app.terminate()
    app.launchArguments = ["-ui-testing"]
    app.launch()
    func initializeTestnet() {
      openSettings()
      app.buttons["environment_testnet"].tap()
      reachTradingControl(app.buttons["initialize_sdk"])
      app.buttons["initialize_sdk"].tap()
      let initialized = app.alerts["SDK Initialized"].waitForExistence(timeout: 10)
      if !initialized {
        let error = app.staticTexts["settings_error"]
        reachTradingControl(error)
        XCTFail(error.label)
      }
      app.alerts.buttons["OK"].tap()
      goBack()
      openExample("Wallet")
    }
    initializeTestnet()
    let address = app.staticTexts["connected_wallet_address"]
    XCTAssertTrue(address.waitForExistence(timeout: 5))
    let first = address.label
    XCTAssertEqual(first.count, 42)
    if let expected = ProcessInfo.processInfo.environment["HELIQ_EXPECTED_TESTNET_ADDRESS"] {
      XCTAssertEqual(first.lowercased(), expected.lowercased())
    }
    goBack()
    openSettings()
    reachTradingControl(app.buttons["Disconnect SDK"])
    app.buttons["Disconnect SDK"].tap()
    goBack()
    initializeTestnet()
    XCTAssertEqual(app.staticTexts["connected_wallet_address"].label, first)
    app.terminate()
    app.launch()
    initializeTestnet()
    XCTAssertEqual(app.staticTexts["connected_wallet_address"].label, first)
  }

  func testFundedTradingPlaceModifyCancel() throws {
    guard ProcessInfo.processInfo.environment["HELIQ_FUNDED_UI_TESTS"] == "1" else {
      throw XCTSkip("Funded testnet UI run is opt-in")
    }
    app.terminate()
    app.launchArguments = ["-ui-testing"]
    app.launch()
    openSettings()
    app.buttons["environment_testnet"].tap()
    reachTradingControl(app.buttons["initialize_sdk"])
    app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    goBack()
    openExample("Wallet")
    XCTAssertEqual(app.staticTexts["connected_wallet_address"].label, "0x444483eba5faa8a1499a4d2261c5e4e927b558cf")
    goBack()
    openExample("Trading")
    func fill(_ identifier: String, _ value: String) {
      let input = app.textFields[identifier]
      reachTradingControl(input)
      input.tap()
      let current = input.value as? String ?? ""
      if !current.isEmpty, current != input.placeholderValue {
        input.doubleTap()
        let selectAll = app.menuItems["Select All"]
        if selectAll.exists { selectAll.tap() }
        else if app.buttons["Select All"].exists { app.buttons["Select All"].tap() }
      }
      input.typeText(value)
      XCTAssertEqual(input.value as? String, value)
      app.buttons["Done"].tap()
      XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
    }
    func result(prefix: String) -> String {
      let output = app.staticTexts["trade_result"]
      for _ in 0..<30 {
        if app.staticTexts["trade_error"].exists { XCTFail(app.staticTexts["trade_error"].label) }
        if output.exists && output.isHittable { break }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8))
          .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.55)))
      }
      let predicate = NSPredicate(format: "label BEGINSWITH %@", prefix)
      XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: output)], timeout: 15), .completed)
      XCTAssertFalse(app.staticTexts["trade_error"].exists)
      return output.label
    }
    // Testnet BTC is asset 3; asset 0 is SOL and only permits two size decimals.
    fill("trade_PlaceOrderForm_asset", "3")
    fill("trade_PlaceOrderForm_size", "0.0003")
    fill("trade_PlaceOrderForm_price", "50000")
    app.buttons["Place Order"].tap()
    let placed = result(prefix: "Order placed: resting")
    let oid = try XCTUnwrap(placed.components(separatedBy: "ID: ").last)
    XCTAssertTrue(oid.allSatisfy(\.isNumber))
    for _ in 0..<10 { app.swipeDown() }
    fill("trade_ModifyOrderForm_orderId", oid)
    fill("trade_ModifyOrderForm_asset", "3")
    fill("trade_ModifyOrderForm_price", "49000")
    reachTradingControl(app.buttons["Modify Order"])
    app.buttons["Modify Order"].tap()
    _ = result(prefix: "Modify: resting")
    for _ in 0..<10 { app.swipeDown() }
    reachTradingControl(app.buttons["Cancel All Orders"])
    app.buttons["Cancel All Orders"].tap()
    _ = result(prefix: "Cancelled: 1 orders")
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  func testTypedPerpsBalancesAndTrading() throws {
    try launchPerpsWallet(expected: "0x444483eba5faa8a1499a4d2261c5e4e927b558cf")
    app.buttons["Available balances"].tap()
    XCTAssertTrue(app.staticTexts["balance_mode"].waitForExistence(timeout: 15))
    XCTAssertEqual(app.staticTexts["balance_mode"].label, "Shared Spot / Perps collateral")
    XCTAssertFalse(app.staticTexts["balance_error"].exists)
    goBack()
    app.buttons["open_perps_transfer"].tap()
    fillPerps("perps_transfer_amount", "1")
    XCTAssertFalse(app.buttons["perps_class_transfer"].isEnabled)
    app.buttons["Done"].tap()
    for _ in 0..<10 { app.swipeDown() }
    fillPerps("perps_size", "0.0003")
    fillPerps("perps_price", "50000")
    reachTradingControl(app.buttons["submit_perps_order"])
    app.buttons["submit_perps_order"].tap()
    _ = perpsResult("Order placed: resting")
    for _ in 0..<10 { app.swipeDown() }
    app.buttons["Open Orders"].tap()
    reachTradingControl(app.buttons["perps_cancel_open"])
    XCTAssertTrue(app.buttons["perps_cancel_open"].waitForExistence(timeout: 5))
    app.buttons["perps_cancel_open"].tap()
    _ = perpsResult("Cancellation accepted")
  }

  func testTypedStandardClassTransferRoundTrip() throws {
    guard ProcessInfo.processInfo.environment["HELIQ_PERPS_STANDARD_UI_TESTS"] == "1" else {
      throw XCTSkip("Standard-wallet simulator transfer test is opt-in")
    }
    try launchPerpsWallet(expected: "0x309ef1a1b1c9c0b2321213c1ffd2f74f8bdb8c93")
    app.buttons["Available balances"].tap()
    XCTAssertTrue(app.staticTexts["balance_mode"].waitForExistence(timeout: 15))
    XCTAssertEqual(app.staticTexts["balance_mode"].label, "Separate Spot and Perps balances")
    goBack()
    app.buttons["open_perps_transfer"].tap()
    fillPerps("perps_transfer_amount", "0.5")
    XCTAssertTrue(app.buttons["perps_class_transfer"].isEnabled)
    app.buttons["perps_class_transfer"].tap()
    _ = perpsResult("Action succeeded")
    app.navigationBars.buttons["Done"].tap()
    for _ in 0..<10 { app.swipeDown() }
    app.buttons["Available balances"].tap()
    XCTAssertTrue(app.descendants(matching: .any)["amount_Total"].waitForExistence(timeout: 15))
    XCTAssertEqual(app.descendants(matching: .any)["amount_Total"].value as? String, "0.5")
    reachTradingControl(app.descendants(matching: .any)["amount_Account value"])
    XCTAssertEqual(app.descendants(matching: .any)["amount_Account value"].value as? String, "0.5")
    goBack()
    reachTradingControl(app.buttons["Perps → Spot"])
    app.buttons["Perps → Spot"].tap()
    XCTAssertTrue(app.buttons["Perps → Spot"].isSelected)
    reachTradingControl(app.buttons["perps_class_transfer"])
    app.buttons["perps_class_transfer"].tap()
    _ = perpsResult("Action succeeded")
    app.navigationBars.buttons["Done"].tap()
    for _ in 0..<10 { app.swipeDown() }
    app.buttons["Available balances"].tap()
    XCTAssertTrue(app.staticTexts["Total: 1"].waitForExistence(timeout: 15))
    reachTradingControl(app.staticTexts["Account value: 0"])
    XCTAssertTrue(app.staticTexts["Account value: 0"].exists)
  }

  private func launchPerpsWallet(expected: String) throws {
    guard ProcessInfo.processInfo.environment["HELIQ_PERPS_UI_TESTS"] == "1" else {
      throw XCTSkip("Funded typed Perps simulator checks are opt-in")
    }
    app.terminate(); app.launchArguments = ["-ui-testing"]; app.launch()
    openSettings(); app.buttons["environment_testnet"].tap()
    reachTradingControl(app.buttons["initialize_sdk"]); app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap(); goBack()
    openExample("Wallet")
    XCTAssertEqual(app.staticTexts["connected_wallet_address"].label, expected)
    goBack()
    app.tabBars.buttons["Perpetuals"].tap()
    let coin = app.buttons["perps_coin"]
    XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label CONTAINS 'BTC'"), object: coin)], timeout: 15), .completed)
  }

  /// Enters a Perps value without confusing the keyboard toolbar with a sheet's Done button.
  private func fillPerps(_ identifier: String, _ value: String) {
    let field = app.textFields[identifier]
    reachTradingControl(field); field.tap(); field.typeText(value)
    XCTAssertEqual(field.value as? String, value)
    if app.keyboards.firstMatch.exists { app.buttons["dismiss_keyboard"].tap() }
    XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
  }

  private func perpsResult(_ prefix: String) -> String {
    let output = app.staticTexts["perps_result"]
    reachTradingControl(output)
    XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
      predicate: NSPredicate(format: "label BEGINSWITH %@", prefix), object: output)], timeout: 15), .completed)
    XCTAssertFalse(app.staticTexts["perps_error"].exists)
    return output.label
  }

  // MARK: - Home

  func testHome_showsNavigationTitle() {
    XCTAssertTrue(app.navigationBars["Overview"].waitForExistence(timeout: 5))
  }

  func testHome_listsAllFeatureEntries() {
    for tab in ["Overview", "Perpetuals", "API Explorer", "Settings"] {
      XCTAssertTrue(app.tabBars.buttons[tab].exists)
    }
    app.tabBars.buttons["Perpetuals"].tap()
    XCTAssertTrue(app.buttons["connect_from_perps"].exists)
    app.buttons["connect_from_perps"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].exists)
  }

  // MARK: - Settings

  func testSettings_canOpenAndShowEnvironments() {
    openSettings()
    XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["Mainnet"].exists || app.buttons["Mainnet"].exists)
    XCTAssertTrue(app.staticTexts["Testnet"].exists || app.buttons["Testnet"].exists)
  }

  // MARK: - Info

  func testInfo_opensMarketDataSection() {
    openExample("Info")
    XCTAssertTrue(app.navigationBars["Info API"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons["Load All Mids"].waitForExistence(timeout: 3) ||
                  app.staticTexts["All Mids"].waitForExistence(timeout: 3))
  }

  func testInfo_loadAllMidsShowsResultOrError() {
    openSettings()
    app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    goBack()
    openExample("Info")
    XCTAssertTrue(app.navigationBars["Info API"].waitForExistence(timeout: 3))

    app.buttons["Load All Mids"].tap()

    let result = app.staticTexts["Tap to load"].waitForNonExistence(timeout: 15)
    let error = app.staticTexts["Error"].waitForExistence(timeout: 15)
    XCTAssertTrue(result || error, "Info request must show data or a visible error")
  }

  func testInfo_loadCandlesShowsChartWithoutError() {
    openSettings()
    app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    goBack()
    openExample("Info")

    let load = app.buttons["Load Candles"]
    for _ in 0..<8 {
      if load.exists && load.isHittable { break }
      app.swipeUp()
    }
    XCTAssertTrue(load.isHittable)
    app.buttons["15m"].tap()
    load.tap()

    let chart = app.staticTexts["Candlestick - BTC"]
    XCTAssertTrue(chart.waitForExistence(timeout: 20), app.debugDescription)
    app.swipeUp()
    let latest = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Latest: '")).firstMatch
    XCTAssertTrue(latest.isHittable)
    XCTAssertFalse(app.staticTexts["Error"].exists)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  func testInfo_userDataQueriesReturnResultsWithoutErrors() {
    openSettings()
    app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    goBack()
    openExample("Info")
    app.buttons["User Data"].tap()
    app.buttons["Use Demo Wallet"].tap()

    for (button, result) in [
      ("Load User State", "user_state_result"),
      ("Load Spot User State", "spot_user_state_result"),
      ("Load Fills", "fills_result"),
      ("Load Fundings", "fundings_result")
    ] {
      let load = app.buttons[button]
      for _ in 0..<24 {
        if load.exists && load.isHittable { break }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8))
          .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.55)))
      }
      XCTAssertTrue(load.isHittable, button + app.debugDescription)
      load.tap()
      let details = app.buttons.containing(.staticText, identifier: result + "_details").firstMatch
      if details.waitForExistence(timeout: 20) { details.tap() }
      XCTAssertTrue(app.staticTexts[result].waitForExistence(timeout: 20), button + app.debugDescription)
      XCTAssertFalse(app.staticTexts["info_error"].exists, button)
    }

    for (field, value, button) in [
      ("Order ID", "1", "Query by OID"),
      ("CLOB ID (cloid)", "0x00000000000000000000000000000001", "Query by CLOB ID")
    ] {
      let input = app.textFields[field]
      for _ in 0..<24 {
        if input.exists && input.isHittable { break }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8))
          .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.55)))
      }
      input.tap()
      input.typeText(value)
      XCTAssertEqual(input.value as? String, value, app.debugDescription)
      input.typeText("\n")
      XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
      let query = app.buttons[button]
      for _ in 0..<6 {
        if query.isHittable { break }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8))
          .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.55)))
      }
      query.tap()
      if !app.staticTexts["orders_result"].exists {
        let details = app.buttons.containing(.staticText, identifier: "orders_result_details").firstMatch
        XCTAssertTrue(details.waitForExistence(timeout: 20)); details.tap()
      }
      XCTAssertTrue(app.staticTexts["orders_result"].waitForExistence(timeout: 20), app.debugDescription)
      XCTAssertEqual(app.staticTexts["orders_result"].label.filter { !$0.isWhitespace }, "[]")
      XCTAssertFalse(app.staticTexts["info_error"].exists, button)
    }
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  func testInfo_metadataAndBuilderFeeUseTypedSDKWithoutErrors() {
    openSettings()
    let initialize = app.buttons["initialize_sdk"]
    reachTradingControl(initialize)
    initialize.tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    goBack()
    openExample("Info")
    app.buttons["Metadata"].tap()

    for (button, result) in [("Load Meta", "perpetual_meta_result"), ("Load Spot Meta", "spot_meta_result")] {
      let load = app.buttons[button]
      for _ in 0..<24 {
        if load.exists && load.isHittable { break }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8))
          .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.55)))
      }
      load.tap()
      XCTAssertTrue(app.staticTexts[result].waitForExistence(timeout: 20), app.debugDescription)
      XCTAssertFalse(app.staticTexts[result].label.hasPrefix("Loaded 0 "))
      XCTAssertFalse(app.staticTexts["info_error"].exists)
    }

    let builder = app.textFields["Builder Address"]
    for _ in 0..<24 {
      if builder.exists && builder.isHittable { break }
      app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8))
        .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.55)))
    }
    builder.tap()
    builder.typeText("0x0000000000000000000000000000000000000001\n")
    XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 5))
    app.buttons["Fetch Builder Fee"].tap()
    XCTAssertTrue(app.staticTexts["builder_fee_result"].waitForExistence(timeout: 20), app.debugDescription)
    XCTAssertFalse(app.staticTexts["info_error"].exists)
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  func testInfo_segmentedControl_switchesSections() {
    openExample("Info")
    XCTAssertTrue(app.navigationBars["Info API"].waitForExistence(timeout: 3))

    // Market Data is default; switch to User Data then Metadata
    let userData = app.buttons["User Data"]
    if userData.waitForExistence(timeout: 2) {
      userData.tap()
    }
    let metadata = app.buttons["Metadata"]
    if metadata.waitForExistence(timeout: 2) {
      metadata.tap()
      XCTAssertTrue(app.buttons["Load Meta"].waitForExistence(timeout: 2) ||
                    app.staticTexts["Meta (Perpetual)"].waitForExistence(timeout: 2))
    }
  }

  // MARK: - Trading

  func testTrading_opensExchangeSections() {
    openExample("Trading")
    XCTAssertTrue(app.navigationBars["Exchange API"].waitForExistence(timeout: 3))
    let asset = app.textFields["trade_PlaceOrderForm_asset"]
    XCTAssertTrue(asset.waitForExistence(timeout: 5), app.debugDescription)
  }

  func testTrading_segmentedControl_hasAllTabs() {
    openExample("Trading")
    XCTAssertTrue(app.navigationBars["Exchange API"].waitForExistence(timeout: 3))
    for tab in ["Orders", "Position", "Transfers", "Account"] {
      XCTAssertTrue(app.buttons[tab].exists || app.staticTexts[tab].exists,
                    "Missing trading tab: \(tab)")
    }
  }

  private func reachTradingControl(_ element: XCUIElement) {
    for _ in 0..<30 {
      if element.exists && element.isHittable { return }
      app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.8))
        .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.55)))
    }
    XCTAssertTrue(element.isHittable, app.debugDescription)
  }

  // MARK: - WebSocket

  func testWebSocket_opensConnectionControls() {
    openExample("WebSocket")
    // Title may vary; look for Connect control
    let connect = app.buttons["Connect"]
    let disconnected = app.staticTexts["Disconnected"]
    XCTAssertTrue(connect.waitForExistence(timeout: 3) || disconnected.waitForExistence(timeout: 3))
  }

  // MARK: - Wallet

  func testWallet_opens() {
    openExample("Wallet")
    // Any wallet-related content
    let nav = app.navigationBars.firstMatch
    XCTAssertTrue(nav.waitForExistence(timeout: 3))
  }

  // MARK: - Navigation round-trip

  func testNavigation_backFromInfo_returnsHome() {
    openExample("Info")
    XCTAssertTrue(app.navigationBars["Info API"].waitForExistence(timeout: 3))
    goBack()
    XCTAssertTrue(app.navigationBars["API Explorer"].waitForExistence(timeout: 3))
  }

  func testNavigation_visitAllFeatures() {
    for feature in ["Info", "Trading", "WebSocket", "Wallet"] {
      openExample(feature)
      goBack()
      XCTAssertTrue(app.navigationBars["API Explorer"].exists)
    }
    app.tabBars.buttons["Overview"].tap()
    XCTAssertTrue(app.navigationBars["Overview"].exists)
  }

  /// Selects the settings tab, keeping its navigation stack independent of API examples.
  private func openSettings() {
    app.tabBars.buttons["Settings"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
  }

  /// Opens an existing SDK example, initializing the default read-only environment if needed.
  private func openExample(_ name: String) {
    app.tabBars.buttons["API Explorer"].tap()
    let link = app.buttons["nav_" + name.lowercased()]
    if !link.isEnabled {
      openSettings()
      let initialize = app.buttons["initialize_sdk"]
      if initialize.isEnabled {
        reachTradingControl(initialize); initialize.tap()
        XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 10))
        app.alerts.buttons["OK"].tap()
      }
      app.tabBars.buttons["API Explorer"].tap()
    }
    link.tap()
  }

  /// Pops a destination, or returns to Overview when the current tab is already at its root.
  private func goBack() {
    let back = app.navigationBars.buttons.matching(identifier: "BackButton").firstMatch
    if back.exists { back.tap() }
    else if app.navigationBars["Info API"].exists || app.navigationBars["Exchange API"].exists ||
      app.navigationBars["Wallet"].exists || app.navigationBars["WebSocket"].exists ||
      app.navigationBars["Available Balances"].exists {
      app.navigationBars.buttons.element(boundBy: 0).tap()
    } else { app.tabBars.buttons["Overview"].tap() }
  }
}
