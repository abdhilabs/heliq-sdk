//
//  Logger.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import OSLog

public enum LogCategory: String, Sendable {
  case network = "Network"
  case webSocket = "WebSocket"
  case signing = "Signing"
  case cache = "Cache"
  case general = "General"
}

public enum LogLevel: String, Sendable {
  case debug = "DEBUG"
  case info = "INFO"
  case warn = "WARN"
  case error = "ERROR"
}

public struct Logger: Sendable {
  public static let shared = Logger()
  
  private let subsystem = "com.heliq.SDK"
  
  private init() {}
  
  public func debug(_ message: String, category: LogCategory = .general) {
    log(message, level: .debug, category: category)
  }
  
  public func info(_ message: String, category: LogCategory = .general) {
    log(message, level: .info, category: category)
  }
  
  public func warn(_ message: String, category: LogCategory = .general) {
    log(message, level: .warn, category: category)
  }
  
  public func error(_ message: String, category: LogCategory = .general) {
    log(message, level: .error, category: category)
  }
  
  public func error(_ error: any Error, category: LogCategory = .general) {
    log(error.localizedDescription, level: .error, category: category)
  }
  
  private func log(_ message: String, level: LogLevel, category: LogCategory) {
    let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
    switch level {
    case .debug:
      logger.debug("\(message, privacy: .public)")
    case .info:
      logger.info("\(message, privacy: .public)")
    case .warn:
      logger.warning("\(message, privacy: .public)")
    case .error:
      logger.error("\(message, privacy: .public)")
    }
  }
}
