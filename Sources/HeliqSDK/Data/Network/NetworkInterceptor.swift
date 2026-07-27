//
//  NetworkInterceptor.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines requirements for network interceptor implementations.
public protocol NetworkInterceptor: Sendable {
  /// Performs the intercept operation.
  func intercept(request: inout URLRequest) async
}

/// Provides network interceptor chain functionality.
public final class NetworkInterceptorChain: Sendable {
  private let interceptors: [any NetworkInterceptor]
  
  /// Creates a network interceptor chain.
  public init(interceptors: [any NetworkInterceptor] = []) {
    self.interceptors = interceptors
  }
  
  /// Performs the intercept operation.
  public func intercept(request: inout URLRequest) async {
    for interceptor in interceptors {
      await interceptor.intercept(request: &request)
    }
  }
}
