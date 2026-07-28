//
//  SubscriptionManager.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines subscription channel values.
public enum SubscriptionChannel: Sendable, Hashable {
  /// The `allMids` option.
  case allMids
  /// The `l2Book` option.
  case l2Book(coin: String)
  /// The `trades` option.
  case trades(coin: String)
  /// The `userEvents` option.
  case userEvents
  /// The `userFills` option.
  case userFills
  /// The `candle` option.
  case candle(coin: String, interval: String)
  /// The `orderUpdates` option.
  case orderUpdates
  /// The `userFundings` option.
  case userFundings
  /// The `userNonFundingLedgerUpdates` option.
  case userNonFundingLedgerUpdates
  /// The `webData2` option.
  case webData2
  /// The `bbo` option.
  case bbo(coin: String)
  /// The `activeAssetCtx` option.
  case activeAssetCtx(coin: String)
  /// The `activeAssetData` option.
  case activeAssetData(coin: String)
  
  /// The channel name.
  public var channelName: String {
    switch self {
    case .allMids:
      return "allMids"
    case .l2Book:
      return "l2Book"
    case .trades:
      return "trades"
    case .userEvents:
      return "userEvents"
    case .userFills:
      return "userFills"
    case .candle:
      return "candle"
    case .orderUpdates:
      return "orderUpdates"
    case .userFundings:
      return "userFundings"
    case .userNonFundingLedgerUpdates:
      return "userNonFundingLedgerUpdates"
    case .webData2:
      return "webData2"
    case .bbo:
      return "bbo"
    case .activeAssetCtx:
      return "activeAssetCtx"
    case .activeAssetData:
      return "activeAssetData"
    }
  }
  
  /// The payload.
  public var payload: [String: Any]? {
    switch self {
    case .l2Book(let coin):
      return ["coin": coin]
    case .trades(let coin):
      return ["coin": coin]
    case .candle(let coin, let interval):
      return ["coin": coin, "interval": interval]
    case .bbo(let coin):
      return ["coin": coin]
    case .activeAssetCtx(let coin):
      return ["coin": coin]
    case .activeAssetData(let coin):
      return ["coin": coin]
    default:
      return nil
    }
  }
}

/// Provides subscription manager functionality.
public final class SubscriptionManager: @unchecked Sendable {
  private var activeSubscriptions: Set<SubscriptionChannel> = []
  private var activeRawSubscriptions: Set<HyperliquidWebSocketSubscription> = []
  private let queue = DispatchQueue(label: "com.heliqsdk.subscriptionmanager")
  private weak var webSocketService: WebSocketService?
  
  /// Creates a subscription manager.
  public init(webSocketService: WebSocketService? = nil) {
    self.webSocketService = webSocketService
  }
  
  /// Performs the subscribe operation.
  public func subscribe(to channel: SubscriptionChannel) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      queue.async {
        guard !self.activeSubscriptions.contains(channel) else {
          continuation.resume()
          return
        }
        self.activeSubscriptions.insert(channel)
        continuation.resume()
      }
    }
    
    guard let service = webSocketService else { return }
    
    try await service.subscribe(channel: channel.channelName, payload: channel.payload)
  }
  
  /// Performs the unsubscribe operation.
  public func unsubscribe(from channel: SubscriptionChannel) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      queue.async {
        guard self.activeSubscriptions.contains(channel) else {
          continuation.resume()
          return
        }
        self.activeSubscriptions.remove(channel)
        continuation.resume()
      }
    }
    
    guard let service = webSocketService else { return }
    
    try await service.unsubscribe(channel: channel.channelName, payload: channel.payload)
  }
  
  /// Performs the subscribe operation.
  public func subscribe(to subscription: HyperliquidWebSocketSubscription) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      queue.async {
        guard !self.activeRawSubscriptions.contains(subscription) else { continuation.resume(); return }
        self.activeRawSubscriptions.insert(subscription)
        continuation.resume()
      }
    }
    try await webSocketService?.subscribe(subscription)
  }

  /// Performs the unsubscribe operation.
  public func unsubscribe(from subscription: HyperliquidWebSocketSubscription) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      queue.async {
        guard self.activeRawSubscriptions.contains(subscription) else { continuation.resume(); return }
        self.activeRawSubscriptions.remove(subscription)
        continuation.resume()
      }
    }
    try await webSocketService?.unsubscribe(subscription)
  }

  /// Performs the is subscribed operation.
  public func isSubscribed(to subscription: HyperliquidWebSocketSubscription) -> Bool {
    queue.sync { activeRawSubscriptions.contains(subscription) }
  }

  /// Performs the unsubscribe all operation.
  public func unsubscribeAll() async throws {
    let (channels, rawSubscriptions): ([SubscriptionChannel], [HyperliquidWebSocketSubscription]) = await withCheckedContinuation { continuation in
      queue.async {
        let channels = Array(self.activeSubscriptions)
        let rawSubscriptions = Array(self.activeRawSubscriptions)
        self.activeSubscriptions.removeAll()
        self.activeRawSubscriptions.removeAll()
        continuation.resume(returning: (channels, rawSubscriptions))
      }
    }

    guard let service = webSocketService else { return }
    for channel in channels {
      try await service.unsubscribe(channel: channel.channelName)
    }
    for subscription in rawSubscriptions {
      try await service.unsubscribe(subscription)
    }
  }
  
  /// Performs the is subscribed operation.
  public func isSubscribed(to channel: SubscriptionChannel) -> Bool {
    var result = false
    queue.sync {
      result = activeSubscriptions.contains(channel)
    }
    return result
  }
  
  /// Performs the get active subscriptions operation.
  public func getActiveSubscriptions() -> [SubscriptionChannel] {
    var result: [SubscriptionChannel] = []
    queue.sync {
      result = Array(activeSubscriptions)
    }
    return result
  }
}
