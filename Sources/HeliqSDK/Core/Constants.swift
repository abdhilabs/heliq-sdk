//
//  Constants.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum HeliqEnvironment: Sendable {
  case mainnet
  case testnet
  case local
}

public enum Constants {
  public enum API {
    public static let mainnetBaseURL = "https://api.hyperliquid.xyz"
    public static let testnetBaseURL = "https://api.hyperliquid-testnet.xyz"
    public static let localBaseURL = "http://localhost:3000"
    
    public static let infoEndpoint = "/info"
    public static let tradeEndpoint = "/trade"
    
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
  
  public enum WebSocket {
    public static let mainnetURL = "wss://api.hyperliquid.xyz/ws"
    public static let testnetURL = "wss://api.hyperliquid-testnet.xyz/ws"
    public static let localURL = "ws://localhost:3000/ws"
    
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
    
    public static let pingInterval: TimeInterval = 50
    public static let pongTimeout: TimeInterval = 10
  }
  
  public enum RateLimiting {
    public static let defaultRequestsPerWindow = 100
    public static let defaultWindowDuration: TimeInterval = 10
  }
  
  public enum Retry {
    public static let maxRetries = 3
    public static let baseDelay: TimeInterval = 1.0
    public static let multiplier: Double = 2.0
  }
  
  public enum Cache {
    public static let assetMetaTTL: TimeInterval = 3600
  }
}
