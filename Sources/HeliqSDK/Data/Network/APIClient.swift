//
//  APIClient.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class APIClient: @unchecked Sendable {
  private let session: URLSession
  private let environment: HeliqEnvironment
  private let retryPolicy: RetryPolicy
  private let rateLimitHandler: RateLimitHandler
  
  public init(
    environment: HeliqEnvironment,
    session: URLSession = .shared,
    retryPolicy: RetryPolicy = .default,
    rateLimitHandler: RateLimitHandler = RateLimitHandler()
  ) {
    self.environment = environment
    self.session = session
    self.retryPolicy = retryPolicy
    self.rateLimitHandler = rateLimitHandler
  }
  
  public func request<T: Decodable>(_ router: any APIRouterProtocol) async throws -> T {
    let request = try router.urlRequest(baseURL: Constants.API.baseURL(for: environment))
    
    guard let urlRequest = request else {
      throw NetworkError.invalidResponse
    }
    
    try await rateLimitHandler.waitForToken(endpoint: router.path)
    
    var lastError: Error = NetworkError.unknown(underlying: nil)
    
    for attempt in 0..<retryPolicy.maxRetries {
      Logger.shared.debug("request path=\(router.path) attempt=\(attempt + 1)", category: .network)
      do {
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
          throw NetworkError.invalidResponse
        }
        
        Logger.shared.debug("response path=\(router.path) status=\(httpResponse.statusCode) bytes=\(data.count)", category: .network)

        switch httpResponse.statusCode {
        case 200...299:
          let decoder = JSONDecoder()
          decoder.dateDecodingStrategy = .millisecondsSince1970
          do {
            return try decoder.decode(T.self, from: data)
          } catch {
            Logger.shared.error("decode-failed path=\(router.path) error=\(error.localizedDescription)", category: .network)
            throw APIError.decodingFailed(underlying: error)
          }
          
        case 429:
          let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Double($0) }
          throw APIError.rateLimited(retryAfter: retryAfter)
          
        case 400...499:
          let errorMessage = String(data: data, encoding: .utf8)
          throw APIError.clientError(statusCode: httpResponse.statusCode, message: errorMessage)
          
        case 500...599:
          throw APIError.serverError(statusCode: httpResponse.statusCode)
          
        default:
          throw APIError.invalidResponse
        }
      } catch let error as HeliqError where error.isRetryable {
        lastError = error
        if attempt < retryPolicy.maxRetries - 1 {
          let delay = retryPolicy.delay(for: attempt)
          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
          continue
        }
      } catch let error as HeliqError {
        throw error
      } catch {
        lastError = NetworkError.unknown(underlying: error)
        if attempt < retryPolicy.maxRetries - 1 {
          let delay = retryPolicy.delay(for: attempt)
          try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
          continue
        }
      }
    }
    
    throw lastError
  }
  
  public func requestData(_ router: any APIRouterProtocol) async throws -> Data {
    let request = try router.urlRequest(baseURL: Constants.API.baseURL(for: environment))
    
    guard let urlRequest = request else {
      throw NetworkError.invalidResponse
    }
    
    try await rateLimitHandler.waitForToken(endpoint: router.path)
    
    Logger.shared.debug("request-data path=\(router.path)", category: .network)
    let (data, response) = try await session.data(for: urlRequest)
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw NetworkError.invalidResponse
    }

    Logger.shared.debug("response-data path=\(router.path) status=\(httpResponse.statusCode) bytes=\(data.count)", category: .network)
    
    switch httpResponse.statusCode {
    case 200...299:
      return data
    case 429:
      let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Double($0) }
      throw APIError.rateLimited(retryAfter: retryAfter)
    case 400...499:
      let errorMessage = String(data: data, encoding: .utf8)
      throw APIError.clientError(statusCode: httpResponse.statusCode, message: errorMessage)
    case 500...599:
      throw APIError.serverError(statusCode: httpResponse.statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
}
