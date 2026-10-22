//
//  RetryPolicy.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Configures exponential-backoff retries for API operations.
public struct RetryPolicy: Sendable {
  /// Maximum number of retry attempts.
  public let maxRetries: Int
  /// Delay before the first retry.
  public let baseDelay: TimeInterval
  /// Multiplier applied to each subsequent delay.
  public let multiplier: Double
  /// Upper bound for a retry delay.
  public let maxDelay: TimeInterval
  
  /// Creates a retry policy.
  public init(
    maxRetries: Int = Constants.Retry.maxRetries,
    baseDelay: TimeInterval = Constants.Retry.baseDelay,
    multiplier: Double = Constants.Retry.multiplier,
    maxDelay: TimeInterval = 30.0
  ) {
    self.maxRetries = maxRetries
    self.baseDelay = baseDelay
    self.multiplier = multiplier
    self.maxDelay = maxDelay
  }
  
  /// Returns the capped delay for a zero-based retry attempt.
  public func delay(for attempt: Int) -> TimeInterval {
    let delay = baseDelay * pow(multiplier, Double(attempt))
    return min(delay, maxDelay)
  }
  
  /// Whether the policy permits at least one retry.
  public var shouldRetry: Bool {
    maxRetries > 0
  }
}

/// Provides common retry policy configurations.
public extension RetryPolicy {
  /// Default SDK retry policy.
  static let `default` = RetryPolicy()
  
  /// Policy that disables retries.
  static let noRetry = RetryPolicy(maxRetries: 0, baseDelay: 0)
}

/// Determines whether an error is eligible for retry.
public enum RetryableError {
  /// Returns whether an error should be retried.
  public static func isRetryable(_ error: any Error) -> Bool {
    if let heliqError = error as? any HeliqError {
      return heliqError.isRetryable
    }
    if let urlError = error as? URLError {
      switch urlError.code {
      case .timedOut, .networkConnectionLost, .notConnectedToInternet:
        return true
      default:
        return false
      }
    }
    return false
  }
}
