//
//  NetworkError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum NetworkError: HeliqError, Sendable {
  case connectivityLost
  case timeout
  case dnsResolutionFailed
  case connectionRefused
  case networkUnavailable
  case invalidResponse
  case unknown(underlying: Error?)
  
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
