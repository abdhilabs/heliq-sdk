//
//  Constants.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Selects the Hyperliquid deployment to use.
public enum HeliqEnvironment: Sendable {
  /// Production Hyperliquid environment.
  case mainnet
  /// Hyperliquid test environment.
  case testnet
  /// Local development environment.
  case local
}

/// Namespace for SDK configuration constants.
public enum Constants {
  /// Constants for HTTP API endpoints.
  public enum API {
    /// Base URL for the mainnet HTTP API.
    public static let mainnetBaseURL = "https://api.hyperliquid.xyz"
    /// Base URL for the testnet HTTP API.
    public static let testnetBaseURL = "https://api.hyperliquid-testnet.xyz"
    /// Base URL for a local HTTP API.
    public static let localBaseURL = "http://localhost:3000"
    
    /// Path for information requests.
    public static let infoEndpoint = "/info"
    /// Path for signed exchange requests.
    public static let exchangeEndpoint = "/exchange"
    /// Deprecated alias for `exchangeEndpoint`.
    @available(*, deprecated, message: "Use exchangeEndpoint; Hyperliquid signed actions use /exchange.")
    public static let tradeEndpoint = exchangeEndpoint
    
    /// Returns the HTTP API base URL for an environment.
    public static func baseURL(for environment: HeliqEnvironment) -> String {
      switch environment {
      case .mainnet:
        return mainnetBaseURL
      case .testnet:
        return testnetBaseURL
      case .local:
        return localBaseURL
      }
    }
  }
  
  /// Constants for WebSocket connections.
  public enum WebSocket {
    /// WebSocket URL for mainnet.
    public static let mainnetURL = "wss://api.hyperliquid.xyz/ws"
    /// WebSocket URL for testnet.
    public static let testnetURL = "wss://api.hyperliquid-testnet.xyz/ws"
    /// WebSocket URL for local development.
    public static let localURL = "ws://localhost:3000/ws"
    
    /// Returns the WebSocket URL for an environment.
    public static func url(for environment: HeliqEnvironment) -> String {
      switch environment {
      case .mainnet:
        return mainnetURL
      case .testnet:
        return testnetURL
      case .local:
        return localURL
      }
    }
    
    /// Interval between WebSocket ping messages.
    public static let pingInterval: TimeInterval = 50
    /// Maximum wait time for a WebSocket pong response.
    public static let pongTimeout: TimeInterval = 10
  }
  
  /// Default HTTP rate-limiting values.
  public enum RateLimiting {
    /// Default maximum requests per rate-limit window.
    public static let defaultRequestsPerWindow = 100
    /// Duration of the default rate-limit window.
    public static let defaultWindowDuration: TimeInterval = 10
  }
  
  /// Default retry-policy values.
  public enum Retry {
    /// Default number of retry attempts.
    public static let maxRetries = 3
    /// Default delay before the first retry.
    public static let baseDelay: TimeInterval = 1.0
    /// Default multiplier for exponential retry backoff.
    public static let multiplier: Double = 2.0
  }
  
  /// Default cache expiration values.
  public enum Cache {
    /// Cache lifetime for asset metadata.
    public static let assetMetaTTL: TimeInterval = 3600
  }
}
