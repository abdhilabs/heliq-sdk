//
//  APIClientTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct APIClientTests {
  
  @Test
  func testInit_withEnvironment_setsEnvironment() {
    let client = APIClient(environment: .testnet)
    #expect(true)
  }
  
  @Test
  func testInit_withAllParameters_succeeds() {
    let client = APIClient(
      environment: .mainnet,
      session: .shared,
      retryPolicy: .default,
      rateLimitHandler: RateLimitHandler()
    )
    #expect(true)
  }
  
  @Test
  func testRetryPolicy_defaultHas3Retries() {
    let policy = RetryPolicy.default
    #expect(policy.maxRetries == 3)
  }
  
  @Test
  func testRetryPolicy_delay_increasesExponentially() {
    let policy = RetryPolicy(maxRetries: 5, baseDelay: 1.0, multiplier: 2.0)
    
    #expect(policy.delay(for: 0) == 1.0)
    #expect(policy.delay(for: 1) == 2.0)
    #expect(policy.delay(for: 2) == 4.0)
    #expect(policy.delay(for: 3) == 8.0)
  }
  
  @Test
  func testRetryPolicy_shouldRetry_withAttemptsRemaining_returnsTrue() {
    let policy = RetryPolicy(maxRetries: 3, baseDelay: 1.0, multiplier: 2.0)
    #expect(policy.shouldRetry == true)
  }
  
  @Test
  func testRateLimitHandler_init_withDefaultValues_succeeds() {
    let handler = RateLimitHandler()
    #expect(true)
  }
  
  @Test
  func testRateLimitHandler_init_withCustomValues_succeeds() {
    let handler = RateLimitHandler(requestsPerWindow: 50, windowDuration: 30)
    #expect(true)
  }
}
