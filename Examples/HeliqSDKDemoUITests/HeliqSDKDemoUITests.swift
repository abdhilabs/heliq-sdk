//
//  HeliqSDKDemoUITests.swift
//  HeliqSDKDemoUITests
//
//  Created by Abdhilabs on 05/04/26.
//
//  UI tests for the example app — covers navigation and primary feature screens.
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
