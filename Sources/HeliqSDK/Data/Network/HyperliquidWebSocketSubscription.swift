//
//  HyperliquidWebSocketSubscription.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum HyperliquidWebSocketSubscriptionType: Sendable, Hashable, Codable {
  case allMids, notification, webData2, webData3, twapStates, clearinghouseState, openOrders, userEvents, userFills, userFundings, userNonFundingLedgerUpdates, userTwapSliceFills, userTwapHistory, l2Book, trades, candle, bbo, activeAssetCtx, activeAssetData, spotState, allDexsClearinghouseState, allDexsAssetCtxs, fastAssetCtxs, outcomeMetaUpdates, orderUpdates, custom(String)
  public var rawValue: String { if case .custom(let v) = self { return v }; return String(describing: self) }
}

/// Exact WS subscription preserving documented `user`, `coin`, `dex`, and all
/// optional fields during subscribe and unsubscribe.
public struct HyperliquidWebSocketSubscription: Sendable, Hashable {
  public let type: HyperliquidWebSocketSubscriptionType
  public let parameters: [String: JSONValue]
  public init(type: HyperliquidWebSocketSubscriptionType, parameters: [String: JSONValue] = [:]) { self.type = type; self.parameters = parameters }
  public func payload() -> [String: Any] {
    parameters.reduce(into: ["type": type.rawValue] as [String: Any]) { $0[$1.key] = $1.value.foundationValue }
  }
}

public extension JSONValue {
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
