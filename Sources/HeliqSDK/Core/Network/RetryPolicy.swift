//
//  RetryPolicy.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct RetryPolicy: Sendable {
  public let maxRetries: Int
  public let baseDelay: TimeInterval
  public let multiplier: Double
  public let maxDelay: TimeInterval
  
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
  
  public func delay(for attempt: Int) -> TimeInterval {
    let delay = baseDelay * pow(multiplier, Double(attempt))
    return min(delay, maxDelay)
  }
  
  public var shouldRetry: Bool {
    maxRetries > 0
  }
}

public extension RetryPolicy {
  static let `default` = RetryPolicy()
  
  static let noRetry = RetryPolicy(maxRetries: 0, baseDelay: 0)
}

public enum RetryableError {
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
