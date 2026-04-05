//
//  WebSocketMessageRouter.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public protocol WebSocketMessageRouterDelegate: AnyObject, Sendable {
  func didReceiveSubscription(_ channel: String, data: Data)
  func didReceiveUnsubscription(_ channel: String)
}

public final class WebSocketMessageRouter: @unchecked Sendable {
  private let parser: WebSocketMessageParser
  private var handlers: [String: (Data) -> Void] = [:]
  private let queue = DispatchQueue(label: "com.heliqsdk.router")
  
  public weak var delegate: (any WebSocketMessageRouterDelegate)?
  
  public init(parser: WebSocketMessageParser = WebSocketMessageParser()) {
    self.parser = parser
  }
  
  public func registerHandler(_ handler: @escaping (Data) -> Void, for channel: String) {
    queue.async {
      self.handlers[channel] = handler
    }
  }
  
  public func unregisterHandler(for channel: String) {
    queue.async {
      self.handlers.removeValue(forKey: channel)
    }
  }
  
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
        
      case .data:
        break
      }
    } catch {
      Logger.shared.error("Failed to route WebSocket message: \(error.localizedDescription)", category: .webSocket)
    }
  }
  
  public func clearAllHandlers() {
    queue.async {
      self.handlers.removeAll()
    }
  }
}
