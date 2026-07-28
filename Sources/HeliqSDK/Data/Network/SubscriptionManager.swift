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
  private var pendingSubscriptions: Set<SubscriptionChannel> = []
  private var activeRawSubscriptions: Set<HyperliquidWebSocketSubscription> = []
  private var pendingRawSubscriptions: Set<HyperliquidWebSocketSubscription> = []
  private let queue = DispatchQueue(label: "com.heliqsdk.subscriptionmanager")
  private weak var webSocketService: WebSocketService?
  
  /// Creates a subscription manager.
  public init(webSocketService: WebSocketService? = nil) {
    self.webSocketService = webSocketService
  }
  
  /// Subscribes to a channel after its WebSocket request succeeds.
  public func subscribe(to channel: SubscriptionChannel) async throws {
    let reserved = queue.sync {
      guard !activeSubscriptions.contains(channel),
            !pendingSubscriptions.contains(channel) else {
        return false
      }
      pendingSubscriptions.insert(channel)
      return true
    }
    guard reserved else { return }

    do {
      if let service = webSocketService {
        try await service.subscribe(channel: channel.channelName, payload: channel.payload)
      }
      let _: Void = queue.sync {
        pendingSubscriptions.remove(channel)
        activeSubscriptions.insert(channel)
      }
    } catch {
      let _: Void = queue.sync {
        pendingSubscriptions.remove(channel)
      }
      throw error
    }
  }
  
  /// Performs the unsubscribe operation.
  public func unsubscribe(from channel: SubscriptionChannel) async throws {
    let reserved = queue.sync {
      guard activeSubscriptions.contains(channel),
            !pendingSubscriptions.contains(channel) else {
        return false
      }
      pendingSubscriptions.insert(channel)
      return true
    }
    guard reserved else { return }

    do {
      if let service = webSocketService {
        try await service.unsubscribe(channel: channel.channelName, payload: channel.payload)
      }
      let _: Void = queue.sync {
        pendingSubscriptions.remove(channel)
        activeSubscriptions.remove(channel)
      }
    } catch {
      let _: Void = queue.sync {
        pendingSubscriptions.remove(channel)
      }
      throw error
    }
  }
  
  /// Performs the subscribe operation.
  public func subscribe(to subscription: HyperliquidWebSocketSubscription) async throws {
    let reserved = queue.sync {
      guard !activeRawSubscriptions.contains(subscription),
            !pendingRawSubscriptions.contains(subscription) else {
        return false
      }
      pendingRawSubscriptions.insert(subscription)
      return true
    }
    guard reserved else { return }

    do {
      try await webSocketService?.subscribe(subscription)
      let _: Void = queue.sync {
        pendingRawSubscriptions.remove(subscription)
        activeRawSubscriptions.insert(subscription)
      }
    } catch {
      let _: Void = queue.sync {
        pendingRawSubscriptions.remove(subscription)
      }
      throw error
    }
  }

  /// Performs the unsubscribe operation.
  public func unsubscribe(from subscription: HyperliquidWebSocketSubscription) async throws {
    let reserved = queue.sync {
      guard activeRawSubscriptions.contains(subscription),
            !pendingRawSubscriptions.contains(subscription) else {
        return false
      }
      pendingRawSubscriptions.insert(subscription)
      return true
    }
    guard reserved else { return }

    do {
      try await webSocketService?.unsubscribe(subscription)
      let _: Void = queue.sync {
        pendingRawSubscriptions.remove(subscription)
        activeRawSubscriptions.remove(subscription)
      }
    } catch {
      let _: Void = queue.sync {
        pendingRawSubscriptions.remove(subscription)
      }
      throw error
    }
  }

  /// Performs the is subscribed operation.
  public func isSubscribed(to subscription: HyperliquidWebSocketSubscription) -> Bool {
    queue.sync { activeRawSubscriptions.contains(subscription) }
  }

  /// Unsubscribes every currently active subscription while preserving concurrent additions.
  public func unsubscribeAll() async throws {
    let (channels, rawSubscriptions): ([SubscriptionChannel], [HyperliquidWebSocketSubscription]) = queue.sync {
      let channels = Array(activeSubscriptions)
      let rawSubscriptions = Array(activeRawSubscriptions)
      pendingSubscriptions.formUnion(channels)
      pendingRawSubscriptions.formUnion(rawSubscriptions)
      return (channels, rawSubscriptions)
    }

    do {
      if let service = webSocketService {
        for channel in channels {
          try await service.unsubscribe(channel: channel.channelName, payload: channel.payload)
        }
        for subscription in rawSubscriptions {
          try await service.unsubscribe(subscription)
        }
      }
      let _: Void = queue.sync {
        activeSubscriptions.subtract(Set(channels))
        activeRawSubscriptions.subtract(Set(rawSubscriptions))
        pendingSubscriptions.subtract(Set(channels))
        pendingRawSubscriptions.subtract(Set(rawSubscriptions))
      }
    } catch {
      let _: Void = queue.sync {
        pendingSubscriptions.subtract(channels)
        pendingRawSubscriptions.subtract(rawSubscriptions)
      }
      throw error
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
