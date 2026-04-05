//
//  MockAPIClient.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
@testable import HeliqSDK

protocol MockAPIClientProtocol {
  var requestCount: Int { get }
  var mockResponse: Data? { get set }
  var mockError: Error? { get set }
  func request<T: Decodable>(_ router: any APIRouterProtocol) async throws -> T
  func requestData(_ router: any APIRouterProtocol) async throws -> Data
}

final class MockAPIClient: MockAPIClientProtocol, @unchecked Sendable {
  var mockResponse: Data?
  var mockError: Error?
  private(set) var requestCount = 0
  
  init(mockResponse: Data? = nil, mockError: Error? = nil) {
    self.mockResponse = mockResponse
    self.mockError = mockError
  }
  
  func request<T: Decodable>(_ router: any APIRouterProtocol) async throws -> T {
    requestCount += 1
    if let error = mockError {
      throw error
    }
    guard let data = mockResponse else {
      throw NetworkError.invalidResponse
    }
    return try JSONCoder.decode(T.self, from: data)
  }
  
  func requestData(_ router: any APIRouterProtocol) async throws -> Data {
    requestCount += 1
    if let error = mockError {
      throw error
    }
    guard let data = mockResponse else {
      throw NetworkError.invalidResponse
    }
    return data
  }
  
  func reset() {
    requestCount = 0
    mockResponse = nil
    mockError = nil
  }
}
