//
//  NetworkInterceptor.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public protocol NetworkInterceptor: Sendable {
  func intercept(request: inout URLRequest) async
}

public final class NetworkInterceptorChain: Sendable {
  private let interceptors: [any NetworkInterceptor]
  
  public init(interceptors: [any NetworkInterceptor] = []) {
    self.interceptors = interceptors
  }
  
  public func intercept(request: inout URLRequest) async {
    for interceptor in interceptors {
      await interceptor.intercept(request: &request)
    }
  }
}
