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

public struct LogLevel: OptionSet, Sendable, Hashable {
  public let rawValue: Int

  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let error = LogLevel(rawValue: 1 << 0)
  public static let warning = LogLevel(rawValue: 1 << 1)
  public static let info = LogLevel(rawValue: 1 << 2)

  public static let disabled: LogLevel = []
  public static let debug: LogLevel = [.error, .warning]
  public static let verbose: LogLevel = [.error, .warning, .info]
}

public final class Logger: @unchecked Sendable {
  public static let shared = Logger()

  private let subsystem = "com.heliq.SDK"
  private let lock = NSLock()
  private var configuredLevel: LogLevel = .disabled

  private init() {}

  public var level: LogLevel {
    lock.lock()
    defer { lock.unlock() }
    return configuredLevel
  }

  func configure(_ level: LogLevel) {
    lock.lock()
    configuredLevel = level
    lock.unlock()
  }

  public func info(_ message: String, category: LogCategory = .general) {
    log(message, severity: .info, category: category)
  }

  public func warning(_ message: String, category: LogCategory = .general) {
    log(message, severity: .warning, category: category)
  }

  public func error(_ message: String, category: LogCategory = .general) {
    log(message, severity: .error, category: category)
  }

  private func log(_ message: String, severity: LogLevel, category: LogCategory) {
    guard level.contains(severity) else { return }

    let logger = os.Logger(subsystem: subsystem, category: category.rawValue)
    switch severity {
    case .info:
      logger.info("\(message, privacy: .public)")
    case .warning:
      logger.warning("\(message, privacy: .public)")
    case .error:
      logger.error("\(message, privacy: .public)")
    default:
      break
    }
  }
}
