//
//  HeliqError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Common interface for errors emitted by Heliq SDK operations.
public protocol HeliqError: Error, Sendable {
  /// Indicates whether retrying the operation may succeed.
  var isRetryable: Bool { get }
  /// Stable machine-readable error code.
  var errorCode: String { get }
  /// Human-readable error description.
  var errorDescription: String { get }
}

/// Provides default behavior for Heliq SDK errors.
public extension HeliqError {
  /// Returns `false` unless the concrete error opts into retry behavior.
  var isRetryable: Bool {
    false
  }
}
