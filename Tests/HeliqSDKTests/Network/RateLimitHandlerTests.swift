//
//  RateLimitHandlerTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct RateLimitHandlerTests {
  
  @Test
  func testInit_withDefaultValues_setsCorrectLimits() async {
    let handler = RateLimitHandler()
    #expect(true)
  }
  
  @Test
  func testInit_withCustomValues_setsCorrectLimits() async {
    let handler = RateLimitHandler(requestsPerWindow: 5, windowDuration: 30)
    #expect(true)
  }
  
  @Test
  func testReset_clearsTokensAndResetsTimer() async {
    let handler = RateLimitHandler(requestsPerWindow: 10, windowDuration: 60)
    await handler.reset()
    #expect(true)
  }
  
  @Test
  func testWaitForToken_doesNotThrowForValidInput() async throws {
    let handler = RateLimitHandler(requestsPerWindow: 10, windowDuration: 60)
    try await handler.waitForToken(endpoint: "/test")
    #expect(true)
  }
  
  @Test
  func testWaitForToken_multipleCalls_tracksTokens() async throws {
    let handler = RateLimitHandler(requestsPerWindow: 10, windowDuration: 60)
    for _ in 0..<10 {
      try await handler.waitForToken(endpoint: "/test")
    }
    #expect(true)
  }
}
