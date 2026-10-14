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
    app = XCUIApplication()
    app.launchArguments += ["-ui-testing"]
    app.launch()
  }

  override func tearDownWithError() throws {
    app = nil
  }

  // MARK: - Home

  func testHome_showsNavigationTitle() {
    XCTAssertTrue(app.navigationBars["HeliqSDK Demo"].waitForExistence(timeout: 5))
  }

  func testHome_listsAllFeatureEntries() {
    XCTAssertTrue(app.staticTexts["Info"].exists)
    XCTAssertTrue(app.staticTexts["Trading"].exists)
    XCTAssertTrue(app.staticTexts["WebSocket"].exists)
    XCTAssertTrue(app.staticTexts["Wallet"].exists)
    XCTAssertTrue(app.staticTexts["Settings"].exists)
  }

  // MARK: - Settings

  func testSettings_canOpenAndShowEnvironments() {
    app.staticTexts["Settings"].tap()
    XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.staticTexts["Mainnet"].exists || app.buttons["Mainnet"].exists)
    XCTAssertTrue(app.staticTexts["Testnet"].exists || app.buttons["Testnet"].exists)
  }

  // MARK: - Info

  func testInfo_opensMarketDataSection() {
    app.staticTexts["Info"].tap()
    XCTAssertTrue(app.navigationBars["Info API"].waitForExistence(timeout: 3))
    XCTAssertTrue(app.buttons["Load All Mids"].waitForExistence(timeout: 3) ||
                  app.staticTexts["All Mids"].waitForExistence(timeout: 3))
  }

  func testInfo_loadAllMidsShowsResultOrError() {
    app.staticTexts["Info"].tap()
    XCTAssertTrue(app.navigationBars["Info API"].waitForExistence(timeout: 3))

    app.buttons["Load All Mids"].tap()

    let result = app.staticTexts["Tap to load"].waitForNonExistence(timeout: 15)
    let error = app.staticTexts["Error"].waitForExistence(timeout: 15)
    XCTAssertTrue(result || error, "Info request must show data or a visible error")
  }

  func testInfo_loadCandlesShowsChartWithoutError() {
    app.staticTexts["Settings"].tap()
    app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    app.navigationBars.buttons.element(boundBy: 0).tap()
    app.staticTexts["Info"].tap()

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
    app.staticTexts["Settings"].tap()
    app.buttons["initialize_sdk"].tap()
    XCTAssertTrue(app.alerts["SDK Initialized"].waitForExistence(timeout: 5))
    app.alerts.buttons["OK"].tap()
    app.navigationBars.buttons.element(boundBy: 0).tap()
    app.staticTexts["Info"].tap()
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
      XCTAssertTrue(app.staticTexts["orders_result"].waitForExistence(timeout: 20), app.debugDescription)
      XCTAssertEqual(app.staticTexts["orders_result"].label.filter { !$0.isWhitespace }, "[]")
      XCTAssertFalse(app.staticTexts["info_error"].exists, button)
    }
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  func testInfo_segmentedControl_switchesSections() {
    app.staticTexts["Info"].tap()
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
    app.staticTexts["Trading"].tap()
    XCTAssertTrue(app.navigationBars["Exchange API"].waitForExistence(timeout: 3))
    // Either not-initialized banner or Orders section
    let notInit = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'not initialized'")).firstMatch
    let placeOrder = app.staticTexts["Place Order"]
    XCTAssertTrue(notInit.waitForExistence(timeout: 2) || placeOrder.waitForExistence(timeout: 2))
  }

  func testTrading_segmentedControl_hasAllTabs() {
    app.staticTexts["Trading"].tap()
    XCTAssertTrue(app.navigationBars["Exchange API"].waitForExistence(timeout: 3))
    for tab in ["Orders", "Position", "Transfers", "Account"] {
      XCTAssertTrue(app.buttons[tab].exists || app.staticTexts[tab].exists,
                    "Missing trading tab: \(tab)")
    }
  }

  // MARK: - WebSocket

  func testWebSocket_opensConnectionControls() {
    app.staticTexts["WebSocket"].tap()
    // Title may vary; look for Connect control
    let connect = app.buttons["Connect"]
    let disconnected = app.staticTexts["Disconnected"]
    XCTAssertTrue(connect.waitForExistence(timeout: 3) || disconnected.waitForExistence(timeout: 3))
  }

  // MARK: - Wallet

  func testWallet_opens() {
    app.staticTexts["Wallet"].tap()
    // Any wallet-related content
    let nav = app.navigationBars.firstMatch
    XCTAssertTrue(nav.waitForExistence(timeout: 3))
  }

  // MARK: - Navigation round-trip

  func testNavigation_backFromInfo_returnsHome() {
    app.staticTexts["Info"].tap()
    XCTAssertTrue(app.navigationBars["Info API"].waitForExistence(timeout: 3))
    app.navigationBars.buttons.element(boundBy: 0).tap()
    XCTAssertTrue(app.navigationBars["HeliqSDK Demo"].waitForExistence(timeout: 3))
  }

  func testNavigation_visitAllFeatures() {
    let features = ["Info", "Trading", "WebSocket", "Wallet", "Settings"]
    for feature in features {
      XCTAssertTrue(app.staticTexts[feature].waitForExistence(timeout: 3), "Missing home entry: \(feature)")
      app.staticTexts[feature].tap()
      // Go back
      if app.navigationBars.buttons.count > 0 {
        app.navigationBars.buttons.element(boundBy: 0).tap()
      }
      XCTAssertTrue(app.navigationBars["HeliqSDK Demo"].waitForExistence(timeout: 3))
    }
  }
}
