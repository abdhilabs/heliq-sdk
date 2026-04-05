//
//  WebSocketReconnectionHandler.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class WebSocketReconnectionHandler: @unchecked Sendable {
  private var consecutiveFailures: Int = 0
  private let maxFailures: Int = 5
  private let baseDelay: TimeInterval = 1.0
  private let maxDelay: TimeInterval = 30.0
  private let multiplier: Double = 2.0
  private let queue = DispatchQueue(label: "com.heliqsdk.reconnection")
  
  public init() {}
  
  public func shouldReconnect() async -> Bool {
    await withCheckedContinuation { continuation in
      queue.async {
        let result = self.consecutiveFailures < self.maxFailures
        continuation.resume(returning: result)
      }
    }
  }
  
  public func recordFailure() async {
    await withCheckedContinuation { continuation in
      queue.async {
        self.consecutiveFailures += 1
        continuation.resume()
      }
    }
  }
  
  public func recordSuccess() async {
    await withCheckedContinuation { continuation in
      queue.async {
        self.consecutiveFailures = 0
        continuation.resume()
      }
    }
  }
  
  public func scheduleReconnect() async {
    let failures = await withCheckedContinuation { continuation in
      queue.async {
        let f = self.consecutiveFailures
        continuation.resume(returning: f)
      }
    }
    
    let delay = min(baseDelay * pow(multiplier, Double(failures)), maxDelay)
    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
  }
  
  public func reset() async {
    await withCheckedContinuation { continuation in
      queue.async {
        self.consecutiveFailures = 0
        continuation.resume()
      }
    }
  }
}
