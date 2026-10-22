//
//  PerpsDeployAction.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

/// Margin policy encoded by current HIP-3 registration and margin-mode updates.
public enum PerpsDeployedMarginMode: String, Sendable {
  /// Normal margin policy, permitting cross margin.
  case normal
  /// Isolated margin policy that also rejects isolated-margin withdrawals in the SDK.
  case strictIsolated
  /// Disallows cross margin without selecting strict-isolated policy.
  case noCross
}
/// Initial parameters for a HIP-3 perpetual asset; validation occurs during payload preparation.
public struct PerpsAssetRegistration: Sendable {
  /// Nonempty protocol coin name for registration.
  public let coin: String
  /// Allowed size decimal places, from 0 through 8 inclusive.
  public let sizeDecimals: Int
  /// Positive initial oracle price, encoded as an exact decimal string.
  public let oraclePrice: Decimal
  /// Positive margin-table identifier.
  public let marginTableID: Int
  /// Margin policy; legacy registration reduces this to an isolated-only Boolean.
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
/// Schema supplied when registering a new HIP-3 DEX alongside an asset.
public struct PerpsDexSchema: Sendable {
  /// Nonempty display name for the DEX.
  public let fullName: String
  /// Nonnegative collateral token index, not a decimal token amount.
  public let collateralToken: Int
  /// Optional authorized oracle updater address, normalized to lowercase on encoding.
  public let oracleUpdater: String?
  /// Defines the DEX display name, collateral token index, and optional oracle updater.
  public init(fullName: String, collateralToken: Int, oracleUpdater: String? = nil) {
    self.fullName = fullName
    self.collateralToken = collateralToken
    self.oracleUpdater = oracleUpdater
  }
}
/// Associates a coin with a deployment value. Tuple lists require unique, nonempty coin names
/// and are sorted by coin when encoded.
public struct PerpsCoinValue<Value: Sendable>: Sendable {
  /// Protocol coin name, including its DEX prefix where applicable.
  public let coin: String
  /// Setting whose units and allowed range depend on the deployment operation.
  public let value: Value
  /// Associates a metadata coin name with one deployment setting.
  public init(_ coin: String, _ value: Value) {
    self.coin = coin
    self.value = value
  }
}
/// Protocol deployment variants that can be granted to or revoked from a sub-deployer.
public enum PerpsDeployPermission: String, Sendable, CaseIterable {
  /// Current asset registration with an explicit margin mode.
  case registerAsset2
  /// Legacy asset registration with an isolated-only flag.
  case registerAsset
  /// Oracle, mark, and external price updates.
  case setOracle
  /// Per-coin funding multiplier updates.
  case setFundingMultipliers
  /// Per-coin funding interest-rate updates.
  case setFundingInterestRates
  /// Per-coin funding clamp updates.
  case setFundingClamps
  /// Trading halt or resume requests.
  case haltTrading
  /// Insertion of a DEX margin table.
  case insertMarginTable
  /// Assignment of margin-table IDs to coins.
  case setMarginTableIds
  /// DEX fee-recipient changes.
  case setFeeRecipient
  /// Per-coin open-interest cap updates.
  case setOpenInterestCaps
  /// Sub-deployer permission changes.
  case setSubDeployers
  /// Per-coin margin-mode changes.
  case setMarginModes
  /// Per-coin deployer fee settings.
  case setDeployerFees
  /// Perpetual market annotation changes.
  case setPerpAnnotation
  /// DEX disable requests.
  case disableDex
}
/// One permission grant or revocation within a sub-deployer update.
public struct PerpsSubDeployer: Sendable {
  /// Deployment variant controlled by this entry.
  public let permission: PerpsDeployPermission
  /// Sub-deployer address, validated and lowercased during encoding.
  public let address: String
  /// Whether to grant (`true`) or revoke (`false`) the permission.
  public let allowed: Bool
  /// Grants or revokes one deployment permission for the specified address.
  public init(permission: PerpsDeployPermission, address: String, allowed: Bool) {
    self.permission = permission
    self.address = address
    self.allowed = allowed
  }
}
/// Deployer fee configuration, validated when encoded rather than at initialization.
public struct PerpsDeployerFee: Sendable {
  /// Nonnegative scale: at most 3 normally, or strictly below 10 in growth mode.
  public let scale: Decimal
  /// Enables the protocol growth-mode fee setting and its alternative scale bound.
  public let growthMode: Bool
  /// Defines a deployer fee scale and whether its growth mode is enabled.
  public init(scale: Decimal, growthMode: Bool) {
    self.scale = scale
    self.growthMode = growthMode
  }
}
/// A margin tier using the protocol's raw integer bound without SDK unit conversion.
public struct PerpsRawMarginTier: Sendable {
  /// Raw nonnegative protocol lower bound; the first tier must start at zero.
  public let lowerBound: Int64
  /// Maximum leverage from 1 through 50, decreasing as successive bounds increase.
  public let maxLeverage: Int
  /// Defines a margin tier’s integer lower bound and maximum leverage.
  public init(lowerBound: Int64, maxLeverage: Int) {
    self.lowerBound = lowerBound
    self.maxLeverage = maxLeverage
  }
}
/// Signed HIP-3 deployment variants, with no arbitrary JSON payloads. The SDK validates payload
/// shape and supported ranges; the service decides whether the signer has deployment authority.
public enum PerpsDeployAction: Sendable {
  /// Registers an asset, optionally with a new DEX schema and nonnegative gas cap. With a schema,
  /// the DEX name must be 2...4 lowercase letters. Legacy mode uses `registerAsset` rather than
  /// `registerAsset2` and encodes nonnormal margin modes as isolated-only.
  case registerAsset(
    dex: String, asset: PerpsAssetRegistration, schema: PerpsDexSchema?, maxGas: Int64?,
    legacy: Bool = false)
  /// Updates positive exact decimal prices for a nonempty DEX. At most two mark-price lists
  /// are accepted; each supplied coin/value list must be nonempty and unique by coin.
  case oracle(
    dex: String, oraclePrices: [PerpsCoinValue<Decimal>], markPrices: [[PerpsCoinValue<Decimal>]],
    externalPrices: [PerpsCoinValue<Decimal>])
  /// Sets per-coin funding multipliers in the inclusive range 0...10.
  case fundingMultipliers([PerpsCoinValue<Decimal>])
  /// Sets raw protocol funding interest rates in the inclusive range -0.01...0.01.
  case fundingInterestRates([PerpsCoinValue<Decimal>])
  /// Sets raw protocol funding clamps in the inclusive range 0...0.01.
  case fundingClamps([PerpsCoinValue<Decimal>])
  /// Halts trading for a coin, or resumes it when `halted` is false.
  case halt(coin: String, halted: Bool)
  /// Inserts 1...3 tiers starting at zero, with strictly increasing bounds and decreasing leverage.
  case insertMarginTable(dex: String, description: String, tiers: [PerpsRawMarginTier])
  /// Assigns positive margin-table IDs to coins.
  case marginTableIDs([PerpsCoinValue<Int>])
  /// Sets the DEX fee-recipient address, normalized to lowercase during encoding.
  case feeRecipient(dex: String, address: String)
  /// Sets raw integer protocol OI caps, each at least 1,000,000, or encodes nil as protocol null.
  case openInterestCaps([PerpsCoinValue<Int64?>])
  /// Grants or revokes the listed deployment permissions for addresses on a DEX.
  case subDeployers(dex: String, users: [PerpsSubDeployer])
  /// Assigns explicit margin policies to coins.
  case marginModes([PerpsCoinValue<PerpsDeployedMarginMode>])
  /// Sets per-coin fee scales and growth-mode flags.
  case deployerFees([PerpsCoinValue<PerpsDeployerFee>])
  /// Updates market text: category ≤15, description ≤400, display name ≤9 characters;
  /// at most two keywords of ≤10 characters each. Nil display name encodes protocol null.
  case annotation(
    coin: String, category: String, description: String, displayName: String?, keywords: [String])
  /// Requests disabling the named DEX.
  case disableDex(String)
}

/// Canonical payload preparation for typed HIP-3 deployment operations.
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
