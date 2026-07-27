//
//  APIRouter.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines httpmethod values.
public enum HTTPMethod: String, Sendable {
  /// The `get` option.
  case get = "GET"
  /// The `post` option.
  case post = "POST"
  /// The `put` option.
  case put = "PUT"
  /// The `delete` option.
  case delete = "DELETE"
}

/// Defines requirements for apirouter protocol implementations.
public protocol APIRouterProtocol: Sendable {
  /// The path.
  var path: String { get }
  /// The method.
  var method: HTTPMethod { get }
  /// The headers.
  var headers: [String: String]? { get }
  /// The body.
  var body: Data? { get }
  /// The query items.
  var queryItems: [URLQueryItem]? { get }
}

/// Adds HeliqSDK conveniences to `APIRouterProtocol`.
public extension APIRouterProtocol {
  /// The headers.
  var headers: [String: String]? { nil }
  /// The body.
  var body: Data? { nil }
  /// The query items.
  var queryItems: [URLQueryItem]? { nil }
  
  /// Performs the url request operation.
  func urlRequest(baseURL: String) -> URLRequest? {
    guard var components = URLComponents(string: baseURL + path) else { return nil }
    
    if let queryItems = queryItems {
      components.queryItems = queryItems
    }
    
    guard let url = components.url else { return nil }
    
    var request = URLRequest(url: url)
    request.httpMethod = method.rawValue
    request.httpBody = body
    
    if let headers = headers {
      for (key, value) in headers {
        request.setValue(value, forHTTPHeaderField: key)
      }
    }
    
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    return request
  }
}
