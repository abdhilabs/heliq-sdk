//
//  Logger.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import OSLog

/// Categories used to route SDK log messages.
public enum LogCategory: String, Sendable {
  /// HTTP networking messages.
  case network = "Network"
  /// WebSocket messages.
  case webSocket = "WebSocket"
  /// Signing-operation messages.
  case signing = "Signing"
  /// Cache-operation messages.
  case cache = "Cache"
  /// General SDK messages.
  case general = "General"
}

/// Selects which SDK log severities are emitted.
public struct LogLevel: OptionSet, Sendable, Hashable {
  /// Bitset representation of the selected severities.
  public let rawValue: Int

  /// Creates a log level from a raw bitset.
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  /// Enables error messages.
  public static let error = LogLevel(rawValue: 1 << 0)
  /// Enables warning messages.
  public static let warning = LogLevel(rawValue: 1 << 1)
  /// Enables informational messages.
  public static let info = LogLevel(rawValue: 1 << 2)

  /// Disables all SDK logging.
  public static let disabled: LogLevel = []
  /// Enables error and warning messages.
  public static let debug: LogLevel = [.error, .warning]
  /// Enables error, warning, and informational messages.
  public static let verbose: LogLevel = [.error, .warning, .info]
}

/// Thread-safe logger for SDK diagnostic messages.
public final class Logger: @unchecked Sendable {
  /// Shared SDK logger.
  public static let shared = Logger()

  private let subsystem = "com.heliq.SDK"
  private let lock = NSLock()
  private var configuredLevel: LogLevel = .disabled

  private init() {}

  /// Currently configured logging level.
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

  /// Logs an informational message.
  public func info(_ message: String, category: LogCategory = .general) {
    log(message, severity: .info, category: category)
  }

  /// Logs a warning message.
  public func warning(_ message: String, category: LogCategory = .general) {
    log(message, severity: .warning, category: category)
  }

  /// Logs an error message.
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
