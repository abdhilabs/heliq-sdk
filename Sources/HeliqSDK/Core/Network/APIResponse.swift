//
//  APIResponse.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents either a successful API value or an SDK error.
public enum APIResponse<T: Sendable> {
  /// Successful response value.
  case success(T)
  /// Failed response with an SDK error.
  case error(any HeliqError)
}

/// Stores the value or error produced by an API operation.
public struct APIResult<T: Sendable>: Sendable {
  /// Successful value, if available.
  public let value: T?
  /// Failure, if the operation was unsuccessful.
  public let error: (any HeliqError)?
  /// Whether this result contains a successful value.
  public let isSuccess: Bool
  
  /// Creates a successful result.
  public init(success: T) {
    self.value = success
    self.error = nil
    self.isSuccess = true
  }
  
  /// Creates a failed result.
  public init(failure: any HeliqError) {
    self.value = nil
    self.error = failure
    self.isSuccess = false
  }
  
  /// Returns the successful value or throws the stored error.
  public func get() throws -> T {
    if let error = error {
      throw error
    }
    guard let value = value else {
      throw APIError.invalidResponse
    }
    return value
  }
}

/// Raw response envelope returned by Hyperliquid.
public struct HyperliquidResponse<T: Sendable>: Sendable {
  /// Response method name, when provided.
  public let method: String?
  /// Response payload, when provided.
  public let data: T?
  /// API error payload, when provided.
  public let error: HyperliquidErrorResponse?
  
  /// Error payload returned by Hyperliquid.
  public struct HyperliquidErrorResponse: Sendable, Codable {
    /// Numeric API error code.
    public let code: Int
    /// API error message.
    public let message: String
  }
}

/// HTTP endpoint supported by the SDK.
public enum APIEndpoint {
  /// Information-query endpoint.
  case info
  /// Signed exchange endpoint.
  case trade
  
  /// URL path for this endpoint.
  public var path: String {
    switch self {
    case .info:
      return Constants.API.infoEndpoint
    case .trade:
      return Constants.API.tradeEndpoint
    }
  }
}
