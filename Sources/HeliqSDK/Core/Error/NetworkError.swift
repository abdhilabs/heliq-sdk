//
//  NetworkError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Describes network failures returned by the SDK.
public enum NetworkError: HeliqError, Sendable {
  /// Existing network connectivity was lost.
  case connectivityLost
  /// A network request timed out.
  case timeout
  /// DNS lookup failed.
  case dnsResolutionFailed
  /// The remote host refused the connection.
  case connectionRefused
  /// No network connection is available.
  case networkUnavailable
  /// The network response was invalid.
  case invalidResponse
  /// An unclassified network error occurred.
  case unknown(underlying: Error?)
  
  /// Stable machine-readable code for this error.
  public var errorCode: String {
    switch self {
    case .connectivityLost:
      return "NETWORK_CONNECTIVITY_LOST"
    case .timeout:
      return "NETWORK_TIMEOUT"
    case .dnsResolutionFailed:
      return "NETWORK_DNS_FAILED"
    case .connectionRefused:
      return "NETWORK_CONNECTION_REFUSED"
    case .networkUnavailable:
      return "NETWORK_UNAVAILABLE"
    case .invalidResponse:
      return "NETWORK_INVALID_RESPONSE"
    case .unknown:
      return "NETWORK_UNKNOWN"
    }
  }
  
  /// Human-readable description of this error.
  public var errorDescription: String {
    switch self {
    case .connectivityLost:
      return "Network connectivity was lost"
    case .timeout:
      return "Request timed out"
    case .dnsResolutionFailed:
      return "DNS resolution failed"
    case .connectionRefused:
      return "Connection refused"
    case .networkUnavailable:
      return "Network is unavailable"
    case .invalidResponse:
      return "Invalid response from server"
    case .unknown(let underlying):
      if let underlying = underlying {
        return "Unknown network error: \(underlying.localizedDescription)"
      }
      return "Unknown network error"
    }
  }
  
  /// Whether retrying the failed operation may succeed.
  public var isRetryable: Bool {
    switch self {
    case .connectivityLost, .timeout, .networkUnavailable, .invalidResponse:
      return true
    case .dnsResolutionFailed, .connectionRefused:
      return false
    case .unknown:
      return true
    }
  }
}
