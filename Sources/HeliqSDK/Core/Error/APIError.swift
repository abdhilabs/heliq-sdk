//
//  APIError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum APIError: HeliqError, Sendable {
  case rateLimited(retryAfter: TimeInterval?)
  case serverError(statusCode: Int)
  case clientError(statusCode: Int, message: String?)
  case invalidResponse
  case decodingFailed(underlying: Error?)
  case hyperliquidError(code: Int, message: String)
  
  public var errorCode: String {
    switch self {
    case .rateLimited:
      return "API_RATE_LIMITED"
    case .serverError(let statusCode):
      return "API_SERVER_ERROR_\(statusCode)"
    case .clientError(let statusCode, _):
      return "API_CLIENT_ERROR_\(statusCode)"
    case .invalidResponse:
      return "API_INVALID_RESPONSE"
    case .decodingFailed:
      return "API_DECODING_FAILED"
    case .hyperliquidError(let code, _):
      return "API_HYPERLIQUID_ERROR_\(code)"
    }
  }
  
  public var errorDescription: String {
    switch self {
    case .rateLimited(let retryAfter):
      if let retryAfter = retryAfter {
        return "Rate limited. Retry after \(retryAfter) seconds"
      }
      return "Rate limited"
    case .serverError(let statusCode):
      return "Server error with status code: \(statusCode)"
    case .clientError(let statusCode, let message):
      if let message = message {
        return "Client error (\(statusCode)): \(message)"
      }
      return "Client error with status code: \(statusCode)"
    case .invalidResponse:
      return "Invalid response from server"
    case .decodingFailed(let underlying):
      if let underlying = underlying {
        return "Failed to decode response: \(underlying.localizedDescription)"
      }
      return "Failed to decode response"
    case .hyperliquidError(let code, let message):
      return "Hyperliquid API error (\(code)): \(message)"
    }
  }
  
  public var isRetryable: Bool {
    switch self {
    case .rateLimited:
      return true
    case .serverError:
      return true
    case .clientError:
      return false
    case .invalidResponse:
      return true
    case .decodingFailed:
      return false
    case .hyperliquidError:
      return false
    }
  }
}
