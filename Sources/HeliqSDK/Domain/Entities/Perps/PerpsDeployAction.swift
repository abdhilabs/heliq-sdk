//
//  PerpsDeployAction.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

public enum PerpsDeployedMarginMode: String, Sendable { case normal, strictIsolated, noCross }
public struct PerpsAssetRegistration: Sendable {
  public let coin: String
  public let sizeDecimals: Int
  public let oraclePrice: Decimal
  public let marginTableID: Int
  public let marginMode: PerpsDeployedMarginMode
  /// Defines a market’s initial precision, oracle price, margin table, and margin mode.
  public init(
    coin: String, sizeDecimals: Int, oraclePrice: Decimal, marginTableID: Int,
    marginMode: PerpsDeployedMarginMode = .normal
  ) {
    self.coin = coin
    self.sizeDecimals = sizeDecimals
    self.oraclePrice = oraclePrice
    self.marginTableID = marginTableID
    self.marginMode = marginMode
  }
}
public struct PerpsDexSchema: Sendable {
  public let fullName: String
  public let collateralToken: Int
  public let oracleUpdater: String?
  /// Defines the DEX display name, collateral token index, and optional oracle updater.
  public init(fullName: String, collateralToken: Int, oracleUpdater: String? = nil) {
    self.fullName = fullName
    self.collateralToken = collateralToken
    self.oracleUpdater = oracleUpdater
  }
}
public struct PerpsCoinValue<Value: Sendable>: Sendable {
  public let coin: String
  public let value: Value
  /// Associates a metadata coin name with one deployment setting.
  public init(_ coin: String, _ value: Value) {
    self.coin = coin
    self.value = value
  }
}
public enum PerpsDeployPermission: String, Sendable, CaseIterable {
  case registerAsset2, registerAsset, setOracle, setFundingMultipliers, setFundingInterestRates
  case setFundingClamps, haltTrading, insertMarginTable, setMarginTableIds, setFeeRecipient
  case setOpenInterestCaps, setSubDeployers, setMarginModes, setDeployerFees, setPerpAnnotation,
    disableDex
}
public struct PerpsSubDeployer: Sendable {
  public let permission: PerpsDeployPermission
  public let address: String
  public let allowed: Bool
  /// Grants or revokes one deployment permission for the specified address.
  public init(permission: PerpsDeployPermission, address: String, allowed: Bool) {
    self.permission = permission
    self.address = address
    self.allowed = allowed
  }
}
public struct PerpsDeployerFee: Sendable {
  public let scale: Decimal
  public let growthMode: Bool
  /// Defines a deployer fee scale and whether its growth mode is enabled.
  public init(scale: Decimal, growthMode: Bool) {
    self.scale = scale
    self.growthMode = growthMode
  }
}
public struct PerpsRawMarginTier: Sendable {
  public let lowerBound: Int64
  public let maxLeverage: Int
  /// Defines a margin tier’s integer lower bound and maximum leverage.
  public init(lowerBound: Int64, maxLeverage: Int) {
    self.lowerBound = lowerBound
    self.maxLeverage = maxLeverage
  }
}
/// Current HIP-3 deployment variants, with no arbitrary JSON payloads.
public enum PerpsDeployAction: Sendable {
  case registerAsset(
    dex: String, asset: PerpsAssetRegistration, schema: PerpsDexSchema?, maxGas: Int64?,
    legacy: Bool = false)
  case oracle(
    dex: String, oraclePrices: [PerpsCoinValue<Decimal>], markPrices: [[PerpsCoinValue<Decimal>]],
    externalPrices: [PerpsCoinValue<Decimal>])
  case fundingMultipliers([PerpsCoinValue<Decimal>])
  case fundingInterestRates([PerpsCoinValue<Decimal>])
  case fundingClamps([PerpsCoinValue<Decimal>])
  case halt(coin: String, halted: Bool)
  case insertMarginTable(dex: String, description: String, tiers: [PerpsRawMarginTier])
  case marginTableIDs([PerpsCoinValue<Int>])
  case feeRecipient(dex: String, address: String)
  case openInterestCaps([PerpsCoinValue<Int64?>])
  case subDeployers(dex: String, users: [PerpsSubDeployer])
  case marginModes([PerpsCoinValue<PerpsDeployedMarginMode>])
  case deployerFees([PerpsCoinValue<PerpsDeployerFee>])
  case annotation(
    coin: String, category: String, description: String, displayName: String?, keywords: [String])
  case disableDex(String)
}

extension PerpsDeployAction {
  /// Validates deployment parameters and builds the ordered `perpDeploy` action payload.
  func wire() throws -> CanonicalMessagePack.Object {
    typealias V = CanonicalMessagePack.Value
    typealias O = CanonicalMessagePack.Object
    let key: String
    let payload: V
    switch self {
    case .registerAsset(let dex, let asset, let schema, let maxGas, let legacy):
      guard
        schema == nil
          ? !dex.isEmpty : dex.range(of: "^[a-z]{2,4}$", options: .regularExpression) != nil,
        (0...8).contains(asset.sizeDecimals), asset.marginTableID > 0, !asset.coin.isEmpty
      else {
        throw ValidationError.malformedData(reason: "Invalid Perps asset registration")
      }
      key = legacy ? "registerAsset" : "registerAsset2"
      var registration: [(String, V)] = [
        ("coin", .string(asset.coin)), ("szDecimals", .number(Double(asset.sizeDecimals))),
        ("oraclePx", .string(try positivePerpsDecimal(asset.oraclePrice))),
        ("marginTableId", .number(Double(asset.marginTableID))),
      ]
      registration.append(
        legacy
          ? ("onlyIsolated", .bool(asset.marginMode != .normal))
          : ("marginMode", .string(asset.marginMode.rawValue)))
      var fields: [(String, V)] = []
      if let maxGas { fields.append(("maxGas", try perpsInteger(maxGas, allowZero: true))) }
      fields += [("assetRequest", .object(O(registration))), ("dex", .string(dex))]
      if let schema {
        guard schema.collateralToken >= 0, !schema.fullName.isEmpty else {
          throw APIError.invalidResponse
        }
        var values: [(String, V)] = [
          ("fullName", .string(schema.fullName)),
          ("collateralToken", .number(Double(schema.collateralToken))),
        ]
        if let updater = schema.oracleUpdater {
          try perpsAddress(updater)
          values.append(("oracleUpdater", .string(updater.lowercased())))
        }
        fields.append(("schema", .object(O(values))))
      }
      payload = .object(O(fields))
    case .oracle(let dex, let oracle, let marks, let external):
      guard marks.count <= 2, !dex.isEmpty else {
        throw ValidationError.malformedData(reason: "Invalid oracle update")
      }
      key = "setOracle"
      payload = .object(
        O([
          ("dex", .string(dex)), ("oraclePxs", try decimalPairs(oracle, range: nil)),
          ("markPxs", .array(try marks.map { try decimalPairs($0, range: nil) })),
          ("externalPerpPxs", try decimalPairs(external, range: nil)),
        ]))
    case .fundingMultipliers(let values):
      key = "setFundingMultipliers"
      payload = try decimalPairs(values, range: 0...10)
    case .fundingInterestRates(let values):
      key = "setFundingInterestRates"
      payload = try decimalPairs(
        values, range: Decimal(string: "-0.01")!...Decimal(string: "0.01")!)
    case .fundingClamps(let values):
      key = "setFundingClamps"
      payload = try decimalPairs(values, range: 0...Decimal(string: "0.01")!)
    case .halt(let coin, let halted):
      key = "haltTrading"
      payload = .object(O([("coin", .string(coin)), ("isHalted", .bool(halted))]))
    case .insertMarginTable(let dex, let description, let tiers):
      guard !tiers.isEmpty, tiers.count <= 3, tiers[0].lowerBound == 0 else {
        throw ValidationError.malformedData(reason: "Invalid margin tiers")
      }
      for (index, tier) in tiers.enumerated() {
        guard (1...50).contains(tier.maxLeverage), tier.lowerBound >= 0,
          index == 0
            || (tier.lowerBound > tiers[index - 1].lowerBound
              && tier.maxLeverage < tiers[index - 1].maxLeverage)
        else {
          throw ValidationError.malformedData(
            reason: "Margin tiers must increase bounds and decrease leverage")
        }
      }
      key = "insertMarginTable"
      payload = .object(
        O([
          ("dex", .string(dex)),
          (
            "marginTable",
            .object(
              O([
                ("description", .string(description)),
                (
                  "marginTiers",
                  .array(
                    try tiers.map {
                      .object(
                        O([
                          ("lowerBound", try perpsInteger($0.lowerBound, allowZero: true)),
                          ("maxLeverage", .number(Double($0.maxLeverage))),
                        ]))
                    })
                ),
              ]))
          ),
        ]))
    case .marginTableIDs(let values):
      key = "setMarginTableIds"
      payload = try pairs(values) { try perpsInteger(Int64($0)) }
    case .feeRecipient(let dex, let address):
      try perpsAddress(address)
      key = "setFeeRecipient"
      payload = .object(
        O([("dex", .string(dex)), ("feeRecipient", .string(address.lowercased()))]))
    case .openInterestCaps(let values):
      key = "setOpenInterestCaps"
      payload = try pairs(values) { value in
        if let value {
          guard value >= 1_000_000 else {
            throw ValidationError.malformedData(reason: "OI cap below minimum")
          }
          return try perpsInteger(value)
        }
        return .null
      }
    case .subDeployers(let dex, let users):
      key = "setSubDeployers"
      payload = .object(
        O([
          ("dex", .string(dex)),
          (
            "subDeployers",
            .array(
              try users.map {
                try perpsAddress($0.address)
                return .object(
                  O([
                    ("variant", .string($0.permission.rawValue)),
                    ("user", .string($0.address.lowercased())), ("allowed", .bool($0.allowed)),
                  ]))
              })
          ),
        ]))
    case .marginModes(let values):
      key = "setMarginModes"
      payload = try pairs(values) { .string($0.rawValue) }
    case .deployerFees(let values):
      key = "setDeployerFees"
      payload = try pairs(values) { fee in
        guard !fee.scale.isNaN, fee.scale >= 0, fee.growthMode ? fee.scale < 10 : fee.scale <= 3
        else { throw ValidationError.malformedData(reason: "Invalid deployer fee scale") }
        return .object(
          O([
            ("scale", .string(try perpsDecimalString(fee.scale))),
            ("growthMode", .bool(fee.growthMode)),
          ]))
      }
    case .annotation(let coin, let category, let description, let name, let keywords):
      guard category.count <= 15, description.count <= 400, (name?.count ?? 0) <= 9,
        keywords.count <= 2, keywords.allSatisfy({ $0.count <= 10 })
      else { throw ValidationError.malformedData(reason: "Annotation exceeds limits") }
      key = "setPerpAnnotation"
      payload = .object(
        O([
          ("coin", .string(coin)), ("category", .string(category)),
          ("description", .string(description)),
          ("displayName", name.map(V.string) ?? .null),
          ("keywords", .array(keywords.map(V.string))),
        ]))
    case .disableDex(let dex):
      key = "disableDex"
      payload = .string(dex)
    }
    return O([("type", .string("perpDeploy")), (key, payload)])
  }
}

/// Validates coin/value entries and encodes them as sorted protocol tuples.
private func pairs<T>(
  _ values: [PerpsCoinValue<T>], transform: (T) throws -> CanonicalMessagePack.Value
) throws -> CanonicalMessagePack.Value {
  guard !values.isEmpty, Set(values.map(\.coin)).count == values.count,
    values.allSatisfy({ !$0.coin.isEmpty })
  else {
    throw ValidationError.malformedData(reason: "Coin tuples must be nonempty and unique")
  }
  return .array(
    try values.sorted { $0.coin < $1.coin }.map {
      .array([.string($0.coin), try transform($0.value)])
    })
}
/// Validates decimal ranges and encodes sorted coin/value tuples with exact decimal strings.
private func decimalPairs(_ values: [PerpsCoinValue<Decimal>], range: ClosedRange<Decimal>?) throws
  -> CanonicalMessagePack.Value
{
  try pairs(values) { value in
    if let range {
      guard !value.isNaN, range.contains(value) else {
        throw ValidationError.malformedData(reason: "Funding parameter out of range")
      }
    } else {
      _ = try positivePerpsDecimal(value)
    }
    return .string(try perpsDecimalString(value))
  }
}
/// Requires a positive amount and returns its exact protocol decimal string.
func positivePerpsDecimal(_ value: Decimal) throws -> String {
  guard !value.isNaN, value > 0 else {
    throw ValidationError.malformedData(reason: "Amount must be positive")
  }
  return try perpsDecimalString(value)
}
/// Validates the sign and zero rules for an action’s integer parameter.
func perpsInteger(_ value: Int64, allowZero: Bool = false, signed: Bool = false) throws
  -> CanonicalMessagePack.Value
{
  guard signed || value > 0 || (allowZero && value == 0) else {
    throw ValidationError.malformedData(reason: "Invalid integer")
  }
  return value < 0 || value >= 9_007_199_254_740_992 ? .signed(value) : .number(Double(value))
}
/// Converts a decimal amount to exact six-decimal integer units, rejecting overflow or rounding.
func perpsMicroUnits(_ value: Decimal, signed: Bool = false) throws -> Int64 {
  guard !value.isNaN else { throw ValidationError.malformedData(reason: "Invalid amount") }
  let scaled = value * 1_000_000
  var input = scaled
  var rounded = Decimal()
  NSDecimalRound(&rounded, &input, 0, .plain)
  guard rounded == scaled, scaled >= Decimal(Int64.min), scaled <= Decimal(Int64.max),
    signed ? scaled != 0 : scaled > 0
  else { throw ValidationError.malformedData(reason: "Amount must be exact micro-units") }
  return NSDecimalNumber(decimal: scaled).int64Value
}
