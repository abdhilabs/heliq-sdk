//
//  WebSocketMessageRouter.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines requirements for web socket message router delegate implementations.
public protocol WebSocketMessageRouterDelegate: AnyObject, Sendable {
  /// Performs the did receive subscription operation.
  func didReceiveSubscription(_ channel: String, data: Data)
  /// Performs the did receive unsubscription operation.
  func didReceiveUnsubscription(_ channel: String)
}

/// Provides web socket message router functionality.
public final class WebSocketMessageRouter: @unchecked Sendable {
  private let parser: WebSocketMessageParser
  private let perpsLock = NSLock()
  private var perpsHandlers: [HyperliquidWebSocketSubscription: (String, @Sendable (Data) -> Void)] = [:]
  private var handlers: [String: @Sendable (Data) -> Void] = [:]
  private let queue = DispatchQueue(label: "com.heliqsdk.router")
  
  /// Public SDK API.
  public weak var delegate: (any WebSocketMessageRouterDelegate)?
  
  /// Creates a web socket message router.
  public init(parser: WebSocketMessageParser = WebSocketMessageParser()) {
    self.parser = parser
  }
  
  /// Performs the register handler operation.
  public func registerHandler(
    _ handler: @escaping @Sendable (Data) -> Void,
    for channel: String
  ) {
    queue.async {
      self.handlers[channel] = handler
    }
  }
  
  /// Performs the unregister handler operation.
  public func unregisterHandler(for channel: String) {
    queue.async {
      self.handlers.removeValue(forKey: channel)
    }
  }
  
  /// Performs the route operation.
  public func route(_ data: Data) {
    do {
      let message = try parser.parse(data)
      
      switch message {
      case .subscribe(let channel, let payload):
        if let payloadData = payload.flatMap({ try? JSONSerialization.data(withJSONObject: $0) }) {
          delegate?.didReceiveSubscription(channel, data: payloadData)
        }
        
        queue.async {
          self.handlers[channel]?(data)
        }
        
      case .unsubscribe(let channel):
        delegate?.didReceiveUnsubscription(channel)
        
        queue.async {
          self.handlers.removeValue(forKey: channel)
        }
        
      case .channelData(let channel, let payload):
        queue.async {
          self.handlers[channel]?(payload)
          for handler in self.perpsHandlers(for: channel) { handler(data) }
        }

      case .data:
        break
      }
    } catch {
      Logger.shared.error("websocket-route-failed code=WEBSOCKET_ROUTE_FAILED", category: .webSocket)
    }
  }
  
  /// Registers a full-envelope handler and rejects subscriptions that cannot be routed
  /// unambiguously.
  func registerPerpsEnvelopeHandler(subscription: HyperliquidWebSocketSubscription, channel: String,
    handler: @escaping @Sendable (Data) -> Void) throws {
    perpsLock.lock(); defer { perpsLock.unlock() }
    for (other, entry) in perpsHandlers where entry.0 == channel && other != subscription {
      let unlabelled = ["allMids", "notification", "user"].contains(channel)
      let ambiguousBook = channel == "l2Book" && other.parameters["coin"] == subscription.parameters["coin"]
      guard !unlabelled, !ambiguousBook else {
        throw ValidationError.malformedData(reason: "This feed does not identify multiple subscription sources; use separate routers/connections")
      }
    }
    perpsHandlers[subscription] = (channel, handler)
  }

  /// Removes the local full-envelope handler for an exact subscription.
  func unregisterPerpsEnvelopeHandler(_ subscription: HyperliquidWebSocketSubscription) {
    perpsLock.lock(); defer { perpsLock.unlock() }
    perpsHandlers.removeValue(forKey: subscription)
  }

  /// Snapshots the matching envelope handlers while holding the registry lock.
  private func perpsHandlers(for channel: String) -> [@Sendable (Data) -> Void] {
    perpsLock.lock(); defer { perpsLock.unlock() }
    return perpsHandlers.values.filter { $0.0 == channel }.map(\.1)
  }

  /// Performs the clear all handlers operation.
  public func clearAllHandlers() {
    queue.async {
      self.handlers.removeAll()
      self.perpsLock.lock(); self.perpsHandlers.removeAll(); self.perpsLock.unlock()
    }
  }
}
