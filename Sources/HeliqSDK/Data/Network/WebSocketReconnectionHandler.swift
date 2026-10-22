//
//  WebSocketReconnectionHandler.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Provides web socket reconnection handler functionality.
public final class WebSocketReconnectionHandler: @unchecked Sendable {
  private var consecutiveFailures: Int = 0
  private let maxFailures: Int = 5
  private let baseDelay: TimeInterval = 1.0
  private let maxDelay: TimeInterval = 30.0
  private let multiplier: Double = 2.0
  private let queue = DispatchQueue(label: "com.heliqsdk.reconnection")
  
  /// Creates a web socket reconnection handler.
  public init() {}
  
  /// Performs the should reconnect operation.
  public func shouldReconnect() async -> Bool {
    await withCheckedContinuation { continuation in
      queue.async {
        let result = self.consecutiveFailures < self.maxFailures
        continuation.resume(returning: result)
      }
    }
  }
  
  /// Performs the record failure operation.
  public func recordFailure() async {
    await withCheckedContinuation { continuation in
      queue.async {
        self.consecutiveFailures += 1
        continuation.resume()
      }
    }
  }
  
  /// Performs the record success operation.
  public func recordSuccess() async {
    await withCheckedContinuation { continuation in
      queue.async {
        self.consecutiveFailures = 0
        continuation.resume()
      }
    }
  }
  
  /// Performs the schedule reconnect operation.
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
  
  /// Performs the reset operation.
  public func reset() async {
    await withCheckedContinuation { continuation in
      queue.async {
        self.consecutiveFailures = 0
        continuation.resume()
      }
    }
  }
}
