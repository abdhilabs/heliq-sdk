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
        queue.async { self.handlers[channel]?(payload) }

      case .data:
        break
      }
    } catch {
      Logger.shared.error("websocket-route-failed code=WEBSOCKET_ROUTE_FAILED", category: .webSocket)
    }
  }
  
  /// Performs the clear all handlers operation.
  public func clearAllHandlers() {
    queue.async {
      self.handlers.removeAll()
    }
  }
}
