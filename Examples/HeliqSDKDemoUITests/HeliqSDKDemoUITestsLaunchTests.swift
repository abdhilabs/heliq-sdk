//
//  HeliqSDKDemoUITestsLaunchTests.swift
//  HeliqSDKDemoUITests
//
//  Created by Abdhilabs on 05/04/26.
//

import XCTest

@MainActor
final class HeliqSDKDemoUITestsLaunchTests: XCTestCase {
  override class var runsForEachTargetApplicationUIConfiguration: Bool { true }

  override func setUpWithError() throws {
    continueAfterFailure = false
  }

  func testLaunch() throws {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(app.navigationBars["HeliqSDK Demo"].waitForExistence(timeout: 5))

    let attachment = XCTAttachment(screenshot: app.screenshot())
    attachment.name = "Launch Screen"
    attachment.lifetime = .keepAlways
    add(attachment)
  }
}
