//
//  PerpsWebSocketSubscription.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

/// Typed payload on the existing subscription/transport lifecycle.
public struct PerpsSubscription<Event: Decodable & Sendable>: Sendable {
  public let subscription: HyperliquidWebSocketSubscription
  private let decodeEnvelope: @Sendable (Data) throws -> Event
  /// Binds subscription parameters to their event decoder on the existing WebSocket transport.
  init(
    _ type: HyperliquidWebSocketSubscriptionType, parameters: [String: JSONValue] = [:],
    decode: (@Sendable (Data) throws -> Event)? = nil
  ) {
    decodeEnvelope =
      decode ?? { try JSONDecoder().decode(PerpsWebSocketEnvelope<Event>.self, from: $0).data }
    subscription = .init(type: type, parameters: parameters)
  }
  public var channel: String {
    subscription.type == .userEvents ? "user" : subscription.type.rawValue
  }
  /// Decodes a complete WS envelope and checks its channel before exposing data.
  public func decode(_ data: Data) throws -> Event {
    let envelope = try JSONDecoder().decode(PerpsWebSocketChannel.self, from: data)
    guard envelope.channel == channel else { throw APIError.invalidResponse }
    return try decodeEnvelope(data)
  }
}
private struct PerpsWebSocketChannel: Decodable { let channel: String }
private struct PerpsWebSocketEnvelope<Event: Decodable>: Decodable {
  let channel: String
  let data: Event
}
public struct PerpsAccountEvent: Codable, Sendable {
  public let dex: String?
  public let user: String
  public let clearinghouseState: PerpsAccountState
}
public struct PerpsSpotEvent: Codable, Sendable {
  public let user: String
  public let spotState: PerpsSpotState
}
public struct PerpsAllDexsAccountEvent: Codable, Sendable {
  public let user: String
  public let clearinghouseStates: [PerpsDexAccount]
}
public struct PerpsOpenOrdersEvent: Codable, Sendable {
  public let user: String
  public let dex: String?
  public let orders: [PerpsOrder]
}
public struct PerpsFillsEvent: Codable, Sendable {
  public let user: String
  public let isSnapshot: Bool?
  public let fills: [PerpsFill]
}
public struct PerpsTwapSliceEvent: Codable, Sendable {
  public let user: String
  public let isSnapshot: Bool?
  public let twapSliceFills: [PerpsTwapSliceFill]
}
public struct PerpsTwapHistoryEvent: Codable, Sendable {
  public let user: String
  public let isSnapshot: Bool?
  public let history: [PerpsTwapHistoryEntry]
}
public struct PerpsTwapStatesEvent: Codable, Sendable {
  public let dex: String
  public let user: String
  public let states: [PerpsTwapEntry]
}
public struct PerpsAssetContextEvent: Codable, Sendable {
  public let coin: String
  public let ctx: PerpsAssetContext
}
public struct PerpsAllDexsContextsEvent: Codable, Sendable {
  public let ctxs: [PerpsDexContexts]
}
public struct PerpsDexContexts: Codable, Sendable {
  public let dex: String
  public let ctxs: [PerpsAssetContext]
  /// Decodes `PerpsDexContexts` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    dex = try c.decode(String.self)
    ctxs = try c.decode([PerpsAssetContext].self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsDexContexts` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(dex)
    try c.encode(ctxs)
  }
}
extension PerpsSubscription where Event == PerpsAccountEvent {
  /// Subscribes to account margin and position updates for the selected DEX.
  public static func account(user: String, dex: String = "") -> Self {
    .init(.clearinghouseState, parameters: ["user": .string(user), "dex": .string(dex)])
  }
}
extension PerpsSubscription where Event == PerpsAllDexsAccountEvent {
  /// Subscribes to account state across all Perps DEXs.
  public static func allAccounts(user: String) -> Self {
    .init(.allDexsClearinghouseState, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsSpotEvent {
  /// Subscribes to Spot balances, with the optional portfolio-margin feed.
  public static func spotState(user: String, portfolioMargin: Bool = false) -> Self {
    .init(
      .spotState, parameters: ["user": .string(user), "isPortfolioMargin": .bool(portfolioMargin)])
  }
}
extension PerpsSubscription where Event == PerpsActiveAssetData {
  /// Subscribes to the user’s trading capacity for one coin.
  public static func activeAsset(user: String, coin: String) -> Self {
    .init(.activeAssetData, parameters: ["user": .string(user), "coin": .string(coin)])
  }
}
extension PerpsSubscription where Event == PerpsAssetContextEvent {
  /// Subscribes to funding, price, and open-interest context for one coin.
  public static func assetContext(coin: String) -> Self {
    .init(.activeAssetCtx, parameters: ["coin": .string(coin)])
  }
}
extension PerpsSubscription where Event == PerpsAllDexsContextsEvent {
  /// Subscribes to asset contexts across all Perps DEXs.
  public static func allContexts() -> Self { .init(.allDexsAssetCtxs) }
}
extension PerpsSubscription where Event == PerpsOpenOrdersEvent {
  /// Subscribes to the user’s open orders on the selected DEX.
  public static func openOrders(user: String, dex: String = "") -> Self {
    .init(.openOrders, parameters: ["user": .string(user), "dex": .string(dex)])
  }
}
extension PerpsSubscription where Event == [PerpsHistoricalOrder] {
  /// Subscribes to changes in the user’s order statuses.
  public static func orderUpdates(user: String) -> Self {
    .init(.orderUpdates, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsFillsEvent {
  /// Subscribes to user fills, optionally aggregating fills by time.
  public static func fills(user: String, aggregateByTime: Bool = false) -> Self {
    .init(
      .userFills, parameters: ["user": .string(user), "aggregateByTime": .bool(aggregateByTime)])
  }
}
extension PerpsSubscription where Event == PerpsTwapSliceEvent {
  /// Subscribes to fills generated by the user’s TWAP slices.
  public static func twapSlices(user: String) -> Self {
    .init(.userTwapSliceFills, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsTwapHistoryEvent {
  /// Subscribes to changes in the user’s TWAP history.
  public static func twapHistory(user: String) -> Self {
    .init(.userTwapHistory, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsTwapStatesEvent {
  /// Subscribes to active TWAP states for the user and selected DEX.
  public static func twapStates(user: String, dex: String = "") -> Self {
    .init(.twapStates, parameters: ["user": .string(user), "dex": .string(dex)])
  }
}
extension SubscriptionManager {
  /// Registers the typed subscription through the existing transport and reconnection lifecycle.
  public func subscribe<Event>(to typed: PerpsSubscription<Event>) async throws {
    try validatePerpsParameters(typed.subscription.parameters)
    try await subscribe(to: typed.subscription)
  }
  /// Removes the typed subscription through the existing transport lifecycle.
  public func unsubscribe<Event>(from typed: PerpsSubscription<Event>) async throws {
    try await unsubscribe(from: typed.subscription)
  }
}
extension WebSocketMessageRouter {
  /// Register before subscribing; subscription lifecycle remains owned by SubscriptionManager.
  public func registerPerpsHandler<Event>(
    for subscription: PerpsSubscription<Event>,
    handler: @escaping @Sendable (Result<Event, Error>) -> Void
  ) throws {
    try validatePerpsParameters(subscription.subscription.parameters)
    try registerPerpsEnvelopeHandler(
      subscription: subscription.subscription, channel: subscription.channel
    ) { data in
      do {
        guard try subscription.matches(data) else { return }
        handler(.success(try subscription.decode(data)))
      } catch { handler(.failure(error)) }
    }
  }
  /// Removes the local envelope handler for this subscription; unsubscribe separately to stop the
  /// feed.
  public func unregisterPerpsHandler<Event>(for subscription: PerpsSubscription<Event>) {
    unregisterPerpsEnvelopeHandler(subscription.subscription)
  }
}

public enum PerpsCandleInterval: String, Codable, Sendable, CaseIterable {
  case minute = "1m"
  case threeMinutes = "3m"
  case fiveMinutes = "5m"
  case fifteenMinutes = "15m"
  case thirtyMinutes = "30m"
  case hour = "1h"
  case twoHours = "2h"
  case fourHours = "4h"
  case eightHours = "8h"
  case twelveHours = "12h"
  case day = "1d"
  case threeDays = "3d"
  case week = "1w"
  case month = "1M"
}
public struct PerpsFundingsEvent: Codable, Sendable {
  public let user: String
  public let isSnapshot: Bool?
  public let fundings: [PerpsUserFunding]
}
public struct PerpsLedgerEvent: Codable, Sendable {
  public let user: String
  public let isSnapshot: Bool?
  public let nonFundingLedgerUpdates: [PerpsLedgerEntry]
}
public struct PerpsNotification: Codable, Sendable { public let notification: String }
public struct PerpsMidsEvent: Decodable, Sendable {
  public let mids: [String: Decimal]
  enum CodingKeys: String, CodingKey { case mids }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    mids = try decoder.container(keyedBy: CodingKeys.self).decode(
      [String: String].self, forKey: .mids
    ).mapValues(perpsDecimal)
  }
}
public struct PerpsFastContexts: Decodable, Sendable {
  public let contexts: [String: FastAssetCtx]
  /// Decodes `PerpsFastContexts` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    contexts = try FastAssetCtxDecoder.decode(decoder.singleValueContainer().decode(String.self))
  }
}
public struct PerpsWebUserState: Decodable, Sendable {
  public let agentAddress: String?
  public let agentValidUntil: Int64?
  public let serverTime: Int64
  public let cumLedger: Decimal
  public let isVault: Bool
  public let user: String
  public let optOutOfSpotDusting: Bool?
  public let dexAbstractionEnabled: Bool?
  enum CodingKeys: String, CodingKey {
    case agentAddress, agentValidUntil, serverTime, cumLedger, isVault, user, optOutOfSpotDusting,
      dexAbstractionEnabled
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    agentAddress = try c.decodeIfPresent(String.self, forKey: .agentAddress)
    agentValidUntil = try c.decodeIfPresent(Int64.self, forKey: .agentValidUntil)
    serverTime = try c.decode(Int64.self, forKey: .serverTime)
    cumLedger = try c.protocolDecimal(.cumLedger)
    isVault = try c.decode(Bool.self, forKey: .isVault)
    user = try c.decode(String.self, forKey: .user)
    optOutOfSpotDusting = try c.decodeIfPresent(Bool.self, forKey: .optOutOfSpotDusting)
    dexAbstractionEnabled = try c.decodeIfPresent(Bool.self, forKey: .dexAbstractionEnabled)
  }
}
public struct PerpsLeadingVault: Decodable, Sendable {
  public let address: String
  public let name: String
}
public struct PerpsWebDexState: Decodable, Sendable {
  public let totalVaultEquity: Decimal
  public let perpsAtOpenInterestCap: [String]?
  public let leadingVaults: [PerpsLeadingVault]?
  enum CodingKeys: String, CodingKey {
    case totalVaultEquity, perpsAtOpenInterestCap, leadingVaults
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    totalVaultEquity = try c.protocolDecimal(.totalVaultEquity)
    perpsAtOpenInterestCap = try c.decodeIfPresent([String].self, forKey: .perpsAtOpenInterestCap)
    leadingVaults = try c.decodeIfPresent([PerpsLeadingVault].self, forKey: .leadingVaults)
  }
}
public struct PerpsWebData3: Decodable, Sendable {
  public let userState: PerpsWebUserState
  public let perpDexStates: [PerpsWebDexState]
}
extension PerpsSubscription where Event == PerpsWebData3 {
  /// Subscribes to the account’s combined frontend state.
  public static func webData(user: String) -> Self {
    .init(.webData3, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsMidsEvent {
  /// Subscribes to midpoint prices for the selected DEX.
  public static func mids(dex: String = "") -> Self {
    .init(.allMids, parameters: ["dex": .string(dex)])
  }
}
extension PerpsSubscription where Event == PerpsFastContexts {
  /// Subscribes to compressed asset contexts using the existing fast decoder.
  public static func fastContexts() -> Self { .init(.fastAssetCtxs) }
}
extension PerpsSubscription where Event == PerpsNotification {
  /// Subscribes to account notification messages.
  public static func notifications(user: String) -> Self {
    .init(.notification, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsUserEvents {
  /// Subscribes to user events delivered on the protocol’s `user` channel.
  public static func userEvents(user: String) -> Self {
    .init(.userEvents, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsFundingsEvent {
  /// Subscribes to the user’s funding payment updates.
  public static func funding(user: String) -> Self {
    .init(.userFundings, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsLedgerEvent {
  /// Subscribes to the user’s non-funding ledger updates.
  public static func ledger(user: String) -> Self {
    .init(.userNonFundingLedgerUpdates, parameters: ["user": .string(user)])
  }
}
extension PerpsSubscription where Event == PerpsBook {
  /// Subscribes to a coin’s order book with optional price-level aggregation.
  public static func book(
    coin: String, nSigFigs: Int? = nil, mantissa: Int? = nil, fast: Bool = false
  ) -> Self {
    var parameters: [String: JSONValue] = ["coin": .string(coin)]
    if let nSigFigs { parameters["nSigFigs"] = .number(Double(nSigFigs)) }
    if let mantissa { parameters["mantissa"] = .number(Double(mantissa)) }
    if fast { parameters["fast"] = .bool(true) }
    return .init(.l2Book, parameters: parameters)
  }
}
extension PerpsSubscription where Event == PerpsBbo {
  /// Subscribes to a coin’s best bid and offer.
  public static func bbo(coin: String) -> Self { .init(.bbo, parameters: ["coin": .string(coin)]) }
}
extension PerpsSubscription where Event == [PerpsTrade] {
  /// Subscribes to public trades for a coin.
  public static func trades(coin: String) -> Self {
    .init(.trades, parameters: ["coin": .string(coin)])
  }
}
extension PerpsSubscription where Event == [PerpsCandle] {
  /// Subscribes to candles for the selected coin and interval.
  public static func candles(coin: String, interval: PerpsCandleInterval) -> Self {
    .init(
      .candle, parameters: ["coin": .string(coin), "interval": .string(interval.rawValue)],
      decode: {
        try JSONDecoder().decode(PerpsWebSocketEnvelope<PerpsCandleBatch>.self, from: $0).data
          .values
      })
  }
}

private struct PerpsCandleBatch: Decodable {
  let values: [PerpsCandle]
  /// Decodes `PerpsCandleBatch` from its protocol response representation; invalid required values
  /// throw.
  init(from decoder: Decoder) throws {
    if (try? decoder.unkeyedContainer()) != nil {
      values = try [PerpsCandle](from: decoder)
    } else {
      values = [try PerpsCandle(from: decoder)]
    }
  }
}

extension PerpsSubscription {
  /// Checks user, coin, DEX, and interval fields to route an envelope to the matching subscription.
  fileprivate func matches(_ data: Data) throws -> Bool {
    let packet = try JSONDecoder().decode(PerpsWebSocketEnvelope<JSONValue>.self, from: data)
    let object: [String: JSONValue]
    switch packet.data {
    case .object(let value): object = value
    case .array(let values):
      if case .object(let first)? = values.first { object = first } else { return true }
    default: return true
    }
    for key in ["user", "coin", "dex", "interval"] {
      guard case .string(let expected)? = subscription.parameters[key] else { continue }
      var actual = object[key]
      if key == "coin", actual == nil { actual = object["s"] }
      if key == "interval", actual == nil { actual = object["i"] }
      if key == "user", actual == nil, case .object(let state)? = object["userState"] {
        actual = state["user"]
      }
      if case .string(let received)? = actual {
        if key == "user" ? received.lowercased() != expected.lowercased() : received != expected {
          return false
        }
      } else if key == "dex", !expected.isEmpty {
        return false
      }
    }
    return true
  }
}
