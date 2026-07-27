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
    
    let startedAt = Date()
    var lastError: Error = NetworkError.unknown(underlying: nil)
    
    for attempt in 0..<retryPolicy.maxRetries {
      Logger.shared.info("request path=\(router.path) attempt=\(attempt + 1)", category: .network)
      do {
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
          throw NetworkError.invalidResponse
        }
        
        let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1_000)
        Logger.shared.info("response path=\(router.path) status=\(httpResponse.statusCode) bytes=\(data.count) elapsed_ms=\(elapsedMs)", category: .network)

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
          logHTTPFailure(path: router.path, status: httpResponse.statusCode, data: data, elapsedMs: elapsedMs)
          let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Double($0) }
          throw APIError.rateLimited(retryAfter: retryAfter)
          
        case 400...499:
          logHTTPFailure(path: router.path, status: httpResponse.statusCode, data: data, elapsedMs: elapsedMs)
          let errorMessage = String(data: data, encoding: .utf8)
          throw APIError.clientError(statusCode: httpResponse.statusCode, message: errorMessage)
          
        case 500...599:
          logHTTPFailure(path: router.path, status: httpResponse.statusCode, data: data, elapsedMs: elapsedMs)
          throw APIError.serverError(statusCode: httpResponse.statusCode)
          
        default:
          logHTTPFailure(path: router.path, status: httpResponse.statusCode, data: data, elapsedMs: elapsedMs)
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
    
    let startedAt = Date()
    Logger.shared.info("request-data path=\(router.path)", category: .network)
    let (data, response) = try await session.data(for: urlRequest)
    
    guard let httpResponse = response as? HTTPURLResponse else {
      throw NetworkError.invalidResponse
    }

    let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1_000)
    Logger.shared.info("response-data path=\(router.path) status=\(httpResponse.statusCode) bytes=\(data.count) elapsed_ms=\(elapsedMs)", category: .network)
    
    switch httpResponse.statusCode {
    case 200...299:
      return data
    case 429:
      logHTTPFailure(path: router.path, status: httpResponse.statusCode, data: data, elapsedMs: elapsedMs)
      let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After").flatMap { Double($0) }
      throw APIError.rateLimited(retryAfter: retryAfter)
    case 400...499:
      logHTTPFailure(path: router.path, status: httpResponse.statusCode, data: data, elapsedMs: elapsedMs)
      let errorMessage = String(data: data, encoding: .utf8)
      throw APIError.clientError(statusCode: httpResponse.statusCode, message: errorMessage)
    case 500...599:
      logHTTPFailure(path: router.path, status: httpResponse.statusCode, data: data, elapsedMs: elapsedMs)
      throw APIError.serverError(statusCode: httpResponse.statusCode)
    default:
      logHTTPFailure(path: router.path, status: httpResponse.statusCode, data: data, elapsedMs: elapsedMs)
      throw APIError.invalidResponse
    }
  }

  private func logHTTPFailure(path: String, status: Int, data: Data, elapsedMs: Int) {
    Logger.shared.warning("response path=\(path) status=\(status) bytes=\(data.count) elapsed_ms=\(elapsedMs)", category: .network)

    guard Logger.shared.level.contains(.info) else { return }
    let limit = 16 * 1024
    let truncated = data.count > limit
    let body = String(decoding: data.prefix(limit), as: UTF8.self)
    Logger.shared.info("response-error-body path=\(path) status=\(status) truncated=\(truncated) body=\(body)", category: .network)
  }
}
