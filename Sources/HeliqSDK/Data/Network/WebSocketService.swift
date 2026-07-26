//
//  WebSocketService.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum WebSocketState: Sendable {
  case disconnected
  case connecting
  case connected
  case reconnecting
}

public protocol WebSocketServiceDelegate: AnyObject, Sendable {
  func webSocketDidConnect()
  func webSocketDidDisconnect(error: Error?)
  func webSocketDidReceiveMessage(_ message: Data)
  func webSocketDidReceiveError(_ error: Error)
}

public final class WebSocketService: NSObject, @unchecked Sendable {
  private var webSocketTask: URLSessionWebSocketTask?
  private var urlSession: URLSession?
  private let url: URL
  private weak var _delegate: (any WebSocketServiceDelegate)?
  private var state: WebSocketState = .disconnected
  private let reconnectHandler: WebSocketReconnectionHandler
  private let healthMonitor: WebSocketHealthMonitor
  
  public weak var webSocketDelegate: (any WebSocketServiceDelegate)? {
    get { _delegate }
    set { _delegate = newValue }
  }
  
  public init(url: URL, delegate: (any WebSocketServiceDelegate)? = nil) {
    self.url = url
    self._delegate = delegate
    self.reconnectHandler = WebSocketReconnectionHandler()
    self.healthMonitor = WebSocketHealthMonitor()
    super.init()
    self.urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
  }
  
  public func connect() {
    guard state == .disconnected else { return }

    state = .connecting

    if urlSession == nil {
      urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
    }

    webSocketTask = urlSession?.webSocketTask(with: url)
    webSocketTask?.delegate = self
    webSocketTask?.resume()
    receiveMessage()
  }
  
  public func disconnect() {
    state = .disconnected
    webSocketTask?.cancel(with: .normalClosure, reason: nil)
    webSocketTask = nil
    urlSession?.invalidateAndCancel()
    urlSession = nil
  }
  
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
  
public func subscribe(channel: String, payload: [String: Any]? = nil) throws {
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

  public func unsubscribe(channel: String) throws {
    let unsubscription: [String: Any] = [
      "method": "unsubscribe",
      "subscription": ["type": channel]
    ]

    guard let data = try? JSONSerialization.data(withJSONObject: unsubscription),
          let jsonString = String(data: data, encoding: .utf8) else {
      throw NetworkError.invalidResponse
    }

    try send(jsonString)
  }
  
  public func subscribe(_ subscription: HyperliquidWebSocketSubscription) throws {
    let message: [String: Any] = ["method": "subscribe", "subscription": subscription.payload()]
    let data = try JSONSerialization.data(withJSONObject: message)
    guard let text = String(data: data, encoding: .utf8) else { throw NetworkError.invalidResponse }
    try send(text)
  }

  public func unsubscribe(_ subscription: HyperliquidWebSocketSubscription) throws {
    let message: [String: Any] = ["method": "unsubscribe", "subscription": subscription.payload()]
    let data = try JSONSerialization.data(withJSONObject: message)
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
  public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
    state = .connected
    healthMonitor.recordConnection()
    _delegate?.webSocketDidConnect()
  }
  
  public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
    handleDisconnection(error: nil)
  }
}

extension WebSocketService: URLSessionTaskDelegate {
  public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    if let error = error {
      _delegate?.webSocketDidReceiveError(error)
      handleDisconnection(error: error)
    }
  }
}
