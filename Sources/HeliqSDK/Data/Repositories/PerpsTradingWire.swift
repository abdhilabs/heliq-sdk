//
//  PerpsTradingWire.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

struct ResolvedPerpsMarket: Sendable {
  let id: Int
  let dex: String
  let asset: PerpsAsset
}

extension ExchangeRepositoryImpl {
  /// Resolves an asset ID or metadata coin name to its DEX, precision, and leverage limits.
  func resolvePerpsMarket(_ market: PerpsMarket) async throws -> ResolvedPerpsMarket {
    let info = InfoRepositoryImpl(apiClient: apiClient)
    let dex: String
    let index: Int?
    let coin: String?
    let dexIndex: Int
    switch market {
    case .coin(let name):
      guard !name.isEmpty else { throw ValidationError.missingRequiredField(field: "coin") }
      coin = name
      index = nil
      dex = name.contains(":") ? String(name.split(separator: ":", maxSplits: 1)[0]) : ""
      if dex.isEmpty {
        dexIndex = 0
      } else {
        let dexs = try await info.perps(.dexs())
        guard let found = dexs.firstIndex(where: { $0?.name == dex }), found > 0 else {
          throw ValidationError.malformedData(reason: "Unknown Perps DEX")
        }
        dexIndex = found
      }
    case .asset(let id):
      guard id >= 0, id < 10000 || id >= 110000 else {
        throw ValidationError.malformedData(reason: "Not a perpetual asset ID")
      }
      coin = nil
      if id < 10000 {
        dex = ""
        dexIndex = 0
        index = id
      } else {
        dexIndex = (id - 100000) / 10000
        index = (id - 100000) % 10000
        let dexs = try await info.perps(.dexs())
        guard dexs.indices.contains(dexIndex), let found = dexs[dexIndex] else {
          throw APIError.invalidResponse
        }
        dex = found.name
      }
    }
    let meta = try await info.perps(.meta(dex: dex))
    guard let found = index ?? meta.universe.firstIndex(where: { $0.name == coin }),
      meta.universe.indices.contains(found), found < 10000
    else {
      throw ValidationError.malformedData(reason: "Unknown perpetual market")
    }
    let asset = meta.universe[found]
    guard (0...8).contains(asset.szDecimals) else {
      throw ValidationError.malformedData(reason: "Market is delisted or has unsupported precision")
    }
    return .init(
      id: dexIndex == 0 ? found : 100000 + dexIndex * 10000 + found, dex: dex, asset: asset)
  }

  /// Validates order precision and parameters, then builds the canonical protocol order.
  func perpsOrderWire(_ order: PerpsOrderRequest) async throws -> CanonicalMessagePack.Object {
    typealias O = CanonicalMessagePack.Object
    typealias V = CanonicalMessagePack.Value
    let resolved = try await resolvePerpsMarket(order.market)
    guard resolved.asset.isDelisted != true || order.reduceOnly else {
      throw ValidationError.malformedData(
        reason: "Delisted markets only permit cleanup/reduce-only requests")
    }
    let size = try positivePerpsDecimal(order.size)
    try validatePerpsPrecision(order.size, decimals: resolved.asset.szDecimals)
    var price = order.price
    let kind: V
    switch order.kind {
    case .limit(let tif):
      kind = .object(O([("limit", .object(O([("tif", .string(tif.rawValue))])))]))
    case .market(let slippage):
      guard !slippage.isNaN, slippage >= 0, slippage < 1 else {
        throw ValidationError.malformedData(reason: "Invalid slippage")
      }
      if price == nil {
        let mids = try await InfoRepositoryImpl(apiClient: apiClient).perps(
          PerpsQuery<[String: Decimal]>.mids(dex: resolved.dex))
        guard let mid = mids[resolved.asset.name] else { throw APIError.invalidResponse }
        price = roundedPerpsPrice(
          mid * (order.side == .buy ? 1 + slippage : 1 - slippage),
          decimals: resolved.asset.szDecimals)
      }
      kind = .object(O([("limit", .object(O([("tif", .string("Ioc"))])))]))
    case .trigger(let trigger, let type, let market):
      try validatePerpsPrice(trigger, decimals: resolved.asset.szDecimals)
      if price == nil, market {
        price = roundedPerpsPrice(
          trigger * (order.side == .buy ? Decimal(string: "1.05")! : Decimal(string: "0.95")!),
          decimals: resolved.asset.szDecimals)
      }
      kind = .object(
        O([
          (
            "trigger",
            .object(
              O([
                ("isMarket", .bool(market)),
                ("triggerPx", .string(try positivePerpsDecimal(trigger))),
                ("tpsl", .string(type.rawValue)),
              ]))
          )
        ]))
    }
    guard let price else { throw ValidationError.missingRequiredField(field: "price") }
    try validatePerpsPrice(price, decimals: resolved.asset.szDecimals)
    var fields: [(String, V)] = [
      ("a", .number(Double(resolved.id))), ("b", .bool(order.side == .buy)),
      ("p", .string(try positivePerpsDecimal(price))), ("s", .string(size)),
      ("r", .bool(order.reduceOnly)), ("t", kind),
    ]
    if let cloid = order.cloid {
      try perpsCloid(cloid)
      fields.append(("c", .string(cloid.lowercased())))
    }
    return O(fields)
  }
}

/// Requires a 16-byte hexadecimal client order ID.
func perpsCloid(_ value: String) throws {
  guard value.hasPrefix("0x"), value.count == 34,
    value.dropFirst(2).utf8.allSatisfy({
      (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
    })
  else {
    throw ValidationError.invalidFieldFormat(
      field: "cloid", expected: "128-bit hexadecimal client ID")
  }
}
/// Validates an exchange or client order ID and preserves its exact wire representation.
func perpsIdentifier(_ id: PerpsOrderIdentifier) throws -> CanonicalMessagePack.Value {
  switch id {
  case .orderID(let value): return try perpsInteger(value)
  case .cloid(let value):
    try perpsCloid(value)
    return .string(value.lowercased())
  }
}
/// Requires the protocol’s explicit token identifier rather than an ambiguous symbol.
func validatePerpsToken(_ token: String) throws {
  let fields = token.split(separator: ":", omittingEmptySubsequences: false)
  guard fields.count == 2, !fields[0].isEmpty, fields[1].hasPrefix("0x"), fields[1].count == 34,
    fields[1].dropFirst(2).allSatisfy({ $0.isHexDigit })
  else { throw ValidationError.malformedData(reason: "Expected tokenName:128-bit-tokenId") }
}
/// Rejects decimal amounts that exceed the metadata’s allowed fractional precision.
func validatePerpsPrecision(_ value: Decimal, decimals: Int) throws {
  guard !value.isNaN, (0...18).contains(decimals) else { throw APIError.invalidResponse }
  var input = value
  var rounded = Decimal()
  NSDecimalRound(&rounded, &input, decimals, .plain)
  guard rounded == value else {
    throw ValidationError.malformedData(reason: "Value exceeds market precision")
  }
}
/// Checks positive prices against protocol decimal and significant-figure limits.
func validatePerpsPrice(_ value: Decimal, decimals: Int) throws {
  _ = try positivePerpsDecimal(value)
  try validatePerpsPrecision(value, decimals: max(0, 6 - decimals))
  let text = try perpsDecimalString(value)
  // Integer prices are exempt from the five-significant-figure rule.
  if text.contains(".") {
    let digits = text.filter { $0.isNumber }.drop(while: { $0 == "0" }).reversed().drop(while: {
      $0 == "0"
    })
    guard digits.count <= 5 else {
      throw ValidationError.malformedData(reason: "Price exceeds five significant figures")
    }
  }
}
/// Rounds a derived market price to the precision permitted by the asset metadata.
func roundedPerpsPrice(_ value: Decimal, decimals: Int) -> Decimal {
  let text = (try? perpsDecimalString(value)) ?? "0"
  let pieces = text.split(separator: ".", omittingEmptySubsequences: false)
  let significantPlaces: Int
  if let whole = pieces.first, whole != "0" {
    significantPlaces = max(0, 5 - whole.count)
  } else {
    significantPlaces = 5 + (pieces.count > 1 ? pieces[1].prefix(while: { $0 == "0" }).count : 0)
  }
  var input = value
  var rounded = Decimal()
  NSDecimalRound(&rounded, &input, min(max(0, 6 - decimals), significantPlaces), .plain)
  return rounded
}

extension JSONValue {
  fileprivate subscript(perps key: String) -> JSONValue {
    if case .object(let object) = self { return object[key] ?? .null }
    return .null
  }
  fileprivate var perpsString: String? {
    if case .string(let value) = self { return value }
    return nil
  }
  fileprivate var perpsID: Int64? {
    if case .integer(let value) = self, value > 0 { return value }
    if case .number(let value) = self, value > 0, value.rounded() == value,
      value < 9_007_199_254_740_992
    {
      return Int64(value)
    }
    return nil
  }
}

/// Decodes acknowledgements and per-item statuses without hiding partial exchange failures.
func decodePerpsResult(_ response: JSONValue, action: PerpsAction) throws -> PerpsActionResult {
  let type = response[perps: "type"].perpsString
  // Single modify acknowledges success without returning the replacement order ID.
  if type == "default", case .modifyOrder = action { return .success }
  if type == "order" {
    guard case .array(let statuses) = response[perps: "data"][perps: "statuses"] else {
      throw APIError.invalidResponse
    }
    let expected: Int
    switch action {
    case .orders(let orders, _, _): expected = orders.count
    case .modify(let orders, _): expected = orders.count
    case .modifyOrder: expected = 1
    case .marketClose: expected = 1
    default: throw APIError.invalidResponse
    }
    guard statuses.count == expected else { throw APIError.invalidResponse }
    return .orders(
      try statuses.map { value in
        if let error = value[perps: "error"].perpsString { return .rejected(error) }
        if let id = value[perps: "resting"][perps: "oid"].perpsID { return .resting(orderID: id) }
        if let id = value[perps: "filled"][perps: "oid"].perpsID,
          let size = value[perps: "filled"][perps: "totalSz"].perpsString,
          let price = value[perps: "filled"][perps: "avgPx"].perpsString
        {
          return .filled(orderID: id, size: try perpsDecimal(size), price: try perpsDecimal(price))
        }
        if value.perpsString == "waitingForFill" { return .waitingForFill }
        if value.perpsString == "waitingForTrigger" { return .waitingForTrigger }
        throw APIError.invalidResponse
      })
  }
  if type == "cancel" {
    guard case .cancel(let requests, _) = action,
      case .array(let statuses) = response[perps: "data"][perps: "statuses"],
      statuses.count == requests.count
    else { throw APIError.invalidResponse }
    return .cancellations(
      try statuses.map {
        if $0.perpsString == "success" { return .success }
        if let error = $0[perps: "error"].perpsString { return .rejected(error) }
        throw APIError.invalidResponse
      })
  }
  if type == "twapOrder", case .twap = action {
    let status = response[perps: "data"][perps: "status"]
    if let error = status[perps: "error"].perpsString {
      throw APIError.hyperliquidError(code: 0, message: error)
    }
    guard let id = status[perps: "running"][perps: "twapId"].perpsID else {
      throw APIError.invalidResponse
    }
    return .twap(id: id)
  }
  if type == "twapCancel", case .cancelTwap = action {
    let status = response[perps: "data"][perps: "status"]
    if let error = status[perps: "error"].perpsString {
      throw APIError.hyperliquidError(code: 0, message: error)
    }
    guard status.perpsString == "success" else { throw APIError.invalidResponse }
    return .success
  }
  if type == "trailingStop", case .trailingStop = action {
    guard let id = response[perps: "data"][perps: "oid"].perpsID else {
      throw APIError.invalidResponse
    }
    return .trailingStop(orderID: id)
  }
  switch action {
  case .orders, .modify, .modifyOrder, .marketClose, .cancel, .twap, .cancelTwap, .trailingStop:
    throw APIError.decodingFailed(
      underlying: ValidationError.malformedData(
        reason: "Unexpected Perps response type: " + (type ?? "missing")))
  default: break
  }
  guard type == "default" else { throw APIError.invalidResponse }
  return .success
}

/// Rejects order options incompatible with the requested modification behavior.
func validatePerpsModification(_ order: PerpsOrderRequest, alwaysPlace: Bool) throws {
  if alwaysPlace { return }
  if case .limit(let tif) = order.kind, tif != .ioc { return }
  throw ValidationError.malformedData(
    reason: "Trigger or IOC modifications require explicit alwaysPlace")
}

extension ExchangeRepositoryImpl {
  /// Checks token metadata, ledger collateral compatibility, and exact transfer precision.
  func validatePerpsTransfer(token: String, amount: Decimal, ledgers: [PerpsLedger]) async throws {
    try validatePerpsToken(token)
    let meta = try await InfoRepositoryImpl(apiClient: apiClient).perps(.spotMeta())
    guard
      let found = meta.tokens.first(where: {
        ($0.name + ":" + $0.tokenId).lowercased() == token.lowercased()
      })
    else {
      throw ValidationError.malformedData(reason: "Unknown transfer token")
    }
    _ = try positivePerpsDecimal(amount)
    try validatePerpsPrecision(amount, decimals: found.weiDecimals ?? found.szDecimals)
    for ledger in ledgers {
      if case .perps(let dex) = ledger {
        let perps = try await InfoRepositoryImpl(apiClient: apiClient).perps(.meta(dex: dex))
        guard perps.collateralToken == found.index else {
          throw ValidationError.malformedData(reason: "Token is not the selected DEX collateral")
        }
      }
    }
  }
}
