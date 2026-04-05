//
//  APIRouter.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum HTTPMethod: String, Sendable {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
}

public protocol APIRouterProtocol: Sendable {
  var path: String { get }
  var method: HTTPMethod { get }
  var headers: [String: String]? { get }
  var body: Data? { get }
  var queryItems: [URLQueryItem]? { get }
}

public extension APIRouterProtocol {
  var headers: [String: String]? { nil }
  var body: Data? { nil }
  var queryItems: [URLQueryItem]? { nil }
  
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
