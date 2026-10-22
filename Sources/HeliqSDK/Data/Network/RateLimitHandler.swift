//
//  RateLimitHandler.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Coordinates access to rate limit handler state.
public actor RateLimitHandler {
  private let requestsPerWindow: Int
  private let windowDuration: TimeInterval
  private var tokens: Int
  private var lastRefill: Date
  
  /// Creates a rate limit handler.
  public init(
    requestsPerWindow: Int = Constants.RateLimiting.defaultRequestsPerWindow,
    windowDuration: TimeInterval = Constants.RateLimiting.defaultWindowDuration
  ) {
    self.requestsPerWindow = requestsPerWindow
    self.windowDuration = windowDuration
    self.tokens = requestsPerWindow
    self.lastRefill = Date()
  }
  
  /// Performs the wait for token operation.
  public func waitForToken(endpoint: String) async throws {
    refillTokens()
    
    if tokens > 0 {
      tokens -= 1
      return
    }
    
    let waitTime = windowDuration - Date().timeIntervalSince(lastRefill)
    try await Task.sleep(nanoseconds: UInt64(max(waitTime, 0) * 1_000_000_000))
    refillTokens()
    tokens -= 1
  }
  
  private func refillTokens() {
    let now = Date()
    let elapsed = now.timeIntervalSince(lastRefill)
    
    if elapsed >= windowDuration {
      tokens = requestsPerWindow
      lastRefill = now
    }
  }
  
  /// Performs the reset operation.
  public func reset() {
    tokens = requestsPerWindow
    lastRefill = Date()
  }
}
