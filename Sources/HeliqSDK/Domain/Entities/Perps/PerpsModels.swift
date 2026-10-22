//
//  PerpsModels.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

// Protocol decimal strings are parsed without passing through binary floating point.
/// Parses a protocol decimal string without binary floating-point conversion.
func perpsDecimal(_ string: String) throws -> Decimal {
  guard !string.isEmpty,
    string.range(of: #"^-?[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil,
    string.filter({ $0.isNumber }).drop(while: { $0 == "0" }).count <= 38,
    let result = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")), !result.isNaN
  else {
    throw APIError.decodingFailed(underlying: nil)
  }
  return result
}

/// Encodes a finite decimal as a locale-independent protocol string.
func perpsDecimalString(_ decimal: Decimal) throws -> String {
  guard !decimal.isNaN else { throw ValidationError.malformedData(reason: "Amount is NaN") }
  var value = decimal
  return NSDecimalString(&value, Locale(identifier: "en_US_POSIX"))
}

extension KeyedDecodingContainer {
  /// Decodes a required protocol amount from a decimal string or JSON number.
  func protocolDecimal(_ key: Key) throws -> Decimal {
    if let text = try? decode(String.self, forKey: key) { return try perpsDecimal(text) }
    return try decode(Decimal.self, forKey: key)
  }
  /// Decodes an optional protocol amount, preserving missing and null values as nil.
  func optionalProtocolDecimal(_ key: Key) throws -> Decimal? {
    guard contains(key), try !decodeNil(forKey: key) else { return nil }
    return try protocolDecimal(key)
  }
  /// Decodes a list of protocol amounts without converting decimal strings through Double.
  func protocolDecimals(_ key: Key) throws -> [Decimal] {
    if let texts = try? decode([String].self, forKey: key) { return try texts.map(perpsDecimal) }
    return try decode([Decimal].self, forKey: key)
  }
}

/// Typed protocol response for Leverage.
public struct PerpsLeverage: Codable, Sendable {
  /// Protocol leverage mode, such as `cross` or `isolated`; retained without normalization.
  public let type: String
  /// Configured leverage multiplier, rather than a percentage.
  public let value: Int
  /// Raw USD margin reported for the leverage mode; nil when omitted or null.
  public let rawUsd: Decimal?
  enum CodingKeys: String, CodingKey { case type, value, rawUsd }
  /// Decodes leverage settings, accepting decimal strings or numbers for raw USD margin.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    value = try c.decode(Int.self, forKey: .value)
    rawUsd = try c.optionalProtocolDecimal(.rawUsd)
  }
}

/// Typed protocol response for Position.
public struct PerpsPosition: Codable, Sendable {
  /// Protocol market identifier, including any DEX prefix.
  public let coin: String
  /// Signed position size in base-asset units; positive is long and negative is short.
  public let szi: Decimal
  /// Average entry price in quote units per base unit; nil when unavailable.
  public let entryPx: Decimal?
  /// Unrealized profit or loss in the market's settlement units, preserving the server's sign.
  public let unrealizedPnl: Decimal
  /// Margin committed to this position in its collateral units.
  public let marginUsed: Decimal
  /// Configured leverage mode and multiplier for this position.
  public let leverage: PerpsLeverage
  /// Return on equity as a fractional ratio, not a percentage; nil when unavailable.
  public let returnOnEquity: Decimal?
  /// Estimated liquidation price in quote units per base unit; nil when unavailable.
  public let liquidationPx: Decimal?
  /// Position notional value in protocol quote units; nil when not supplied.
  public let positionValue: Decimal?
  /// Maximum leverage multiplier reported for this position; nil when not supplied.
  public let maxLeverage: Int?
  /// Funding totals over the server's reporting windows; nil when not supplied.
  public let cumFunding: PerpsCumulativeFunding?
  enum CodingKeys: String, CodingKey {
    case coin, szi, entryPx, unrealizedPnl, marginUsed, leverage, returnOnEquity, liquidationPx,
      positionValue, maxLeverage, cumFunding
  }
  /// Decodes a position, preserving absent optional metrics and parsing protocol decimals exactly.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    szi = try c.protocolDecimal(.szi)
    entryPx = try c.optionalProtocolDecimal(.entryPx)
    unrealizedPnl = try c.protocolDecimal(.unrealizedPnl)
    marginUsed = try c.protocolDecimal(.marginUsed)
    leverage = try c.decode(PerpsLeverage.self, forKey: .leverage)
    returnOnEquity = try c.optionalProtocolDecimal(.returnOnEquity)
    liquidationPx = try c.optionalProtocolDecimal(.liquidationPx)
    positionValue = try c.optionalProtocolDecimal(.positionValue)
    maxLeverage = try c.decodeIfPresent(Int.self, forKey: .maxLeverage)
    cumFunding = try c.decodeIfPresent(PerpsCumulativeFunding.self, forKey: .cumFunding)
  }
}

/// Typed protocol response for CumulativeFunding.
public struct PerpsCumulativeFunding: Codable, Sendable {
  /// All-time cumulative funding in settlement units, with the protocol's sign convention.
  public let allTime: Decimal
  /// Cumulative funding in settlement units since this position was opened.
  public let sinceOpen: Decimal
  /// Cumulative funding in settlement units since the most recent position change.
  public let sinceChange: Decimal
  enum CodingKeys: String, CodingKey { case allTime, sinceOpen, sinceChange }
  /// Decodes cumulative funding amounts from decimal strings or JSON numbers.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    allTime = try c.protocolDecimal(.allTime)
    sinceOpen = try c.protocolDecimal(.sinceOpen)
    sinceChange = try c.protocolDecimal(.sinceChange)
  }
}

/// Typed protocol response for MarginSummary.
public struct PerpsMarginSummary: Codable, Sendable {
  /// Account equity in the clearinghouse's collateral units for this summary.
  public let accountValue: Decimal
  /// Total committed margin in the clearinghouse's collateral units for this summary.
  public let totalMarginUsed: Decimal
  /// Aggregate position notional in protocol quote units; nil when omitted or null.
  public let totalNtlPos: Decimal?
  /// Raw USD balance before unrealized position PnL; nil when not supplied.
  public let totalRawUsd: Decimal?
  enum CodingKeys: String, CodingKey {
    case accountValue, totalMarginUsed, totalNtlPos, totalRawUsd
  }
  /// Decodes margin totals, preserving missing or null optional amounts as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    accountValue = try c.protocolDecimal(.accountValue)
    totalMarginUsed = try c.protocolDecimal(.totalMarginUsed)
    totalNtlPos = try c.optionalProtocolDecimal(.totalNtlPos)
    totalRawUsd = try c.optionalProtocolDecimal(.totalRawUsd)
  }
}

/// Typed protocol response for PositionEntry.
public struct PerpsPositionEntry: Codable, Sendable {
  /// Server position wrapper discriminator; nil when omitted or null.
  public let type: String?
  /// Position carried by this response entry.
  public let position: PerpsPosition
  enum CodingKeys: String, CodingKey { case type, position }
  /// Decodes a position wrapper with an optional protocol discriminator.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    position = try c.decode(PerpsPosition.self, forKey: .position)
  }
}

/// Typed protocol response for AccountState.
public struct PerpsAccountState: Codable, Sendable {
  /// Margin and equity totals across the returned clearinghouse account.
  public let marginSummary: PerpsMarginSummary
  /// Cross-margin-only totals; nil when not supplied.
  public let crossMarginSummary: PerpsMarginSummary?
  /// Cross-maintenance margin requirement in collateral units; nil when not supplied.
  public let crossMaintenanceMarginUsed: Decimal?
  /// Server-reported withdrawable collateral amount; nil means unavailable, not zero.
  public let withdrawable: Decimal?
  /// Positions reported by this clearinghouse snapshot.
  public let assetPositions: [PerpsPositionEntry]
  /// Snapshot time in Unix milliseconds; nil when not supplied.
  public let time: Int64?
  enum CodingKeys: String, CodingKey {
    case marginSummary, crossMarginSummary, crossMaintenanceMarginUsed, withdrawable,
      assetPositions, time
  }
  /// Decodes a clearinghouse snapshot without inferring unavailable margin or withdrawal metrics.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    marginSummary = try c.decode(PerpsMarginSummary.self, forKey: .marginSummary)
    crossMarginSummary = try c.decodeIfPresent(PerpsMarginSummary.self, forKey: .crossMarginSummary)
    crossMaintenanceMarginUsed = try c.optionalProtocolDecimal(.crossMaintenanceMarginUsed)
    withdrawable = try c.optionalProtocolDecimal(.withdrawable)
    assetPositions = try c.decode([PerpsPositionEntry].self, forKey: .assetPositions)
    time = try c.decodeIfPresent(Int64.self, forKey: .time)
  }
}

/// Typed protocol response for ActiveAssetData.
public struct PerpsActiveAssetData: Codable, Sendable {
  /// Account address whose trading capacity is being reported.
  public let user: String
  /// Protocol market identifier for this capacity snapshot.
  public let coin: String
  /// User's configured leverage for the market.
  public let leverage: PerpsLeverage
  /// Maximum trade sizes in base units, ordered buy then sell; decoding requires two entries.
  public let maxTradeSzs: [Decimal]
  /// Server trading capacity, ordered buy then sell; decoding requires two entries.
  /// Values are retained in protocol units without conversion to order size.
  public let availableToTrade: [Decimal]
  /// Mark price in quote units per base unit; nil when not supplied.
  public let markPx: Decimal?
  enum CodingKeys: String, CodingKey {
    case user, coin, leverage, maxTradeSzs, availableToTrade, markPx
  }
  /// Decodes trading capacity and rejects buy/sell arrays that do not contain exactly two values.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    user = try c.decode(String.self, forKey: .user)
    coin = try c.decode(String.self, forKey: .coin)
    leverage = try c.decode(PerpsLeverage.self, forKey: .leverage)
    maxTradeSzs = try c.protocolDecimals(.maxTradeSzs)
    availableToTrade = try c.protocolDecimals(.availableToTrade)
    markPx = try c.optionalProtocolDecimal(.markPx)
    guard availableToTrade.count == 2, maxTradeSzs.count == 2 else {
      throw APIError.invalidResponse
    }
  }
}

/// Typed protocol response for MarginTier.
public struct PerpsMarginTier: Codable, Sendable {
  /// Inclusive position-notional threshold in USD at which this tier begins.
  public let lowerBound: Decimal
  /// Maximum leverage multiplier allowed in this tier.
  public let maxLeverage: Int
  enum CodingKeys: String, CodingKey { case lowerBound, maxLeverage }
  /// Decodes a notional threshold and its required integer leverage limit.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    lowerBound = try c.protocolDecimal(.lowerBound)
    maxLeverage = try c.decode(Int.self, forKey: .maxLeverage)
  }
}

/// Typed protocol response for MarginTable.
public struct PerpsMarginTable: Codable, Sendable {
  /// Server-provided human-readable description of the margin schedule.
  public let description: String
  /// Notional thresholds and their corresponding leverage limits, in server order.
  public let marginTiers: [PerpsMarginTier]
  enum CodingKeys: String, CodingKey { case description, marginTiers }
  /// Decodes the margin schedule and description, retaining tier order.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    description = try c.decode(String.self, forKey: .description)
    marginTiers = try c.decode([PerpsMarginTier].self, forKey: .marginTiers)
  }
}

/// Typed protocol response for Asset.
public struct PerpsAsset: Codable, Sendable {
  /// Protocol market name, including a DEX prefix when present.
  public let name: String
  /// Number of decimal places supported for order size in base units.
  public let szDecimals: Int
  /// Market's maximum leverage multiplier.
  public let maxLeverage: Int
  /// Identifier of the applicable margin table; nil when not supplied.
  public let marginTableId: Int?
  /// Whether only isolated margin is allowed; nil means the server did not specify it.
  public let onlyIsolated: Bool?
  /// Whether the market is delisted; nil is unspecified rather than false.
  public let isDelisted: Bool?
  /// Raw protocol margin-mode label; nil when not supplied.
  public let marginMode: String?
  /// Raw protocol growth-mode label; nil when not supplied.
  public let growthMode: String?
  /// Last growth-mode change time in the server's string representation; nil if unavailable.
  /// No timestamp format or unit conversion is applied.
  public let lastGrowthModeChangeTime: String?
  enum CodingKeys: String, CodingKey {
    case name, szDecimals, maxLeverage, marginTableId, onlyIsolated, isDelisted, marginMode,
      growthMode, lastGrowthModeChangeTime
  }
  /// Decodes market metadata without defaulting absent flags or normalizing mode strings.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    name = try c.decode(String.self, forKey: .name)
    szDecimals = try c.decode(Int.self, forKey: .szDecimals)
    maxLeverage = try c.decode(Int.self, forKey: .maxLeverage)
    marginTableId = try c.decodeIfPresent(Int.self, forKey: .marginTableId)
    onlyIsolated = try c.decodeIfPresent(Bool.self, forKey: .onlyIsolated)
    isDelisted = try c.decodeIfPresent(Bool.self, forKey: .isDelisted)
    marginMode = try c.decodeIfPresent(String.self, forKey: .marginMode)
    growthMode = try c.decodeIfPresent(String.self, forKey: .growthMode)
    lastGrowthModeChangeTime = try c.decodeIfPresent(String.self, forKey: .lastGrowthModeChangeTime)
  }
}

/// Typed protocol response for Meta.
public struct PerpsMeta: Codable, Sendable {
  /// Markets in protocol asset-index order for this DEX.
  public let universe: [PerpsAsset]
  /// Margin tables keyed by their protocol IDs; nil when not supplied.
  public let marginTables: [PerpsMarginTableEntry]?
  /// Spot token index used as collateral; nil when not supplied, without assuming USDC.
  public let collateralToken: Int?
  enum CodingKeys: String, CodingKey { case universe, marginTables, collateralToken }
  /// Decodes the market universe and optional margin-table and collateral metadata.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    universe = try c.decode([PerpsAsset].self, forKey: .universe)
    marginTables = try c.decodeIfPresent([PerpsMarginTableEntry].self, forKey: .marginTables)
    collateralToken = try c.decodeIfPresent(Int.self, forKey: .collateralToken)
  }
}

/// Typed protocol response for AssetContext.
public struct PerpsAssetContext: Codable, Sendable {
  /// Trailing-day trading notional in USD.
  public let dayNtlVlm: Decimal
  /// Current funding rate as a fractional ratio, not a percentage.
  public let funding: Decimal
  /// Mark price in quote units per base unit.
  public let markPx: Decimal
  /// Order-book midpoint price; nil when the server cannot provide one or omits it.
  public let midPx: Decimal?
  /// Outstanding open interest in base-asset units.
  public let openInterest: Decimal
  /// Oracle reference price in quote units per base unit.
  public let oraclePx: Decimal
  /// Reference price from the previous day, in quote units per base unit.
  public let prevDayPx: Decimal
  /// Premium ratio reported by the server; nil when omitted or null.
  public let premium: Decimal?
  /// Impact bid and ask prices in protocol order; nil when unavailable.
  public let impactPxs: [Decimal]?
  enum CodingKeys: String, CodingKey {
    case dayNtlVlm, funding, markPx, midPx, openInterest, oraclePx, prevDayPx, premium, impactPxs
  }
  /// Decodes market metrics using exact protocol decimals and preserves unavailable prices as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    dayNtlVlm = try c.protocolDecimal(.dayNtlVlm)
    funding = try c.protocolDecimal(.funding)
    markPx = try c.protocolDecimal(.markPx)
    midPx = try c.optionalProtocolDecimal(.midPx)
    openInterest = try c.protocolDecimal(.openInterest)
    oraclePx = try c.protocolDecimal(.oraclePx)
    prevDayPx = try c.protocolDecimal(.prevDayPx)
    premium = try c.optionalProtocolDecimal(.premium)
    impactPxs =
      try c.contains(.impactPxs) && !c.decodeNil(forKey: .impactPxs)
      ? c.protocolDecimals(.impactPxs) : nil
  }
}

/// Typed protocol response for Dex.
public struct PerpsDex: Codable, Sendable {
  /// Short protocol DEX identifier used in market prefixes and requests.
  public let name: String
  /// Human-readable DEX name supplied by the server.
  public let fullName: String
  /// Address responsible for deploying the DEX.
  public let deployer: String
  /// Oracle updater address; nil when not supplied.
  public let oracleUpdater: String?
  /// Address receiving DEX fees; nil when not supplied.
  public let feeRecipient: String?
  /// Asset-keyed streaming open-interest caps in protocol units; nil when not supplied.
  public let assetToStreamingOiCap: [PerpsDecimalPair]?
  /// Asset-keyed funding multipliers, not percentage rates; nil when not supplied.
  public let assetToFundingMultiplier: [PerpsDecimalPair]?
  enum CodingKeys: String, CodingKey {
    case name, fullName, deployer, oracleUpdater, feeRecipient, assetToStreamingOiCap,
      assetToFundingMultiplier
  }
  /// Decodes DEX identity and optional asset-keyed limit and funding configuration.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    name = try c.decode(String.self, forKey: .name)
    fullName = try c.decode(String.self, forKey: .fullName)
    deployer = try c.decode(String.self, forKey: .deployer)
    oracleUpdater = try c.decodeIfPresent(String.self, forKey: .oracleUpdater)
    feeRecipient = try c.decodeIfPresent(String.self, forKey: .feeRecipient)
    assetToStreamingOiCap = try c.decodeIfPresent(
      [PerpsDecimalPair].self, forKey: .assetToStreamingOiCap)
    assetToFundingMultiplier = try c.decodeIfPresent(
      [PerpsDecimalPair].self, forKey: .assetToFundingMultiplier)
  }
}

/// Typed protocol response for Funding.
public struct PerpsFunding: Codable, Sendable {
  /// Protocol market identifier to which the funding observation applies.
  public let coin: String
  /// Funding rate as a fractional ratio for the reported interval.
  public let fundingRate: Decimal
  /// Premium ratio used in the funding observation.
  public let premium: Decimal
  /// Funding observation time in Unix milliseconds.
  public let time: Int64
  enum CodingKeys: String, CodingKey { case coin, fundingRate, premium, time }
  /// Decodes a historical funding observation with exact decimal rates.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    fundingRate = try c.protocolDecimal(.fundingRate)
    premium = try c.protocolDecimal(.premium)
    time = try c.decode(Int64.self, forKey: .time)
  }
}

/// Typed protocol response for PredictedFunding.
public struct PerpsPredictedFunding: Codable, Sendable {
  /// Predicted funding rate as a fractional ratio for this venue's interval.
  public let fundingRate: Decimal
  /// Next funding time in Unix milliseconds; nil when not supplied.
  public let nextFundingTime: Int64?
  /// Length of the venue's funding interval in hours; nil when not supplied.
  public let fundingIntervalHours: Int?
  enum CodingKeys: String, CodingKey { case fundingRate, nextFundingTime, fundingIntervalHours }
  /// Decodes a funding prediction without inventing a missing funding time or interval.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    fundingRate = try c.protocolDecimal(.fundingRate)
    nextFundingTime = try c.decodeIfPresent(Int64.self, forKey: .nextFundingTime)
    fundingIntervalHours = try c.decodeIfPresent(Int.self, forKey: .fundingIntervalHours)
  }
}

/// Typed protocol response for DeployAuction.
public struct PerpsDeployAuction: Codable, Sendable {
  /// Auction start time in Unix seconds, not milliseconds.
  public let startTimeSeconds: Int64
  /// Auction duration in seconds.
  public let durationSeconds: Int64
  /// Initial deployment gas price in the protocol's gas-price units.
  public let startGas: Decimal
  /// Current deployment gas price in the same units as `startGas`.
  public let currentGas: Decimal
  /// Ending deployment gas price; nil when not supplied.
  public let endGas: Decimal?
  enum CodingKeys: String, CodingKey {
    case startTimeSeconds, durationSeconds, startGas, currentGas, endGas
  }
  /// Decodes auction times in seconds and gas prices from protocol decimals.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    startTimeSeconds = try c.decode(Int64.self, forKey: .startTimeSeconds)
    durationSeconds = try c.decode(Int64.self, forKey: .durationSeconds)
    startGas = try c.protocolDecimal(.startGas)
    currentGas = try c.protocolDecimal(.currentGas)
    endGas = try c.optionalProtocolDecimal(.endGas)
  }
}

/// Typed protocol response for DexLimits.
public struct PerpsDexLimits: Codable, Sendable {
  /// Aggregate open-interest notional cap in USD for the DEX.
  public let totalOiCap: Decimal
  /// Per-market open-interest size cap in base-asset units.
  public let oiSzCapPerPerp: Decimal
  /// Maximum transfer notional in USD.
  public let maxTransferNtl: Decimal
  /// Market-keyed open-interest notional caps in USD.
  public let coinToOiCap: [PerpsDecimalPair]
  enum CodingKeys: String, CodingKey {
    case totalOiCap, oiSzCapPerPerp, maxTransferNtl, coinToOiCap
  }
  /// Decodes DEX-wide and per-market limits without rescaling the server's amounts.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    totalOiCap = try c.protocolDecimal(.totalOiCap)
    oiSzCapPerPerp = try c.protocolDecimal(.oiSzCapPerPerp)
    maxTransferNtl = try c.protocolDecimal(.maxTransferNtl)
    coinToOiCap = try c.decode([PerpsDecimalPair].self, forKey: .coinToOiCap)
  }
}

/// Typed protocol response for DexStatus.
public struct PerpsDexStatus: Codable, Sendable {
  /// Net deposits reported for the DEX, retained in protocol notional units.
  public let totalNetDeposit: Decimal
  enum CodingKeys: String, CodingKey { case totalNetDeposit }
  /// Decodes DEX deposit status from a required protocol decimal amount.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    totalNetDeposit = try c.protocolDecimal(.totalNetDeposit)
  }
}

/// Typed protocol response for Annotation.
public struct PerpsAnnotation: Codable, Sendable {
  /// Server classification label for the annotated market.
  public let category: String
  /// Optional explanatory text; nil when omitted or null.
  public let description: String?
  /// Optional human-readable market label; nil when not supplied.
  public let displayName: String?
  /// Search keywords supplied by the server; nil is distinct from an empty list.
  public let keywords: [String]?
  enum CodingKeys: String, CodingKey { case category, description, displayName, keywords }
  /// Decodes market classification and preserves absent display and search metadata as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    category = try c.decode(String.self, forKey: .category)
    description = try c.decodeIfPresent(String.self, forKey: .description)
    displayName = try c.decodeIfPresent(String.self, forKey: .displayName)
    keywords = try c.decodeIfPresent([String].self, forKey: .keywords)
  }
}

/// Typed protocol response for SpotBalance.
public struct PerpsSpotBalance: Codable, Sendable {
  /// Token symbol as returned by the protocol.
  public let coin: String
  /// Token index in Spot metadata.
  public let token: Int
  /// Total balance in token units, including held funds.
  public let total: Decimal
  /// Held portion of the total in token units, not an additional balance.
  public let hold: Decimal
  /// Entry notional reported for this holding; nil when not supplied.
  public let entryNtl: Decimal?
  enum CodingKeys: String, CodingKey { case coin, token, total, hold, entryNtl }
  /// Decodes Spot holdings without combining held funds with total or entry notional.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    token = try c.decode(Int.self, forKey: .token)
    total = try c.protocolDecimal(.total)
    hold = try c.protocolDecimal(.hold)
    entryNtl = try c.optionalProtocolDecimal(.entryNtl)
  }
}

/// Typed protocol response for SpotState.
public struct PerpsSpotState: Codable, Sendable {
  /// Token holdings returned by the Spot clearinghouse.
  public let balances: [PerpsSpotBalance]
  /// Per-token availability after maintenance requirements, in token units.
  /// Nil means this information was not supplied, not that all balances are unavailable.
  public let tokenToAvailableAfterMaintenance: [PerpsTokenAvailability]?
  enum CodingKeys: String, CodingKey { case balances, tokenToAvailableAfterMaintenance }
  /// Decodes Spot holdings and any token-indexed maintenance availability tuples.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    balances = try c.decode([PerpsSpotBalance].self, forKey: .balances)
    tokenToAvailableAfterMaintenance = try c.decodeIfPresent(
      [PerpsTokenAvailability].self, forKey: .tokenToAvailableAfterMaintenance)
  }
}

/// Typed protocol response for UserFees.
public struct PerpsUserFees: Codable, Sendable {
  /// Daily trading volumes used to determine the user's fee tier.
  public let dailyUserVlm: [PerpsDailyVolume]
  /// Base fee rates, tier thresholds, and available discounts.
  public let feeSchedule: PerpsFeeSchedule
  /// User's effective perpetual taker fee rate as a fraction of traded notional.
  public let userCrossRate: Decimal
  /// User's effective perpetual maker fee rate as a fraction of traded notional.
  public let userAddRate: Decimal
  /// Effective Spot taker fee fraction; nil when not supplied.
  public let userSpotCrossRate: Decimal?
  /// Effective Spot maker fee fraction; nil when not supplied.
  public let userSpotAddRate: Decimal?
  /// Active referral discount fraction; nil when not supplied.
  public let activeReferralDiscount: Decimal?
  /// Fee-trial reward in server-defined units; nil when not supplied.
  public let feeTrialReward: Decimal?
  /// Active staking discount details; nil when not supplied.
  public let activeStakingDiscount: PerpsStakingDiscount?
  /// Unmodeled fee-trial details preserved as JSON; nil for an absent or null payload.
  public let trial: JSONValue?
  /// Next trial eligibility timestamp in the server's raw units; nil when unavailable.
  public let nextTrialAvailableTimestamp: Int64?
  /// Staking account relationship used for fee discounts; nil when not supplied.
  public let stakingLink: PerpsStakingLink?
  enum CodingKeys: String, CodingKey {
    case dailyUserVlm, feeSchedule, userCrossRate, userAddRate, userSpotCrossRate, userSpotAddRate,
      activeReferralDiscount, feeTrialReward, activeStakingDiscount, trial,
      nextTrialAvailableTimestamp, stakingLink
  }
  /// Decodes fee rates and discounts while preserving unmodeled trial details as JSON.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    dailyUserVlm = try c.decode([PerpsDailyVolume].self, forKey: .dailyUserVlm)
    feeSchedule = try c.decode(PerpsFeeSchedule.self, forKey: .feeSchedule)
    userCrossRate = try c.protocolDecimal(.userCrossRate)
    userAddRate = try c.protocolDecimal(.userAddRate)
    userSpotCrossRate = try c.optionalProtocolDecimal(.userSpotCrossRate)
    userSpotAddRate = try c.optionalProtocolDecimal(.userSpotAddRate)
    activeReferralDiscount = try c.optionalProtocolDecimal(.activeReferralDiscount)
    feeTrialReward = try c.optionalProtocolDecimal(.feeTrialReward)
    activeStakingDiscount = try c.decodeIfPresent(
      PerpsStakingDiscount.self, forKey: .activeStakingDiscount)
    trial = try c.decodeIfPresent(JSONValue.self, forKey: .trial)
    nextTrialAvailableTimestamp = try c.decodeIfPresent(
      Int64.self, forKey: .nextTrialAvailableTimestamp)
    stakingLink = try c.decodeIfPresent(PerpsStakingLink.self, forKey: .stakingLink)
  }
}

/// Typed protocol response for DailyVolume.
public struct PerpsDailyVolume: Codable, Sendable {
  /// Trading-day label in the server's date-string representation.
  public let date: String
  /// User's taker trading notional in USD for the day.
  public let userCross: Decimal
  /// User's maker trading notional in USD for the day.
  public let userAdd: Decimal
  /// Exchange trading notional in USD for the day.
  public let exchange: Decimal
  enum CodingKeys: String, CodingKey { case date, userCross, userAdd, exchange }
  /// Decodes a daily volume record without converting the server's date label.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    date = try c.decode(String.self, forKey: .date)
    userCross = try c.protocolDecimal(.userCross)
    userAdd = try c.protocolDecimal(.userAdd)
    exchange = try c.protocolDecimal(.exchange)
  }
}

/// Typed protocol response for FeeSchedule.
public struct PerpsFeeSchedule: Codable, Sendable {
  /// Base perpetual taker fee as a fraction of traded notional.
  public let cross: Decimal
  /// Base perpetual maker fee as a fraction of traded notional.
  public let add: Decimal
  /// Base Spot taker fee fraction; nil when not supplied.
  public let spotCross: Decimal?
  /// Base Spot maker fee fraction; nil when not supplied.
  public let spotAdd: Decimal?
  /// Referral discount fraction; nil when not supplied.
  public let referralDiscount: Decimal?
  /// Available staking discount levels; nil when not supplied.
  public let stakingDiscountTiers: [PerpsStakingDiscount]?
  /// Volume-based VIP and market-maker fee tiers.
  public let tiers: PerpsFeeTiers
  enum CodingKeys: String, CodingKey {
    case cross, add, spotCross, spotAdd, referralDiscount, stakingDiscountTiers, tiers
  }
  /// Decodes base fees and tier schedules, leaving unavailable optional discounts as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cross = try c.protocolDecimal(.cross)
    add = try c.protocolDecimal(.add)
    spotCross = try c.optionalProtocolDecimal(.spotCross)
    spotAdd = try c.optionalProtocolDecimal(.spotAdd)
    referralDiscount = try c.optionalProtocolDecimal(.referralDiscount)
    stakingDiscountTiers = try c.decodeIfPresent(
      [PerpsStakingDiscount].self, forKey: .stakingDiscountTiers)
    tiers = try c.decode(PerpsFeeTiers.self, forKey: .tiers)
  }
}

/// Typed protocol response for FeeTiers.
public struct PerpsFeeTiers: Codable, Sendable {
  /// VIP fee tiers selected by trading-notional thresholds.
  public let vip: [PerpsVipTier]
  /// Market-maker fee tiers selected by maker-volume share.
  public let mm: [PerpsMakerTier]
  enum CodingKeys: String, CodingKey { case vip, mm }
  /// Decodes the required VIP and market-maker tier lists in server order.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    vip = try c.decode([PerpsVipTier].self, forKey: .vip)
    mm = try c.decode([PerpsMakerTier].self, forKey: .mm)
  }
}

/// Typed protocol response for VipTier.
public struct PerpsVipTier: Codable, Sendable {
  /// Trading-notional threshold in USD for this fee tier.
  public let ntlCutoff: Decimal
  /// Perpetual taker fee fraction for this tier.
  public let cross: Decimal
  /// Perpetual maker fee fraction for this tier.
  public let add: Decimal
  /// Spot taker fee fraction for this tier; nil when not supplied.
  public let spotCross: Decimal?
  /// Spot maker fee fraction for this tier; nil when not supplied.
  public let spotAdd: Decimal?
  enum CodingKeys: String, CodingKey { case ntlCutoff, cross, add, spotCross, spotAdd }
  /// Decodes a notional-based fee tier with optional Spot rates.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    ntlCutoff = try c.protocolDecimal(.ntlCutoff)
    cross = try c.protocolDecimal(.cross)
    add = try c.protocolDecimal(.add)
    spotCross = try c.optionalProtocolDecimal(.spotCross)
    spotAdd = try c.optionalProtocolDecimal(.spotAdd)
  }
}

/// Typed protocol response for MakerTier.
public struct PerpsMakerTier: Codable, Sendable {
  /// Required fraction of maker volume to qualify for this tier.
  public let makerFractionCutoff: Decimal
  /// Maker fee fraction of traded notional, preserving any rebate sign.
  public let add: Decimal
  enum CodingKeys: String, CodingKey { case makerFractionCutoff, add }
  /// Decodes the maker-volume share threshold and corresponding maker fee fraction.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    makerFractionCutoff = try c.protocolDecimal(.makerFractionCutoff)
    add = try c.protocolDecimal(.add)
  }
}

/// Typed protocol response for StakingLink.
public struct PerpsStakingLink: Codable, Sendable {
  /// Raw discriminator describing the staking-account relationship.
  public let type: String
  /// Address of the linked staking account.
  public let stakingUser: String
  enum CodingKeys: String, CodingKey { case type, stakingUser }
  /// Decodes the raw staking relationship type and linked account address.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    stakingUser = try c.decode(String.self, forKey: .stakingUser)
  }
}

/// Typed protocol response for TwapState.
public struct PerpsTwapState: Codable, Sendable {
  /// Protocol market identifier for the time-weighted average price order.
  public let coin: String
  /// Address owning the TWAP order.
  public let user: String
  /// Protocol side code: `B` for buy or `A` for sell.
  public let side: String
  /// Total requested order size in base-asset units.
  public let sz: Decimal
  /// Size already executed in base-asset units.
  public let executedSz: Decimal
  /// Executed notional in quote units.
  public let executedNtl: Decimal
  /// Requested execution duration in minutes.
  public let minutes: Int
  /// Whether executions may only reduce the existing position.
  public let reduceOnly: Bool
  /// Whether execution timing is randomized by the protocol.
  public let randomize: Bool
  /// TWAP creation time in Unix milliseconds.
  public let timestamp: Int64
  enum CodingKeys: String, CodingKey {
    case coin, user, side, sz, executedSz, executedNtl, minutes, reduceOnly, randomize, timestamp
  }
  /// Decodes TWAP execution progress, retaining server sizes, flags, and timestamp.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    user = try c.decode(String.self, forKey: .user)
    side = try c.decode(String.self, forKey: .side)
    sz = try c.protocolDecimal(.sz)
    executedSz = try c.protocolDecimal(.executedSz)
    executedNtl = try c.protocolDecimal(.executedNtl)
    minutes = try c.decode(Int.self, forKey: .minutes)
    reduceOnly = try c.decode(Bool.self, forKey: .reduceOnly)
    randomize = try c.decode(Bool.self, forKey: .randomize)
    timestamp = try c.decode(Int64.self, forKey: .timestamp)
  }
}

/// Typed protocol response for TwapHistoryEntry.
public struct PerpsTwapHistoryEntry: Codable, Sendable {
  /// TWAP execution state associated with this history event.
  public let state: PerpsTwapState
  /// Server status and any explanatory text for the event.
  public let status: PerpsTwapStatus
  /// History event time in Unix milliseconds.
  public let time: Int64
  enum CodingKeys: String, CodingKey { case state, status, time }
  /// Decodes a timestamped TWAP state and status event.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    state = try c.decode(PerpsTwapState.self, forKey: .state)
    status = try c.decode(PerpsTwapStatus.self, forKey: .status)
    time = try c.decode(Int64.self, forKey: .time)
  }
}

/// Typed protocol response for TwapStatus.
public struct PerpsTwapStatus: Codable, Sendable {
  /// Raw TWAP status label, preserving values introduced by the server.
  public let status: String
  /// Additional status explanation; nil when omitted or null.
  public let description: String?
  enum CodingKeys: String, CodingKey { case status, description }
  /// Decodes a raw TWAP status label and optional explanation without restricting future labels.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    status = try c.decode(String.self, forKey: .status)
    description = try c.decodeIfPresent(String.self, forKey: .description)
  }
}

/// Typed protocol response for Fill.
public struct PerpsFill: Codable, Sendable {
  /// Realized profit or loss from closing exposure, in the market's settlement units.
  public let closedPnl: Decimal
  /// Protocol market identifier for the execution.
  public let coin: String
  /// Whether the order crossed the book and took liquidity.
  public let crossed: Bool
  /// Server description of the position effect, such as opening or closing a long.
  public let dir: String
  /// Protocol transaction hash associated with the execution.
  public let hash: String
  /// Exchange-assigned identifier of the filled order.
  public let oid: Int64
  /// Execution price in quote units per base unit.
  public let px: Decimal
  /// Protocol side code: `B` for buy or `A` for sell.
  public let side: String
  /// Signed position size in base units immediately before this fill.
  public let startPosition: Decimal
  /// Executed size in base-asset units.
  public let sz: Decimal
  /// Execution time in Unix milliseconds.
  public let time: Int64
  /// Execution fee in `feeToken` units when specified, preserving any rebate sign.
  public let fee: Decimal
  /// Token in which the fee is denominated; nil when the server does not identify it.
  public let feeToken: String?
  /// Builder fee reported for this fill; nil when not supplied.
  public let builderFee: Decimal?
  /// Exchange-assigned trade identifier.
  public let tid: Int64
  enum CodingKeys: String, CodingKey {
    case closedPnl, coin, crossed, dir, hash, oid, px, side, startPosition, sz, time, fee, feeToken,
      builderFee, tid
  }
  /// Decodes an execution with exact decimal amounts and optional fee-token and builder details.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    closedPnl = try c.protocolDecimal(.closedPnl)
    coin = try c.decode(String.self, forKey: .coin)
    crossed = try c.decode(Bool.self, forKey: .crossed)
    dir = try c.decode(String.self, forKey: .dir)
    hash = try c.decode(String.self, forKey: .hash)
    oid = try c.decode(Int64.self, forKey: .oid)
    px = try c.protocolDecimal(.px)
    side = try c.decode(String.self, forKey: .side)
    startPosition = try c.protocolDecimal(.startPosition)
    sz = try c.protocolDecimal(.sz)
    time = try c.decode(Int64.self, forKey: .time)
    fee = try c.protocolDecimal(.fee)
    feeToken = try c.decodeIfPresent(String.self, forKey: .feeToken)
    builderFee = try c.optionalProtocolDecimal(.builderFee)
    tid = try c.decode(Int64.self, forKey: .tid)
  }
}

/// Typed protocol response for TwapSliceFill.
public struct PerpsTwapSliceFill: Codable, Sendable {
  /// Execution generated by one slice of the parent TWAP.
  public let fill: PerpsFill
  /// Exchange-assigned identifier of the parent TWAP order.
  public let twapId: Int64
  enum CodingKeys: String, CodingKey { case fill, twapId }
  /// Decodes a fill and the identifier of the TWAP that generated it.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    fill = try c.decode(PerpsFill.self, forKey: .fill)
    twapId = try c.decode(Int64.self, forKey: .twapId)
  }
}

/// Typed protocol response for HistoricalOrder.
public struct PerpsHistoricalOrder: Codable, Sendable {
  /// Order details associated with the status update.
  public let order: PerpsOrder
  /// Raw server order-status label, including cancellation or rejection reasons.
  public let status: String
  /// Time of the status update in Unix milliseconds.
  public let statusTimestamp: Int64
  enum CodingKeys: String, CodingKey { case order, status, statusTimestamp }
  /// Decodes historical order details with their status label and update timestamp.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    order = try c.decode(PerpsOrder.self, forKey: .order)
    status = try c.decode(String.self, forKey: .status)
    statusTimestamp = try c.decode(Int64.self, forKey: .statusTimestamp)
  }
}

/// Typed protocol response for Order.
public struct PerpsOrder: Codable, Sendable {
  /// Protocol market identifier for the order.
  public let coin: String
  /// Protocol side code: `B` for buy or `A` for sell.
  public let side: String
  /// Limit price in quote units per base unit.
  public let limitPx: Decimal
  /// Remaining order size in base-asset units.
  public let sz: Decimal
  /// Exchange-assigned order identifier.
  public let oid: Int64
  /// Order timestamp in Unix milliseconds.
  public let timestamp: Int64
  /// Original order size in base units; nil when not supplied.
  public let origSz: Decimal?
  /// Client-assigned order identifier; nil when not supplied.
  public let cloid: String?
  /// Whether the order may only reduce exposure; nil is unspecified, not false.
  public let reduceOnly: Bool?
  /// Whether the order is trigger-based; nil when not supplied.
  public let isTrigger: Bool?
  /// Whether the order is a position-level take-profit or stop-loss; nil when not supplied.
  public let isPositionTpsl: Bool?
  /// Trigger price in quote units per base unit; nil when not supplied.
  public let triggerPx: Decimal?
  /// Server description of the trigger condition; nil when not supplied.
  public let triggerCondition: String?
  /// Raw protocol order-type label; nil when not supplied.
  public let orderType: String?
  /// Raw time-in-force code; nil when not supplied.
  public let tif: String?
  enum CodingKeys: String, CodingKey {
    case coin, side, limitPx, sz, oid, timestamp, origSz, cloid, reduceOnly, isTrigger,
      isPositionTpsl, triggerPx, triggerCondition, orderType, tif
  }
  /// Decodes common order fields and preserves omitted extended order attributes as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    side = try c.decode(String.self, forKey: .side)
    limitPx = try c.protocolDecimal(.limitPx)
    sz = try c.protocolDecimal(.sz)
    oid = try c.decode(Int64.self, forKey: .oid)
    timestamp = try c.decode(Int64.self, forKey: .timestamp)
    origSz = try c.optionalProtocolDecimal(.origSz)
    cloid = try c.decodeIfPresent(String.self, forKey: .cloid)
    reduceOnly = try c.decodeIfPresent(Bool.self, forKey: .reduceOnly)
    isTrigger = try c.decodeIfPresent(Bool.self, forKey: .isTrigger)
    isPositionTpsl = try c.decodeIfPresent(Bool.self, forKey: .isPositionTpsl)
    triggerPx = try c.optionalProtocolDecimal(.triggerPx)
    triggerCondition = try c.decodeIfPresent(String.self, forKey: .triggerCondition)
    orderType = try c.decodeIfPresent(String.self, forKey: .orderType)
    tif = try c.decodeIfPresent(String.self, forKey: .tif)
  }
}

/// Typed protocol response for ApprovedAgent.
public struct PerpsApprovedAgent: Codable, Sendable {
  /// Address of the approved agent wallet.
  public let address: String
  /// Server-provided label for the agent.
  public let name: String
  /// Approval expiration timestamp retained in the protocol's raw units.
  public let validUntil: Int64
  enum CodingKeys: String, CodingKey { case address, name, validUntil }
  /// Decodes an agent approval without converting the protocol expiration timestamp.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    address = try c.decode(String.self, forKey: .address)
    name = try c.decode(String.self, forKey: .name)
    validUntil = try c.decode(Int64.self, forKey: .validUntil)
  }
}

/// Typed protocol response for ApprovedBuilder.
public struct PerpsApprovedBuilder: Codable, Sendable {
  /// Address of the builder authorized to receive fees.
  public let builder: String
  /// Approved fee-rate ceiling in the protocol's integer rate units, without rescaling.
  public let maxFeeRate: Int
  enum CodingKeys: String, CodingKey { case builder, maxFeeRate }
  /// Decodes a builder approval while retaining the integer fee ceiling without rescaling.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    builder = try c.decode(String.self, forKey: .builder)
    maxFeeRate = try c.decode(Int.self, forKey: .maxFeeRate)
  }
}

/// Typed protocol response for UserRole.
public struct PerpsUserRole: Codable, Sendable {
  /// Raw account-role label; unknown future labels remain intact.
  public let role: String
  /// Role-specific account relationships; nil when omitted or null.
  public let data: PerpsRoleData?
  enum CodingKeys: String, CodingKey { case role, data }
  /// Decodes an unrestricted role label and any role-specific account data.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    role = try c.decode(String.self, forKey: .role)
    data = try c.decodeIfPresent(PerpsRoleData.self, forKey: .data)
  }
}

/// Typed protocol response for RoleData.
public struct PerpsRoleData: Codable, Sendable {
  /// Related user address for roles that supply one; nil otherwise.
  public let user: String?
  /// Master account address for roles that supply one; nil otherwise.
  public let master: String?
  /// Role-specific account label; nil when not supplied.
  public let name: String?
  /// Authorized signer addresses for a multisignature role; nil when not supplied.
  public let authorizedUsers: [String]?
  /// Required authorization count for a multisignature role; nil when not supplied.
  public let threshold: Int?
  enum CodingKeys: String, CodingKey { case user, master, name, authorizedUsers, threshold }
  /// Decodes role-specific fields, preserving absent or null relationships as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    user = try c.decodeIfPresent(String.self, forKey: .user)
    master = try c.decodeIfPresent(String.self, forKey: .master)
    name = try c.decodeIfPresent(String.self, forKey: .name)
    authorizedUsers = try c.decodeIfPresent([String].self, forKey: .authorizedUsers)
    threshold = try c.decodeIfPresent(Int.self, forKey: .threshold)
  }
}

/// Typed protocol response for LedgerEntry.
public struct PerpsLedgerEntry: Codable, Sendable {
  /// Ledger event time in Unix milliseconds.
  public let time: Int64
  /// Protocol transaction hash associated with the event.
  public let hash: String
  /// Type-discriminated balance movement reported by the ledger.
  public let delta: PerpsLedgerDelta
  enum CodingKeys: String, CodingKey { case time, hash, delta }
  /// Decodes a timestamped ledger movement and its protocol transaction hash.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    time = try c.decode(Int64.self, forKey: .time)
    hash = try c.decode(String.self, forKey: .hash)
    delta = try c.decode(PerpsLedgerDelta.self, forKey: .delta)
  }
}

/// Typed protocol response for LedgerDelta.
public struct PerpsLedgerDelta: Codable, Sendable {
  /// Raw ledger event discriminator that determines which optional fields apply.
  public let type: String
  /// USDC-denominated amount when applicable; nil when omitted or null.
  public let usdc: Decimal?
  /// Movement amount in the event's token units; nil when not supplied.
  public let amount: Decimal?
  /// Event fee in the denomination defined by its type; nil when not supplied.
  public let fee: Decimal?
  /// Protocol token identifier for token-specific movements; nil when not supplied.
  public let token: String?
  /// User address associated with the movement; nil when not supplied.
  public let user: String?
  /// Destination address for event types that report one; nil otherwise.
  public let destination: String?
  /// Source address for event types that report one; nil otherwise.
  public let source: String?
  /// Vault address for vault movements; nil when not supplied.
  public let vault: String?
  /// Whether a vault movement is a deposit; nil when the event does not specify it.
  public let isDeposit: Bool?
  /// Whether a class transfer moves toward perpetuals; nil when not supplied.
  public let toPerp: Bool?
  /// Subaccount address associated with a transfer; nil when not supplied.
  public let subAccount: String?
  /// Source DEX identifier for a DEX transfer; nil when not supplied.
  public let sourceDex: String?
  /// Destination DEX identifier for a DEX transfer; nil when not supplied.
  public let destinationDex: String?
  /// Protocol nonce identifying the movement; nil when not supplied, not a derived timestamp.
  public let nonce: Int64?
  enum CodingKeys: String, CodingKey {
    case type, usdc, amount, fee, token, user, destination, source, vault, isDeposit, toPerp,
      subAccount, sourceDex, destinationDex, nonce
  }
  /// Decodes the ledger discriminator and supplied fields without inferring missing event data.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    usdc = try c.optionalProtocolDecimal(.usdc)
    amount = try c.optionalProtocolDecimal(.amount)
    fee = try c.optionalProtocolDecimal(.fee)
    token = try c.decodeIfPresent(String.self, forKey: .token)
    user = try c.decodeIfPresent(String.self, forKey: .user)
    destination = try c.decodeIfPresent(String.self, forKey: .destination)
    source = try c.decodeIfPresent(String.self, forKey: .source)
    vault = try c.decodeIfPresent(String.self, forKey: .vault)
    isDeposit = try c.decodeIfPresent(Bool.self, forKey: .isDeposit)
    toPerp = try c.decodeIfPresent(Bool.self, forKey: .toPerp)
    subAccount = try c.decodeIfPresent(String.self, forKey: .subAccount)
    sourceDex = try c.decodeIfPresent(String.self, forKey: .sourceDex)
    destinationDex = try c.decodeIfPresent(String.self, forKey: .destinationDex)
    nonce = try c.decodeIfPresent(Int64.self, forKey: .nonce)
  }
}

/// Typed protocol response for PortfolioValue.
public struct PerpsPortfolioValue: Codable, Sendable {
  /// Account equity history as Unix-millisecond and USD-value pairs.
  public let accountValueHistory: [PerpsTimeValue]
  /// Profit-and-loss history as Unix-millisecond and USD-value pairs.
  public let pnlHistory: [PerpsTimeValue]
  /// Trading notional in USD for this portfolio period.
  public let vlm: Decimal
  enum CodingKeys: String, CodingKey { case accountValueHistory, pnlHistory, vlm }
  /// Decodes portfolio histories as timestamp/value tuples and a protocol-decimal volume.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    accountValueHistory = try c.decode([PerpsTimeValue].self, forKey: .accountValueHistory)
    pnlHistory = try c.decode([PerpsTimeValue].self, forKey: .pnlHistory)
    vlm = try c.protocolDecimal(.vlm)
  }
}

/// Typed protocol response for UserFunding.
public struct PerpsUserFunding: Codable, Sendable {
  /// Funding event time in Unix milliseconds.
  public let time: Int64
  /// Protocol market identifier for the funded position.
  public let coin: String
  /// Funding payment in USDC, preserving the server's sign.
  public let usdc: Decimal
  /// Signed position size in base units at the funding event.
  public let szi: Decimal
  /// Applied funding rate as a fractional ratio, not a percentage.
  public let fundingRate: Decimal
  enum CodingKeys: String, CodingKey { case time, coin, usdc, szi, fundingRate }
  /// Decodes a user funding event with exact payment, size, and rate decimals.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    time = try c.decode(Int64.self, forKey: .time)
    coin = try c.decode(String.self, forKey: .coin)
    usdc = try c.protocolDecimal(.usdc)
    szi = try c.protocolDecimal(.szi)
    fundingRate = try c.protocolDecimal(.fundingRate)
  }
}

/// Typed protocol response for FundingEntry.
public struct PerpsFundingEntry: Codable, Sendable {
  /// Funding ledger event time in Unix milliseconds.
  public let time: Int64
  /// Protocol transaction hash associated with the funding event.
  public let hash: String
  /// Position size, rate, and resulting funding payment.
  public let delta: PerpsFundingDelta
  enum CodingKeys: String, CodingKey { case time, hash, delta }
  /// Decodes a funding ledger entry and its nested payment details.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    time = try c.decode(Int64.self, forKey: .time)
    hash = try c.decode(String.self, forKey: .hash)
    delta = try c.decode(PerpsFundingDelta.self, forKey: .delta)
  }
}

/// Typed protocol response for FundingDelta.
public struct PerpsFundingDelta: Codable, Sendable {
  /// Raw funding-ledger discriminator supplied by the server.
  public let type: String
  /// Protocol market identifier for the funding payment.
  public let coin: String
  /// Funding payment in USDC, preserving the server's sign.
  public let usdc: Decimal
  /// Signed position size in base-asset units.
  public let szi: Decimal
  /// Applied funding rate as a fractional ratio.
  public let fundingRate: Decimal
  /// Number of funding samples represented by the delta; nil when not supplied.
  public let nSamples: Int?
  enum CodingKeys: String, CodingKey { case type, coin, usdc, szi, fundingRate, nSamples }
  /// Decodes funding payment details without defaulting an absent sample count.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    coin = try c.decode(String.self, forKey: .coin)
    usdc = try c.protocolDecimal(.usdc)
    szi = try c.protocolDecimal(.szi)
    fundingRate = try c.protocolDecimal(.fundingRate)
    nSamples = try c.decodeIfPresent(Int.self, forKey: .nSamples)
  }
}

/// Typed protocol response for BookLevel.
public struct PerpsBookLevel: Codable, Sendable {
  /// Price of this book level in quote units per base unit.
  public let px: Decimal
  /// Aggregate resting size at the level in base units.
  public let sz: Decimal
  /// Number of orders represented by the level.
  public let n: Int
  enum CodingKeys: String, CodingKey { case px, sz, n }
  /// Decodes a price level's exact price, aggregate size, and order count.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    px = try c.protocolDecimal(.px)
    sz = try c.protocolDecimal(.sz)
    n = try c.decode(Int.self, forKey: .n)
  }
}

/// Typed protocol response for Book.
public struct PerpsBook: Codable, Sendable {
  /// Protocol market identifier for the book snapshot.
  public let coin: String
  /// Bid levels followed by ask levels, retaining server ordering within each side.
  public let levels: [[PerpsBookLevel]]
  /// Book snapshot time in Unix milliseconds.
  public let time: Int64
  enum CodingKeys: String, CodingKey { case coin, levels, time }
  /// Decodes a book snapshot, retaining the server's level arrays without reshaping them.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    levels = try c.decode([[PerpsBookLevel]].self, forKey: .levels)
    time = try c.decode(Int64.self, forKey: .time)
  }
}

/// Typed protocol response for Bbo.
public struct PerpsBbo: Codable, Sendable {
  /// Protocol market identifier for the best quotes.
  public let coin: String
  /// Quote update time in Unix milliseconds.
  public let time: Int64
  /// Best bid followed by best ask; a null side decodes as nil when no quote is available.
  public let bbo: [PerpsBookLevel?]
  enum CodingKeys: String, CodingKey { case coin, time, bbo }
  /// Decodes best quotes while retaining null bid or ask entries as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    time = try c.decode(Int64.self, forKey: .time)
    bbo = try c.decode([PerpsBookLevel?].self, forKey: .bbo)
  }
}

/// Typed protocol response for Trade.
public struct PerpsTrade: Codable, Sendable {
  /// Protocol market identifier for this public trade.
  public let coin: String
  /// Aggressor side code: `B` for buy or `A` for sell.
  public let side: String
  /// Execution price in quote units per base unit.
  public let px: Decimal
  /// Executed size in base-asset units.
  public let sz: Decimal
  /// Protocol transaction hash associated with the trade.
  public let hash: String
  /// Execution time in Unix milliseconds.
  public let time: Int64
  /// Exchange-assigned trade identifier.
  public let tid: Int64
  /// Participant addresses when included by the server; nil when omitted or null.
  public let users: [String]?
  enum CodingKeys: String, CodingKey { case coin, side, px, sz, hash, time, tid, users }
  /// Decodes a public trade with exact decimal price and size and optional participant addresses.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    side = try c.decode(String.self, forKey: .side)
    px = try c.protocolDecimal(.px)
    sz = try c.protocolDecimal(.sz)
    hash = try c.decode(String.self, forKey: .hash)
    time = try c.decode(Int64.self, forKey: .time)
    tid = try c.decode(Int64.self, forKey: .tid)
    users = try c.decodeIfPresent([String].self, forKey: .users)
  }
}

/// Typed protocol response for Candle.
public struct PerpsCandle: Codable, Sendable {
  /// Candle opening time in Unix milliseconds.
  public let t: Int64
  /// Candle closing time in Unix milliseconds.
  public let T: Int64
  /// Protocol market symbol represented by the candle.
  public let s: String
  /// Protocol interval label, such as `1m` or `1h`.
  public let i: String
  /// Opening price in quote units per base unit.
  public let o: Decimal
  /// Closing price in quote units per base unit.
  public let c: Decimal
  /// Highest traded price in quote units per base unit.
  public let h: Decimal
  /// Lowest traded price in quote units per base unit.
  public let l: Decimal
  /// Traded volume during the interval in base-asset units.
  public let v: Decimal
  /// Number of trades in the interval.
  public let n: Int
  enum CodingKeys: String, CodingKey { case t, T, s, i, o, c, h, l, v, n }
  /// Decodes a candle's protocol field names, exact OHLCV decimals, and millisecond timestamps.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    t = try c.decode(Int64.self, forKey: .t)
    T = try c.decode(Int64.self, forKey: .T)
    s = try c.decode(String.self, forKey: .s)
    i = try c.decode(String.self, forKey: .i)
    o = try c.protocolDecimal(.o)
    self.c = try c.protocolDecimal(.c)
    h = try c.protocolDecimal(.h)
    l = try c.protocolDecimal(.l)
    v = try c.protocolDecimal(.v)
    n = try c.decode(Int.self, forKey: .n)
  }
}

/// Typed protocol response for Liquidation.
public struct PerpsLiquidation: Codable, Sendable {
  /// Protocol liquidation event identifier.
  public let lid: Int64
  /// Address of the liquidating account.
  public let liquidator: String
  /// Address of the account whose exposure was liquidated.
  public let liquidated_user: String
  /// Liquidated position notional in USD.
  public let liquidated_ntl_pos: Decimal
  /// Liquidated account's reported equity in USD.
  public let liquidated_account_value: Decimal
  enum CodingKeys: String, CodingKey {
    case lid, liquidator, liquidated_user, liquidated_ntl_pos, liquidated_account_value
  }
  /// Decodes liquidation participants and the reported notional and account value.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    lid = try c.decode(Int64.self, forKey: .lid)
    liquidator = try c.decode(String.self, forKey: .liquidator)
    liquidated_user = try c.decode(String.self, forKey: .liquidated_user)
    liquidated_ntl_pos = try c.protocolDecimal(.liquidated_ntl_pos)
    liquidated_account_value = try c.protocolDecimal(.liquidated_account_value)
  }
}

/// Typed protocol response for NonUserCancel.
public struct PerpsNonUserCancel: Codable, Sendable {
  /// Protocol market identifier for the canceled order.
  public let coin: String
  /// Identifier of an order canceled by the system rather than the user.
  public let oid: Int64
  enum CodingKeys: String, CodingKey { case coin, oid }
  /// Decodes the market and order identifier of a system-initiated cancellation.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    oid = try c.decode(Int64.self, forKey: .oid)
  }
}

/// Typed protocol response for UserEvents.
public struct PerpsUserEvents: Codable, Sendable {
  /// Executions included in this event; nil when omitted or null, not an empty fill batch.
  public let fills: [PerpsFill]?
  /// Funding payment included in this event; nil when not supplied.
  public let funding: PerpsUserFunding?
  /// Liquidation details included in this event; nil when not supplied.
  public let liquidation: PerpsLiquidation?
  /// System-initiated order cancellations; nil when not supplied.
  public let nonUserCancel: [PerpsNonUserCancel]?
  enum CodingKeys: String, CodingKey { case fills, funding, liquidation, nonUserCancel }
  /// Decodes supplied user-event variants, leaving absent event payloads as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    fills = try c.decodeIfPresent([PerpsFill].self, forKey: .fills)
    funding = try c.decodeIfPresent(PerpsUserFunding.self, forKey: .funding)
    liquidation = try c.decodeIfPresent(PerpsLiquidation.self, forKey: .liquidation)
    nonUserCancel = try c.decodeIfPresent([PerpsNonUserCancel].self, forKey: .nonUserCancel)
  }
}

/// Typed protocol response for BorrowValue.
public struct PerpsBorrowValue: Codable, Sendable {
  /// Server-reported accounting basis, retained without unit or accrual conversion.
  public let basis: Decimal
  /// Server-reported current value, distinct from `basis`; no local interest is calculated.
  public let value: Decimal
  enum CodingKeys: String, CodingKey { case basis, value }
  /// Decodes the server's basis and current accounting values without calculating interest.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    basis = try c.protocolDecimal(.basis)
    value = try c.protocolDecimal(.value)
  }
}

/// Typed protocol response for BorrowState.
public struct PerpsBorrowState: Codable, Sendable {
  /// Borrow-side accounting values for the associated token.
  public let borrow: PerpsBorrowValue
  /// Supply-side accounting values for the associated token.
  public let supply: PerpsBorrowValue
  enum CodingKeys: String, CodingKey { case borrow, supply }
  /// Decodes distinct borrow and supply accounting states for a token.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    borrow = try c.decode(PerpsBorrowValue.self, forKey: .borrow)
    supply = try c.decode(PerpsBorrowValue.self, forKey: .supply)
  }
}

/// Typed protocol response for BorrowLendUser.
public struct PerpsBorrowLendUser: Codable, Sendable {
  /// Raw server health label; nil when no label is supplied.
  public let health: String?
  /// Server-computed health factor; nil means unavailable, not zero or infinite.
  public let healthFactor: Decimal?
  /// Borrow and supply states keyed by Spot token index.
  public let tokenToState: [PerpsTokenBorrowState]
  enum CodingKeys: String, CodingKey { case tokenToState, health, healthFactor }
  /// Decodes token-indexed lending states and preserves unavailable health metrics as nil.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    health = try c.decodeIfPresent(String.self, forKey: .health)
    healthFactor = try c.optionalProtocolDecimal(.healthFactor)
    tokenToState = try c.decode([PerpsTokenBorrowState].self, forKey: .tokenToState)
  }
}

/// Typed protocol response for SubAccount.
public struct PerpsSubAccount: Codable, Sendable {
  /// Human-readable label assigned to the subaccount.
  public let name: String
  /// Address identifying the subaccount.
  public let subAccountUser: String
  /// Address of the controlling master account.
  public let master: String
  /// Perpetual clearinghouse snapshot for the subaccount.
  public let clearinghouseState: PerpsAccountState
  /// Spot holdings for the subaccount; nil when not supplied.
  public let spotState: PerpsSpotState?
  enum CodingKeys: String, CodingKey {
    case name, subAccountUser, master, clearinghouseState, spotState
  }
  /// Decodes subaccount identity and clearinghouse state with optional Spot holdings.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    name = try c.decode(String.self, forKey: .name)
    subAccountUser = try c.decode(String.self, forKey: .subAccountUser)
    master = try c.decode(String.self, forKey: .master)
    clearinghouseState = try c.decode(PerpsAccountState.self, forKey: .clearinghouseState)
    spotState = try c.decodeIfPresent(PerpsSpotState.self, forKey: .spotState)
  }
}

/// A named projection of a protocol tuple.
public struct PerpsDecimalPair: Codable, Sendable {
  /// Protocol map key, interpreted by the containing response (for example, an asset name).
  public let key: String
  /// Decimal map value in the units defined by the containing response.
  public let value: Decimal
  /// Decodes `PerpsDecimalPair` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(String.self)
    value = try perpsDecimal(c.decode(String.self))
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsDecimalPair` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(perpsDecimalString(value))
  }
}

/// A named projection of a protocol tuple.
public struct PerpsTokenAvailability: Codable, Sendable {
  /// Spot token index identifying the balance.
  public let key: Int
  /// Amount available after maintenance requirements, in the identified token's units.
  public let value: Decimal
  /// Decodes `PerpsTokenAvailability` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(Int.self)
    value = try perpsDecimal(c.decode(String.self))
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsTokenAvailability` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(perpsDecimalString(value))
  }
}

/// A named projection of a protocol tuple.
public struct PerpsMarginTableEntry: Codable, Sendable {
  /// Margin table ID referenced by market metadata.
  public let key: Int
  /// Leverage schedule associated with this table ID.
  public let value: PerpsMarginTable
  /// Decodes `PerpsMarginTableEntry` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(Int.self)
    value = try c.decode(PerpsMarginTable.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsMarginTableEntry` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(value)
  }
}

/// A named projection of a protocol tuple.
public struct PerpsDexAccount: Codable, Sendable {
  /// Protocol DEX identifier; an empty string identifies the default DEX.
  public let key: String
  /// Clearinghouse account snapshot for the identified DEX.
  public let value: PerpsAccountState
  /// Decodes `PerpsDexAccount` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(String.self)
    value = try c.decode(PerpsAccountState.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsDexAccount` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(value)
  }
}

/// A named projection of a protocol tuple.
public struct PerpsFundingVenue: Codable, Sendable {
  /// Venue label identifying the source of the funding prediction.
  public let key: String
  /// Venue's prediction; nil preserves a null prediction rather than a zero rate.
  public let value: PerpsPredictedFunding?
  /// Decodes `PerpsFundingVenue` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(String.self)
    value = try c.decode(PerpsPredictedFunding?.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsFundingVenue` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(value)
  }
}

/// A named projection of a protocol tuple.
public struct PerpsPredictedFundingEntry: Codable, Sendable {
  /// Protocol market identifier whose funding is predicted.
  public let key: String
  /// Predictions grouped by venue, retaining server order.
  public let value: [PerpsFundingVenue]
  /// Decodes `PerpsPredictedFundingEntry` from its protocol response representation; invalid
  /// required values throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(String.self)
    value = try c.decode([PerpsFundingVenue].self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsPredictedFundingEntry` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(value)
  }
}

/// A named projection of a protocol tuple.
public struct PerpsConciseAnnotation: Codable, Sendable {
  /// Protocol market identifier to which the annotation applies.
  public let key: String
  /// Classification and optional display metadata for this market.
  public let value: PerpsAnnotation
  /// Decodes `PerpsConciseAnnotation` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(String.self)
    value = try c.decode(PerpsAnnotation.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsConciseAnnotation` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(value)
  }
}

/// A named projection of a protocol tuple.
public struct PerpsTwapEntry: Codable, Sendable {
  /// Exchange-assigned TWAP order identifier.
  public let key: Int64
  /// Execution state for the identified TWAP.
  public let value: PerpsTwapState
  /// Decodes `PerpsTwapEntry` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(Int64.self)
    value = try c.decode(PerpsTwapState.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsTwapEntry` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(value)
  }
}

/// A named projection of a protocol tuple.
public struct PerpsTimeValue: Codable, Sendable {
  /// Observation time in Unix milliseconds.
  public let key: Int64
  /// Observed amount in the units of the containing history series.
  public let value: Decimal
  /// Decodes `PerpsTimeValue` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(Int64.self)
    value = try perpsDecimal(c.decode(String.self))
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsTimeValue` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(perpsDecimalString(value))
  }
}

/// A named projection of a protocol tuple.
public struct PerpsPortfolioPeriod: Codable, Sendable {
  /// Protocol history-window label, such as `day` or `allTime`.
  public let key: String
  /// Equity, PnL, and trading volume for the named window.
  public let value: PerpsPortfolioValue
  /// Decodes `PerpsPortfolioPeriod` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(String.self)
    value = try c.decode(PerpsPortfolioValue.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsPortfolioPeriod` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(value)
  }
}

/// A named projection of a protocol tuple.
public struct PerpsTokenBorrowState: Codable, Sendable {
  /// Spot token index to which the lending state belongs.
  public let key: Int
  /// Borrow-side and supply-side accounting state for the token.
  public let value: PerpsBorrowState
  /// Decodes `PerpsTokenBorrowState` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    key = try c.decode(Int.self)
    value = try c.decode(PerpsBorrowState.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsTokenBorrowState` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(key)
    try c.encode(value)
  }
}

/// Metadata and contexts are returned as a two-element tuple.
public struct PerpsMetaAndContexts: Codable, Sendable {
  /// Market metadata whose universe determines context ordering.
  public let meta: PerpsMeta
  /// One context per universe entry at the same index; decoding rejects mismatched counts.
  public let contexts: [PerpsAssetContext]
  /// Decodes `PerpsMetaAndContexts` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    meta = try c.decode(PerpsMeta.self)
    contexts = try c.decode([PerpsAssetContext].self)
    guard c.isAtEnd, meta.universe.count == contexts.count else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsMetaAndContexts` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(meta)
    try c.encode(contexts)
  }
}

/// Explicit modes; unresolved and future values are never treated as standard.
public enum AccountAbstraction: Codable, Sendable, Equatable {
  /// Separate Spot and perpetual balances with class transfers supported.
  case standard
  /// Unified account mode with shared collateral.
  case unifiedAccount
  /// Portfolio-margin mode with shared collateral.
  case portfolioMargin
  /// DEX abstraction mode with separate balances and no class-transfer support here.
  case dexAbstraction
  /// Disabled abstraction with separate balances and class transfers supported.
  case disabled
  /// Unresolved protocol `default` mode; no balance or transfer capabilities are assumed.
  case defaultMode
  /// Unrecognized protocol mode, preserving its original string without assuming capabilities.
  case unknown(String)
  /// Decodes `AccountAbstraction` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    switch value {
    /// Recognizes the explicit separate-balance mode.
    case "standard": self = .standard
    /// Recognizes unified shared collateral.
    case "unifiedAccount": self = .unifiedAccount
    /// Recognizes portfolio-margin shared collateral.
    case "portfolioMargin": self = .portfolioMargin
    /// Recognizes the DEX abstraction mode.
    case "dexAbstraction": self = .dexAbstraction
    /// Recognizes explicitly disabled abstraction.
    case "disabled": self = .disabled
    /// Preserves default as unresolved rather than treating it as standard.
    case "default": self = .defaultMode
    default: self = .unknown(value)
    }
  }
  /// Protocol string used for encoding, including the original string for unknown modes.
  public var rawValue: String {
    switch self {
    /// Emits the explicit standard-mode label.
    case .standard: return "standard"
    /// Emits the unified-account label.
    case .unifiedAccount: return "unifiedAccount"
    /// Emits the portfolio-margin label.
    case .portfolioMargin: return "portfolioMargin"
    /// Emits the DEX-abstraction label.
    case .dexAbstraction: return "dexAbstraction"
    /// Emits the disabled-abstraction label.
    case .disabled: return "disabled"
    /// Emits the protocol spelling of the unresolved default mode.
    case .defaultMode: return "default"
    /// Round-trips a future mode's original label.
    case .unknown(let value): return value
    }
  }
  /// Encodes `AccountAbstraction` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    try c.encode(rawValue)
  }
  /// Whether this is unified-account or portfolio-margin mode; unresolved modes return false.
  public var hasSharedCollateral: Bool { self == .unifiedAccount || self == .portfolioMargin }
  /// Whether separate balances are known to apply: standard, disabled, or DEX abstraction.
  public var hasSeparateBalances: Bool {
    self == .standard || self == .disabled || self == .dexAbstraction
  }
  /// Whether Spot/perpetual class transfers are supported: only standard or disabled mode.
  public var supportsClassTransfer: Bool { self == .standard || self == .disabled }
}

/// Token holdings that keep unheld funds, maintenance availability, and withdrawals distinct.
public struct TokenBalance: Sendable {
  /// Protocol token symbol.
  public let coin: String
  /// Spot metadata index identifying the token.
  public let token: Int
  /// Total balance in token units, including held funds.
  public let total: Decimal
  /// Portion of `total` held in token units.
  public let held: Decimal
  /// Total minus held funds, clamped to zero; not a withdrawal or maintenance-availability limit.
  public var unheld: Decimal { max(0, total - held) }
  /// Server-reported availability in token units after maintenance; nil means unknown.
  public let availableAfterMaintenance: Decimal?
  /// Server-reported withdrawable token amount; nil means unknown, not equal to `unheld`.
  public let withdrawable: Decimal?
  /// Stores distinct token balance values; unavailable server values remain nil.
  public init(
    coin: String, token: Int, total: Decimal, held: Decimal,
    availableAfterMaintenance: Decimal? = nil, withdrawable: Decimal? = nil
  ) {
    self.coin = coin
    self.token = token
    self.total = total
    self.held = held
    self.availableAfterMaintenance = availableAfterMaintenance
    self.withdrawable = withdrawable
  }
}

/// A DEX's positions and, when separately attributable, its collateral balances.
public struct PerpsDexBalance: Sendable {
  /// Protocol DEX identifier; an empty string identifies the default DEX.
  public let dex: String
  /// Collateral token's Spot index; nil when metadata does not identify it.
  public let collateralToken: Int?
  /// Separately attributable collateral equity; nil for shared or unresolved balance modes.
  public let accountValue: Decimal?
  /// Separately attributable collateral usage; nil for shared or unresolved balance modes.
  public let marginUsed: Decimal?
  /// Withdrawable collateral amount; nil when unavailable or not separately attributable.
  public let withdrawable: Decimal?
  /// Positions belonging to this DEX, even when collateral is shared.
  public let positions: [PerpsPositionEntry]
  /// Stores a DEX’s collateral and positions without adding them to shared Spot balances.
  public init(
    dex: String, collateralToken: Int? = nil, accountValue: Decimal? = nil,
    marginUsed: Decimal? = nil, withdrawable: Decimal? = nil, positions: [PerpsPositionEntry] = []
  ) {
    self.dex = dex
    self.collateralToken = collateralToken
    self.accountValue = accountValue
    self.marginUsed = marginUsed
    self.withdrawable = withdrawable
    self.positions = positions
  }
}

/// Account-mode-aware balance snapshot that avoids double-counting shared collateral.
public struct AccountBalances: Sendable {
  /// Address whose balances were requested.
  public let address: String
  /// Resolved protocol mode, retaining default or unknown modes without guessing.
  public let abstraction: AccountAbstraction
  /// Spot token holdings, including collateral shared by applicable account modes.
  public let spot: [TokenBalance]
  /// Per-DEX positions and any independently attributable collateral balances.
  public let perps: [PerpsDexBalance]
  /// Whether the account mode explicitly uses shared collateral.
  public var hasSharedCollateral: Bool { abstraction.hasSharedCollateral }
  /// Stores account-mode-aware Spot and Perps balances without aggregating shared collateral.
  public init(
    address: String, abstraction: AccountAbstraction, spot: [TokenBalance], perps: [PerpsDexBalance]
  ) {
    self.address = address
    self.abstraction = abstraction
    self.spot = spot
    self.perps = perps
  }
}

/// Named buy/sell projections of the protocol's two-element capacity arrays.
extension PerpsActiveAssetData {
  /// Buy-side trading capacity in the protocol units of `availableToTrade`.
  public var availableToBuy: Decimal { availableToTrade[0] }
  /// Sell-side trading capacity in the protocol units of `availableToTrade`.
  public var availableToSell: Decimal { availableToTrade[1] }
  /// Maximum buy order size in base-asset units.
  public var maxBuySize: Decimal { maxTradeSzs[0] }
  /// Maximum sell order size in base-asset units.
  public var maxSellSize: Decimal { maxTradeSzs[1] }
}

/// Market classification represented on the wire as a two-string tuple.
public struct PerpsCategory: Codable, Sendable {
  /// Protocol market identifier being classified.
  public let coin: String
  /// Server-supplied category label, preserved without normalization.
  public let category: String
  /// Decodes `PerpsCategory` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    coin = try c.decode(String.self)
    category = try c.decode(String.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsCategory` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(coin)
    try c.encode(category)
  }
}

/// allPerpMetas currently returns metadata; some documented versions include contexts.
public enum PerpsAllMetaEntry: Codable, Sendable {
  /// Metadata-only object representation returned by the protocol.
  case metadata(PerpsMeta)
  /// Two-element tuple containing metadata and index-aligned market contexts.
  case metadataAndContexts(PerpsMetaAndContexts)
  /// Decodes `PerpsAllMetaEntry` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    if (try? decoder.unkeyedContainer()) != nil {
      self = .metadataAndContexts(try PerpsMetaAndContexts(from: decoder))
    } else {
      self = .metadata(try PerpsMeta(from: decoder))
    }
  }
  /// Market metadata regardless of whether contexts accompanied the response.
  public var meta: PerpsMeta {
    switch self {
    /// Returns metadata from the object representation.
    case .metadata(let meta): return meta
    /// Projects metadata out of the tuple representation.
    case .metadataAndContexts(let value): return value.meta
    }
  }
  /// Encodes `PerpsAllMetaEntry` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    switch self {
    /// Retains the metadata-only object shape.
    case .metadata(let meta): try meta.encode(to: encoder)
    /// Retains the metadata-and-contexts tuple shape.
    case .metadataAndContexts(let value): try value.encode(to: encoder)
    }
  }
}

/// Spot token identity and precision metadata used to interpret balances and market pairs.
public struct PerpsSpotToken: Codable, Sendable {
  /// Protocol token name or symbol.
  public let name: String
  /// Token index referenced by Spot balances and market token pairs.
  public let index: Int
  /// Number of decimal places allowed for trading size.
  public let szDecimals: Int
  /// Protocol token identifier, distinct from the numeric metadata index.
  public let tokenId: String
  /// Decimal precision of the token's smallest units; nil when not supplied.
  public let weiDecimals: Int?
  /// Whether the token is canonical according to the server; nil means unspecified.
  public let isCanonical: Bool?
}
/// Spot trading pair metadata referencing tokens by their metadata indices.
public struct PerpsSpotMarket: Codable, Sendable {
  /// Protocol market name, which may differ from a display pair symbol.
  public let name: String
  /// Protocol Spot market index.
  public let index: Int
  /// Base and quote token indices in protocol pair order.
  public let tokens: [Int]
  /// Whether the pair is canonical according to the server; nil means unspecified.
  public let isCanonical: Bool?
}
/// Spot token catalog and trading-pair universe returned together by the protocol.
public struct PerpsSpotMeta: Codable, Sendable {
  /// Token definitions referenced by balance and pair indices.
  public let tokens: [PerpsSpotToken]
  /// Available Spot market definitions in server order.
  public let universe: [PerpsSpotMarket]
}
/// Server snapshot of lending-reserve rates, utilization, and aggregate accounting values.
public struct PerpsBorrowReserve: Decodable, Sendable {
  /// Annual borrowing rate as a fractional ratio, not a percentage.
  public let borrowYearlyRate: Decimal
  /// Annual supply rate as a fractional ratio, not a percentage.
  public let supplyYearlyRate: Decimal
  /// Reserve balance in server-defined accounting units; no local balance equation is applied.
  public let balance: Decimal
  /// Reserve utilization as a fractional ratio, not a percentage.
  public let utilization: Decimal
  /// Oracle price for the reserve token in protocol quote units per token.
  public let oraclePx: Decimal
  /// Loan-to-value limit as a fractional ratio, not a percentage.
  public let ltv: Decimal
  /// Aggregate supplied amount in the reserve's protocol accounting units.
  public let totalSupplied: Decimal
  /// Aggregate borrowed amount in the reserve's protocol accounting units.
  public let totalBorrowed: Decimal
  enum CodingKeys: String, CodingKey {
    case borrowYearlyRate, supplyYearlyRate, balance, utilization, oraclePx, ltv, totalSupplied,
      totalBorrowed
  }
  /// Decodes lending-reserve rates and accounting values from protocol decimal strings or numbers.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    borrowYearlyRate = try c.protocolDecimal(.borrowYearlyRate)
    supplyYearlyRate = try c.protocolDecimal(.supplyYearlyRate)
    balance = try c.protocolDecimal(.balance)
    utilization = try c.protocolDecimal(.utilization)
    oraclePx = try c.protocolDecimal(.oraclePx)
    ltv = try c.protocolDecimal(.ltv)
    totalSupplied = try c.protocolDecimal(.totalSupplied)
    totalBorrowed = try c.protocolDecimal(.totalBorrowed)
  }
}
/// Token-indexed lending reserve decoded from a two-element protocol tuple.
public struct PerpsTokenReserve: Decodable, Sendable {
  /// Spot token index identifying the reserve asset.
  public let token: Int
  /// Rates and aggregate accounting state for the identified token.
  public let reserve: PerpsBorrowReserve
  /// Decodes `PerpsTokenReserve` from its protocol response representation; invalid required values
  /// throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    token = try c.decode(Int.self)
    reserve = try c.decode(PerpsBorrowReserve.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
}
