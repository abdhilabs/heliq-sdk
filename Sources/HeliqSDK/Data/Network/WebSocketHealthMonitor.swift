//
//  WebSocketHealthMonitor.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Provides web socket health monitor functionality.
public final class WebSocketHealthMonitor: @unchecked Sendable {
  private var lastPingTime: Date?
  private var lastPongTime: Date?
  private var isHealthy: Bool = true
  private let pingInterval: TimeInterval
  private let lock = NSLock()
  
  /// Creates a web socket health monitor.
  public init(pingInterval: TimeInterval = Constants.WebSocket.pingInterval) {
    self.pingInterval = pingInterval
  }
  
  /// Performs the record ping operation.
  public func recordPing() {
    lock.lock()
    defer { lock.unlock() }
    lastPingTime = Date()
  }
  
  /// Performs the record pong operation.
  public func recordPong() {
    lock.lock()
    defer { lock.unlock() }
    lastPongTime = Date()
    isHealthy = true
  }
  
  /// Performs the record connection operation.
  public func recordConnection() {
    lock.lock()
    defer { lock.unlock() }
    isHealthy = true
    lastPingTime = nil
    lastPongTime = nil
  }
  
  /// Performs the record disconnection operation.
  public func recordDisconnection() {
    lock.lock()
    defer { lock.unlock() }
    isHealthy = false
  }
  
  /// Performs the should report unhealthy operation.
  public func shouldReportUnhealthy() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    
    guard let lastPing = lastPingTime else { return false }
    
    let timeSinceLastPing = Date().timeIntervalSince(lastPing)
    return timeSinceLastPing > pingInterval * 2 && !isHealthy
  }
  
  /// Performs the get health status operation.
  public func getHealthStatus() -> HealthStatus {
    lock.lock()
    defer { lock.unlock() }
    
    return HealthStatus(
      isHealthy: isHealthy,
      lastPingTime: lastPingTime,
      lastPongTime: lastPongTime,
      pingInterval: pingInterval
    )
  }
}

/// Represents health status data.
public struct HealthStatus: Sendable {
  /// The is healthy.
  public let isHealthy: Bool
  /// The last ping time.
  public let lastPingTime: Date?
  /// The last pong time.
  public let lastPongTime: Date?
  /// The ping interval.
  public let pingInterval: TimeInterval
  
  /// The time since last pong.
  public var timeSinceLastPong: TimeInterval? {
    guard let lastPong = lastPongTime else { return nil }
    return Date().timeIntervalSince(lastPong)
  }
}
