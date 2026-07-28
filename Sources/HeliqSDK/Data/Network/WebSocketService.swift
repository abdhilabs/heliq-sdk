//
//  WebSocketService.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents lifecycle and message events emitted by a WebSocket connection.
public enum WebSocketEvent: Sendable {
  /// The connection state changed.
  case stateChanged(WebSocketState)
  /// A message arrived from the server.
  case message(Data)
  /// A transport error occurred.
  case failed(String)
}

/// Defines WebSocket connection states.
public enum WebSocketState: Sendable, Equatable {
  /// The connection is inactive.
  case disconnected
  /// A connection attempt is in progress.
  case connecting
  /// The socket is active.
  case connected
  /// A delayed reconnect is pending.
  case reconnecting
}

/// Actor-owned WebSocket transport.
///
/// Events are delivered on this actor, not on `MainActor`. UI clients must explicitly
/// hop to `MainActor` before mutating view state.
public actor WebSocketService {
  /// Receives lifecycle, message, and error events.
  public typealias EventHandler = @Sendable (WebSocketEvent) -> Void

  private let url: URL
  private let session: URLSession
  private let reconnectPolicy: ReconnectPolicy
  private var task: URLSessionWebSocketTask?
  private var connectionTask: Task<Void, Never>?
  private var receiveTask: Task<Void, Never>?
  private var reconnectTask: Task<Void, Never>?
  private var handler: EventHandler?
  private var state: WebSocketState = .disconnected
  private var generation = 0
  private var consecutiveFailures = 0
  private var reconnectEnabled = true

  /// Creates a WebSocket transport.
  public init(
    url: URL,
    session: URLSession = .shared,
    reconnectPolicy: ReconnectPolicy = .default,
    eventHandler: EventHandler? = nil
  ) {
    self.url = url
    self.session = session
    self.reconnectPolicy = reconnectPolicy
    handler = eventHandler
  }

  /// Replaces the event handler.
  public func setEventHandler(_ handler: EventHandler?) {
    self.handler = handler
  }

  /// Starts a connection attempt.
  public func connect() {
    guard state == .disconnected else { return }

    reconnectEnabled = true
    startConnection()
  }

  /// Stops the connection and cancels all pending recovery work.
  public func disconnect() {
    reconnectEnabled = false
    generation += 1
    reconnectTask?.cancel()
    reconnectTask = nil
    connectionTask?.cancel()
    connectionTask = nil
    receiveTask?.cancel()
    receiveTask = nil
    task?.cancel(with: .normalClosure, reason: nil)
    task = nil
    consecutiveFailures = 0
    transition(to: .disconnected)
  }

  /// Sends binary data through the active connection.
  public func send(_ data: Data) async throws {
    guard let task, state == .connected else {
      throw NetworkError.invalidResponse
    }
    try await task.send(.data(data))
  }

  /// Sends text through the active connection.
  public func send(_ message: String) async throws {
    guard let task, state == .connected else {
      throw NetworkError.invalidResponse
    }
    try await task.send(.string(message))
  }

  /// Subscribes to a channel.
  public func subscribe(
    channel: String,
    payload: [String: Any]? = nil
  ) async throws {
    var subscription: [String: Any] = ["type": channel]
    payload?.forEach { subscription[$0.key] = $0.value }
    try await sendJSON(["method": "subscribe", "subscription": subscription])
  }

  /// Unsubscribes from a channel.
  public func unsubscribe(
    channel: String,
    payload: [String: Any]? = nil
  ) async throws {
    var subscription: [String: Any] = ["type": channel]
    payload?.forEach { subscription[$0.key] = $0.value }
    try await sendJSON(["method": "unsubscribe", "subscription": subscription])
  }

  /// Subscribes using the typed Hyperliquid subscription model.
  public func subscribe(
    _ subscription: HyperliquidWebSocketSubscription
  ) async throws {
    try await sendJSON([
      "method": "subscribe",
      "subscription": subscription.payload()
    ])
  }

  /// Unsubscribes using the typed Hyperliquid subscription model.
  public func unsubscribe(
    _ subscription: HyperliquidWebSocketSubscription
  ) async throws {
    try await sendJSON([
      "method": "unsubscribe",
      "subscription": subscription.payload()
    ])
  }

  /// Posts a typed WebSocket request.
  public func post(_ request: HyperliquidWebSocketPostRequest) async throws {
    try await sendJSON(request.object())
  }

  private func startConnection() {
    let connectionGeneration = generation
    transition(to: .connecting)
    Logger.shared.info("websocket lifecycle=connect-start", category: .webSocket)

    let task = session.webSocketTask(with: url)
    self.task = task
    task.resume()
    confirmConnection(for: task, generation: connectionGeneration)
    receiveMessages(for: task, generation: connectionGeneration)
  }

  private func confirmConnection(
    for task: URLSessionWebSocketTask,
    generation: Int
  ) {
    connectionTask?.cancel()
    connectionTask = Task { [weak self] in
      guard let self else { return }

      do {
        try await self.waitForPong(from: task)
        await self.markConnected(task: task, generation: generation)
      } catch is CancellationError {
        return
      } catch {
        await self.handleDisconnection(
          error: error,
          task: task,
          generation: generation
        )
      }
    }
  }

  private func waitForPong(from task: URLSessionWebSocketTask) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      task.sendPing { error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume()
        }
      }
    }
  }

  private func markConnected(
    task connectedTask: URLSessionWebSocketTask,
    generation: Int
  ) {
    guard isCurrent(task: connectedTask, generation: generation),
          state == .connecting else {
      return
    }

    consecutiveFailures = 0
    transition(to: .connected)
    Logger.shared.info("websocket lifecycle=connected", category: .webSocket)
  }

  private func receiveMessages(
    for task: URLSessionWebSocketTask,
    generation: Int
  ) {
    receiveTask?.cancel()
    receiveTask = Task { [weak self] in
      guard let self else { return }

      do {
        while !Task.isCancelled {
          let message = try await task.receive()
          guard await self.isCurrent(task: task, generation: generation) else {
            return
          }
          await self.handle(message, task: task, generation: generation)
        }
      } catch is CancellationError {
        return
      } catch {
        await self.handleDisconnection(
          error: error,
          task: task,
          generation: generation
        )
      }
    }
  }

  private func isCurrent(
    task: URLSessionWebSocketTask,
    generation: Int
  ) -> Bool {
    self.task === task && self.generation == generation && reconnectEnabled
  }

  private func handle(
    _ message: URLSessionWebSocketTask.Message,
    task messageTask: URLSessionWebSocketTask,
    generation: Int
  ) {
    guard isCurrent(task: messageTask, generation: generation) else { return }

    switch message {
    case .data(let data):
      handler?(.message(data))
    case .string(let text):
      handler?(.message(Data(text.utf8)))
    @unknown default:
      break
    }
  }

  private func handleDisconnection(
    error: Error,
    task failedTask: URLSessionWebSocketTask,
    generation: Int
  ) {
    guard self.task === failedTask,
          self.generation == generation,
          reconnectEnabled else {
      return
    }

    connectionTask?.cancel()
    connectionTask = nil
    receiveTask?.cancel()
    receiveTask = nil
    task = nil
    consecutiveFailures += 1
    handler?(.failed("WEBSOCKET_CONNECTION_FAILED"))
    scheduleReconnect(for: generation)
  }

  private func scheduleReconnect(for generation: Int) {
    guard reconnectEnabled,
          reconnectTask == nil,
          consecutiveFailures <= reconnectPolicy.maxAttempts else {
      transition(to: .disconnected)
      return
    }

    transition(to: .reconnecting)
    let delay = reconnectPolicy.delay(forFailureCount: consecutiveFailures)
    reconnectTask = Task { [weak self] in
      do {
        try await Task.sleep(for: .seconds(delay))
      } catch {
        return
      }

      guard let self else { return }
      await self.reconnect(after: generation)
    }
  }

  private func reconnect(after generation: Int) {
    reconnectTask = nil
    guard self.generation == generation, reconnectEnabled else { return }
    transition(to: .disconnected)
    startConnection()
  }

  private func sendJSON(_ object: [String: Any]) async throws {
    let data = try JSONSerialization.data(withJSONObject: object)
    guard let text = String(data: data, encoding: .utf8) else {
      throw NetworkError.invalidResponse
    }
    try await send(text)
  }

  private func transition(to state: WebSocketState) {
    self.state = state
    handler?(.stateChanged(state))
  }
}

/// Controls automatic WebSocket reconnect attempts.
public struct ReconnectPolicy: Sendable, Equatable {
  /// Maximum reconnect attempts after a transport failure.
  public let maxAttempts: Int
  /// Initial delay before the first reconnect attempt.
  public let initialDelay: TimeInterval
  /// Maximum delay after exponential backoff.
  public let maximumDelay: TimeInterval

  /// Default reconnect policy.
  public static let `default` = ReconnectPolicy(
    maxAttempts: 5,
    initialDelay: 1,
    maximumDelay: 30
  )

  /// Creates a reconnect policy.
  public init(
    maxAttempts: Int,
    initialDelay: TimeInterval,
    maximumDelay: TimeInterval
  ) {
    self.maxAttempts = maxAttempts
    self.initialDelay = initialDelay
    self.maximumDelay = maximumDelay
  }

  func delay(forFailureCount failureCount: Int) -> TimeInterval {
    min(initialDelay * pow(2, Double(failureCount - 1)), maximumDelay)
  }
}
