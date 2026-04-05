//
//  WebSocketHealthMonitor.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class WebSocketHealthMonitor: @unchecked Sendable {
  private var lastPingTime: Date?
  private var lastPongTime: Date?
  private var isHealthy: Bool = true
  private let pingInterval: TimeInterval
  private let lock = NSLock()
  
  public init(pingInterval: TimeInterval = Constants.WebSocket.pingInterval) {
    self.pingInterval = pingInterval
  }
  
  public func recordPing() {
    lock.lock()
    defer { lock.unlock() }
    lastPingTime = Date()
  }
  
  public func recordPong() {
    lock.lock()
    defer { lock.unlock() }
    lastPongTime = Date()
    isHealthy = true
  }
  
  public func recordConnection() {
    lock.lock()
    defer { lock.unlock() }
    isHealthy = true
    lastPingTime = nil
    lastPongTime = nil
  }
  
  public func recordDisconnection() {
    lock.lock()
    defer { lock.unlock() }
    isHealthy = false
  }
  
  public func shouldReportUnhealthy() -> Bool {
    lock.lock()
    defer { lock.unlock() }
    
    guard let lastPing = lastPingTime else { return false }
    
    let timeSinceLastPing = Date().timeIntervalSince(lastPing)
    return timeSinceLastPing > pingInterval * 2 && !isHealthy
  }
  
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

public struct HealthStatus: Sendable {
  public let isHealthy: Bool
  public let lastPingTime: Date?
  public let lastPongTime: Date?
  public let pingInterval: TimeInterval
  
  public var timeSinceLastPong: TimeInterval? {
    guard let lastPong = lastPongTime else { return nil }
    return Date().timeIntervalSince(lastPong)
  }
}
