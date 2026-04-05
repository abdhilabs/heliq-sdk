//
//  APIResponse.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum APIResponse<T: Sendable> {
  case success(T)
  case error(any HeliqError)
}

public struct APIResult<T: Sendable>: Sendable {
  public let value: T?
  public let error: (any HeliqError)?
  public let isSuccess: Bool
  
  public init(success: T) {
    self.value = success
    self.error = nil
    self.isSuccess = true
  }
  
  public init(failure: any HeliqError) {
    self.value = nil
    self.error = failure
    self.isSuccess = false
  }
  
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

public struct HyperliquidResponse<T: Sendable>: Sendable {
  public let method: String?
  public let data: T?
  public let error: HyperliquidErrorResponse?
  
  public struct HyperliquidErrorResponse: Sendable, Codable {
    public let code: Int
    public let message: String
  }
}

public enum APIEndpoint {
  case info
  case trade
  
  public var path: String {
    switch self {
    case .info:
      return Constants.API.infoEndpoint
    case .trade:
      return Constants.API.tradeEndpoint
    }
  }
}
