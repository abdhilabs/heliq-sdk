//
//  LoggingPlugin.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import OSLog

public protocol LoggingPluginProtocol: Sendable {
  func log(request: URLRequest)
  func log(response: URLResponse, data: Data?, error: Error?)
  func log(message: String, level: LogLevel)
}

public final class LoggingPlugin: LoggingPluginProtocol, @unchecked Sendable {
  private let logger: Logger
  private let category: LogCategory
  
  public init(logger: Logger = .shared, category: LogCategory = .network) {
    self.logger = logger
    self.category = category
  }
  
  public func log(request: URLRequest) {
    let message = """
        [REQUEST] \(request.httpMethod ?? "UNKNOWN") \(request.url?.absoluteString ?? "unknown")
        Headers: \(request.allHTTPHeaderFields?.description ?? "none")
        """
    
    switch request.httpMethod {
    case "GET":
      logger.debug(message, category: category)
    default:
      logger.info(message, category: category)
    }
  }
  
  public func log(response: URLResponse, data: Data?, error: Error?) {
    if let error = error {
      logger.error("[\(category.rawValue)] \(error.localizedDescription)", category: category)
      return
    }
    
    guard let httpResponse = response as? HTTPURLResponse else { return }
    
    let message = """
        [RESPONSE] \(httpResponse.statusCode) \(httpResponse.url?.absoluteString ?? "unknown")
        """
    
    if (200...299).contains(httpResponse.statusCode) {
      logger.debug(message, category: category)
    } else {
      logger.warn(message, category: category)
    }
  }
  
  public func log(message: String, level: LogLevel) {
    switch level {
    case .debug:
      logger.debug(message, category: category)
    case .info:
      logger.info(message, category: category)
    case .warn:
      logger.warn(message, category: category)
    case .error:
      logger.error(message, category: category)
    }
  }
}
