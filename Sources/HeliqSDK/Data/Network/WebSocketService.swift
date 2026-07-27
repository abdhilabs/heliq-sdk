//
//  WebSocketService.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines web socket state values.
public enum WebSocketState: Sendable {
  /// The `disconnected` option.
  case disconnected
  /// The `connecting` option.
  case connecting
  /// The `connected` option.
  case connected
  /// The `reconnecting` option.
  case reconnecting
}

/// Defines requirements for web socket service delegate implementations.
public protocol WebSocketServiceDelegate: AnyObject, Sendable {
  /// Performs the web socket did connect operation.
  func webSocketDidConnect()
  /// Performs the web socket did disconnect operation.
  func webSocketDidDisconnect(error: Error?)
  /// Performs the web socket did receive message operation.
  func webSocketDidReceiveMessage(_ message: Data)
  /// Performs the web socket did receive error operation.
  func webSocketDidReceiveError(_ error: Error)
}

/// Provides web socket service functionality.
public final class WebSocketService: NSObject, @unchecked Sendable {
  private var webSocketTask: URLSessionWebSocketTask?
  private var urlSession: URLSession?
  private let url: URL
  private weak var _delegate: (any WebSocketServiceDelegate)?
  private var state: WebSocketState = .disconnected
  private let reconnectHandler: WebSocketReconnectionHandler
  private let healthMonitor: WebSocketHealthMonitor
  
  /// Public SDK API.
  public weak var webSocketDelegate: (any WebSocketServiceDelegate)? {
    get { _delegate }
    set { _delegate = newValue }
  }
  
  /// Creates a web socket service.
  public init(url: URL, delegate: (any WebSocketServiceDelegate)? = nil) {
    self.url = url
    self._delegate = delegate
    self.reconnectHandler = WebSocketReconnectionHandler()
    self.healthMonitor = WebSocketHealthMonitor()
    super.init()
    self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
  }
  
  /// Performs the connect operation.
  public func connect() {
    guard state == .disconnected else { return }

    Logger.shared.info("websocket lifecycle=connect-start", category: .webSocket)
    state = .connecting

    if urlSession == nil {
      urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    webSocketTask = urlSession?.webSocketTask(with: url)
    webSocketTask?.delegate = self
    webSocketTask?.resume()
    receiveMessage()
  }
  
  /// Performs the disconnect operation.
  public func disconnect() {
    Logger.shared.info("websocket lifecycle=disconnect", category: .webSocket)
    state = .disconnected
    webSocketTask?.cancel(with: .normalClosure, reason: nil)
    webSocketTask = nil
    urlSession?.invalidateAndCancel()
    urlSession = nil
  }
  
  /// Performs the send operation.
  public func send(_ data: Data) throws {
    guard state == .connected || state == .connecting else {
      throw NetworkError.invalidResponse
    }
    let message = URLSessionWebSocketTask.Message.data(data)
    webSocketTask?.send(message) { [weak self] error in
      if let error = error {
        self?._delegate?.webSocketDidReceiveError(error)
      }
    }
  }
  
  /// Performs the send operation.
  public func send(_ message: String) throws {
    guard state == .connected || state == .connecting else {
      throw NetworkError.invalidResponse
    }
    let message = URLSessionWebSocketTask.Message.string(message)
    webSocketTask?.send(message) { [weak self] error in
      if let error = error {
        self?._delegate?.webSocketDidReceiveError(error)
      }
    }
  }
  
  /// Performs the subscribe operation.
  public func subscribe(channel: String, payload: [String: Any]? = nil) throws {
    Logger.shared.info("websocket lifecycle=subscribe", category: .webSocket)
    var subscription: [String: Any] = [
      "method": "subscribe"
    ]

    var subscriptionData: [String: Any] = ["type": channel]
    if let payload = payload {
      for (key, value) in payload {
        subscriptionData[key] = value
      }
    }
    subscription["subscription"] = subscriptionData

    guard let data = try? JSONSerialization.data(withJSONObject: subscription),
          let jsonString = String(data: data, encoding: .utf8) else {
      throw NetworkError.invalidResponse
    }

    try send(jsonString)
  }

  /// Performs the unsubscribe operation.
  public func unsubscribe(channel: String, payload: [String: Any]? = nil) throws {
    var subscription: [String: Any] = ["type": channel]
    if let payload { for (key, value) in payload { subscription[key] = value } }
    let unsubscription: [String: Any] = ["method": "unsubscribe", "subscription": subscription]

    guard let data = try? JSONSerialization.data(withJSONObject: unsubscription),
          let jsonString = String(data: data, encoding: .utf8) else {
      throw NetworkError.invalidResponse
    }

    try send(jsonString)
  }
  
  /// Performs the subscribe operation.
  public func subscribe(_ subscription: HyperliquidWebSocketSubscription) throws {
    let message: [String: Any] = ["method": "subscribe", "subscription": subscription.payload()]
    let data = try JSONSerialization.data(withJSONObject: message)
    guard let text = String(data: data, encoding: .utf8) else { throw NetworkError.invalidResponse }
    try send(text)
  }

  /// Performs the unsubscribe operation.
  public func unsubscribe(_ subscription: HyperliquidWebSocketSubscription) throws {
    let message: [String: Any] = ["method": "unsubscribe", "subscription": subscription.payload()]
    let data = try JSONSerialization.data(withJSONObject: message)
    guard let text = String(data: data, encoding: .utf8) else { throw NetworkError.invalidResponse }
    try send(text)
  }

  /// Performs the post operation.
  public func post(_ request: HyperliquidWebSocketPostRequest) throws {
    let data = try JSONSerialization.data(withJSONObject: request.object())
    guard let text = String(data: data, encoding: .utf8) else { throw NetworkError.invalidResponse }
    try send(text)
  }

  private func receiveMessage() {
    webSocketTask?.receive { [weak self] result in
      guard let self = self else { return }
      
      switch result {
      case .success(let message):
        switch message {
        case .string(let text):
          if let data = text.data(using: .utf8) {
            self._delegate?.webSocketDidReceiveMessage(data)
          }
        case .data(let data):
          self._delegate?.webSocketDidReceiveMessage(data)
        @unknown default:
          break
        }
        self.receiveMessage()
        
      case .failure(let error):
        self._delegate?.webSocketDidReceiveError(error)
        self.handleDisconnection(error: error)
      }
    }
  }
  
  private func handleDisconnection(error: Error?) {
    Logger.shared.warning("websocket lifecycle=disconnected reason=\(error == nil ? "closed" : "error")", category: .webSocket)
    state = .disconnected
    _delegate?.webSocketDidDisconnect(error: error)
    
    Task { [weak self] in
      guard let self = self else { return }
      let shouldReconnect = await self.reconnectHandler.shouldReconnect()
      if shouldReconnect {
        self.state = .reconnecting
        await self.reconnectHandler.scheduleReconnect()
        await MainActor.run {
          self.connect()
        }
      }
    }
  }
}

extension WebSocketService: URLSessionWebSocketDelegate {
  /// Performs the url session operation.
  public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
    Logger.shared.info("websocket lifecycle=connected", category: .webSocket)
    state = .connected
    healthMonitor.recordConnection()
    _delegate?.webSocketDidConnect()
  }
  
  /// Performs the url session operation.
  public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    handleDisconnection(error: nil)
  }
}

extension WebSocketService: URLSessionTaskDelegate {
  /// Performs the url session operation.
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      _delegate?.webSocketDidReceiveError(error)
      handleDisconnection(error: error)
    }
  }
}
