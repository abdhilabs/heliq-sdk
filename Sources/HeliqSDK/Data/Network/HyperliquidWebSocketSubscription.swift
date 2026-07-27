//
//  HyperliquidWebSocketSubscription.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines hyperliquid web socket subscription type values.
public enum HyperliquidWebSocketSubscriptionType: Sendable, Hashable, Codable {
  /// The `allMids` option.
  case allMids
  /// The `notification` option.
  case notification
  /// The `webData2` option.
  case webData2
  /// The `webData3` option.
  case webData3
  /// The `twapStates` option.
  case twapStates
  /// The `clearinghouseState` option.
  case clearinghouseState
  /// The `openOrders` option.
  case openOrders
  /// The `userEvents` option.
  case userEvents
  /// The `userFills` option.
  case userFills
  /// The `userFundings` option.
  case userFundings
  /// The `userNonFundingLedgerUpdates` option.
  case userNonFundingLedgerUpdates
  /// The `userTwapSliceFills` option.
  case userTwapSliceFills
  /// The `userTwapHistory` option.
  case userTwapHistory
  /// The `l2Book` option.
  case l2Book
  /// The `trades` option.
  case trades
  /// The `candle` option.
  case candle
  /// The `bbo` option.
  case bbo
  /// The `activeAssetCtx` option.
  case activeAssetCtx
  /// The `activeAssetData` option.
  case activeAssetData
  /// The `spotState` option.
  case spotState
  /// The `allDexsClearinghouseState` option.
  case allDexsClearinghouseState
  /// The `allDexsAssetCtxs` option.
  case allDexsAssetCtxs
  /// The `fastAssetCtxs` option.
  case fastAssetCtxs
  /// The `outcomeMetaUpdates` option.
  case outcomeMetaUpdates
  /// The `orderUpdates` option.
  case orderUpdates
  /// The `custom` option.
  case custom(String)
  /// The raw value.
  public var rawValue: String { if case .custom(let v) = self { return v }; return String(describing: self) }
}

/// Exact WS subscription preserving documented `user`, `coin`, `dex`, and all
/// optional fields during subscribe and unsubscribe.
public struct HyperliquidWebSocketSubscription: Sendable, Hashable {
  /// The type.
  public let type: HyperliquidWebSocketSubscriptionType
  /// The parameters.
  public let parameters: [String: JSONValue]
  /// Creates a hyperliquid web socket subscription.
  public init(type: HyperliquidWebSocketSubscriptionType, parameters: [String: JSONValue] = [:]) { self.type = type; self.parameters = parameters }
  /// Performs the payload operation.
  public func payload() -> [String: Any] {
    parameters.reduce(into: ["type": type.rawValue] as [String: Any]) { $0[$1.key] = $1.value.foundationValue }
  }
}

/// Adds HeliqSDK conveniences to `JSONValue`.
public extension JSONValue {
  /// The foundation value.
  var foundationValue: Any {
    switch self {
    case .string(let v): return v
    case .number(let v): return v
    case .bool(let v): return v
    case .null: return NSNull()
    case .array(let v): return v.map(\.foundationValue)
    case .object(let v): return v.mapValues(\.foundationValue)
    }
  }
}
