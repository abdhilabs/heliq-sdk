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
  public let type: String
  public let value: Int
  public let rawUsd: Decimal?
  enum CodingKeys: String, CodingKey { case type, value, rawUsd }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    value = try c.decode(Int.self, forKey: .value)
    rawUsd = try c.optionalProtocolDecimal(.rawUsd)
  }
}

/// Typed protocol response for Position.
public struct PerpsPosition: Codable, Sendable {
  public let coin: String
  public let szi: Decimal
  public let entryPx: Decimal?
  public let unrealizedPnl: Decimal
  public let marginUsed: Decimal
  public let leverage: PerpsLeverage
  public let returnOnEquity: Decimal?
  public let liquidationPx: Decimal?
  public let positionValue: Decimal?
  public let maxLeverage: Int?
  public let cumFunding: PerpsCumulativeFunding?
  enum CodingKeys: String, CodingKey {
    case coin, szi, entryPx, unrealizedPnl, marginUsed, leverage, returnOnEquity, liquidationPx,
      positionValue, maxLeverage, cumFunding
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let allTime: Decimal
  public let sinceOpen: Decimal
  public let sinceChange: Decimal
  enum CodingKeys: String, CodingKey { case allTime, sinceOpen, sinceChange }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    allTime = try c.protocolDecimal(.allTime)
    sinceOpen = try c.protocolDecimal(.sinceOpen)
    sinceChange = try c.protocolDecimal(.sinceChange)
  }
}

/// Typed protocol response for MarginSummary.
public struct PerpsMarginSummary: Codable, Sendable {
  public let accountValue: Decimal
  public let totalMarginUsed: Decimal
  public let totalNtlPos: Decimal?
  public let totalRawUsd: Decimal?
  enum CodingKeys: String, CodingKey {
    case accountValue, totalMarginUsed, totalNtlPos, totalRawUsd
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let type: String?
  public let position: PerpsPosition
  enum CodingKeys: String, CodingKey { case type, position }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decodeIfPresent(String.self, forKey: .type)
    position = try c.decode(PerpsPosition.self, forKey: .position)
  }
}

/// Typed protocol response for AccountState.
public struct PerpsAccountState: Codable, Sendable {
  public let marginSummary: PerpsMarginSummary
  public let crossMarginSummary: PerpsMarginSummary?
  public let crossMaintenanceMarginUsed: Decimal?
  public let withdrawable: Decimal?
  public let assetPositions: [PerpsPositionEntry]
  public let time: Int64?
  enum CodingKeys: String, CodingKey {
    case marginSummary, crossMarginSummary, crossMaintenanceMarginUsed, withdrawable,
      assetPositions, time
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let user: String
  public let coin: String
  public let leverage: PerpsLeverage
  public let maxTradeSzs: [Decimal]
  public let availableToTrade: [Decimal]
  public let markPx: Decimal?
  enum CodingKeys: String, CodingKey {
    case user, coin, leverage, maxTradeSzs, availableToTrade, markPx
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let lowerBound: Decimal
  public let maxLeverage: Int
  enum CodingKeys: String, CodingKey { case lowerBound, maxLeverage }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    lowerBound = try c.protocolDecimal(.lowerBound)
    maxLeverage = try c.decode(Int.self, forKey: .maxLeverage)
  }
}

/// Typed protocol response for MarginTable.
public struct PerpsMarginTable: Codable, Sendable {
  public let description: String
  public let marginTiers: [PerpsMarginTier]
  enum CodingKeys: String, CodingKey { case description, marginTiers }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    description = try c.decode(String.self, forKey: .description)
    marginTiers = try c.decode([PerpsMarginTier].self, forKey: .marginTiers)
  }
}

/// Typed protocol response for Asset.
public struct PerpsAsset: Codable, Sendable {
  public let name: String
  public let szDecimals: Int
  public let maxLeverage: Int
  public let marginTableId: Int?
  public let onlyIsolated: Bool?
  public let isDelisted: Bool?
  public let marginMode: String?
  public let growthMode: String?
  public let lastGrowthModeChangeTime: String?
  enum CodingKeys: String, CodingKey {
    case name, szDecimals, maxLeverage, marginTableId, onlyIsolated, isDelisted, marginMode,
      growthMode, lastGrowthModeChangeTime
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let universe: [PerpsAsset]
  public let marginTables: [PerpsMarginTableEntry]?
  public let collateralToken: Int?
  enum CodingKeys: String, CodingKey { case universe, marginTables, collateralToken }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    universe = try c.decode([PerpsAsset].self, forKey: .universe)
    marginTables = try c.decodeIfPresent([PerpsMarginTableEntry].self, forKey: .marginTables)
    collateralToken = try c.decodeIfPresent(Int.self, forKey: .collateralToken)
  }
}

/// Typed protocol response for AssetContext.
public struct PerpsAssetContext: Codable, Sendable {
  public let dayNtlVlm: Decimal
  public let funding: Decimal
  public let markPx: Decimal
  public let midPx: Decimal?
  public let openInterest: Decimal
  public let oraclePx: Decimal
  public let prevDayPx: Decimal
  public let premium: Decimal?
  public let impactPxs: [Decimal]?
  enum CodingKeys: String, CodingKey {
    case dayNtlVlm, funding, markPx, midPx, openInterest, oraclePx, prevDayPx, premium, impactPxs
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let name: String
  public let fullName: String
  public let deployer: String
  public let oracleUpdater: String?
  public let feeRecipient: String?
  public let assetToStreamingOiCap: [PerpsDecimalPair]?
  public let assetToFundingMultiplier: [PerpsDecimalPair]?
  enum CodingKeys: String, CodingKey {
    case name, fullName, deployer, oracleUpdater, feeRecipient, assetToStreamingOiCap,
      assetToFundingMultiplier
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let coin: String
  public let fundingRate: Decimal
  public let premium: Decimal
  public let time: Int64
  enum CodingKeys: String, CodingKey { case coin, fundingRate, premium, time }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let fundingRate: Decimal
  public let nextFundingTime: Int64?
  public let fundingIntervalHours: Int?
  enum CodingKeys: String, CodingKey { case fundingRate, nextFundingTime, fundingIntervalHours }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    fundingRate = try c.protocolDecimal(.fundingRate)
    nextFundingTime = try c.decodeIfPresent(Int64.self, forKey: .nextFundingTime)
    fundingIntervalHours = try c.decodeIfPresent(Int.self, forKey: .fundingIntervalHours)
  }
}

/// Typed protocol response for DeployAuction.
public struct PerpsDeployAuction: Codable, Sendable {
  public let startTimeSeconds: Int64
  public let durationSeconds: Int64
  public let startGas: Decimal
  public let currentGas: Decimal
  public let endGas: Decimal?
  enum CodingKeys: String, CodingKey {
    case startTimeSeconds, durationSeconds, startGas, currentGas, endGas
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let totalOiCap: Decimal
  public let oiSzCapPerPerp: Decimal
  public let maxTransferNtl: Decimal
  public let coinToOiCap: [PerpsDecimalPair]
  enum CodingKeys: String, CodingKey {
    case totalOiCap, oiSzCapPerPerp, maxTransferNtl, coinToOiCap
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let totalNetDeposit: Decimal
  enum CodingKeys: String, CodingKey { case totalNetDeposit }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    totalNetDeposit = try c.protocolDecimal(.totalNetDeposit)
  }
}

/// Typed protocol response for Annotation.
public struct PerpsAnnotation: Codable, Sendable {
  public let category: String
  public let description: String?
  public let displayName: String?
  public let keywords: [String]?
  enum CodingKeys: String, CodingKey { case category, description, displayName, keywords }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let coin: String
  public let token: Int
  public let total: Decimal
  public let hold: Decimal
  public let entryNtl: Decimal?
  enum CodingKeys: String, CodingKey { case coin, token, total, hold, entryNtl }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let balances: [PerpsSpotBalance]
  public let tokenToAvailableAfterMaintenance: [PerpsTokenAvailability]?
  enum CodingKeys: String, CodingKey { case balances, tokenToAvailableAfterMaintenance }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    balances = try c.decode([PerpsSpotBalance].self, forKey: .balances)
    tokenToAvailableAfterMaintenance = try c.decodeIfPresent(
      [PerpsTokenAvailability].self, forKey: .tokenToAvailableAfterMaintenance)
  }
}

/// Typed protocol response for UserFees.
public struct PerpsUserFees: Codable, Sendable {
  public let dailyUserVlm: [PerpsDailyVolume]
  public let feeSchedule: PerpsFeeSchedule
  public let userCrossRate: Decimal
  public let userAddRate: Decimal
  public let userSpotCrossRate: Decimal?
  public let userSpotAddRate: Decimal?
  public let activeReferralDiscount: Decimal?
  public let feeTrialReward: Decimal?
  public let activeStakingDiscount: PerpsStakingDiscount?
  public let trial: JSONValue?
  public let nextTrialAvailableTimestamp: Int64?
  public let stakingLink: PerpsStakingLink?
  enum CodingKeys: String, CodingKey {
    case dailyUserVlm, feeSchedule, userCrossRate, userAddRate, userSpotCrossRate, userSpotAddRate,
      activeReferralDiscount, feeTrialReward, activeStakingDiscount, trial,
      nextTrialAvailableTimestamp, stakingLink
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let date: String
  public let userCross: Decimal
  public let userAdd: Decimal
  public let exchange: Decimal
  enum CodingKeys: String, CodingKey { case date, userCross, userAdd, exchange }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let cross: Decimal
  public let add: Decimal
  public let spotCross: Decimal?
  public let spotAdd: Decimal?
  public let referralDiscount: Decimal?
  public let stakingDiscountTiers: [PerpsStakingDiscount]?
  public let tiers: PerpsFeeTiers
  enum CodingKeys: String, CodingKey {
    case cross, add, spotCross, spotAdd, referralDiscount, stakingDiscountTiers, tiers
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let vip: [PerpsVipTier]
  public let mm: [PerpsMakerTier]
  enum CodingKeys: String, CodingKey { case vip, mm }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    vip = try c.decode([PerpsVipTier].self, forKey: .vip)
    mm = try c.decode([PerpsMakerTier].self, forKey: .mm)
  }
}

/// Typed protocol response for VipTier.
public struct PerpsVipTier: Codable, Sendable {
  public let ntlCutoff: Decimal
  public let cross: Decimal
  public let add: Decimal
  public let spotCross: Decimal?
  public let spotAdd: Decimal?
  enum CodingKeys: String, CodingKey { case ntlCutoff, cross, add, spotCross, spotAdd }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let makerFractionCutoff: Decimal
  public let add: Decimal
  enum CodingKeys: String, CodingKey { case makerFractionCutoff, add }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    makerFractionCutoff = try c.protocolDecimal(.makerFractionCutoff)
    add = try c.protocolDecimal(.add)
  }
}

/// Typed protocol response for StakingLink.
public struct PerpsStakingLink: Codable, Sendable {
  public let type: String
  public let stakingUser: String
  enum CodingKeys: String, CodingKey { case type, stakingUser }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    stakingUser = try c.decode(String.self, forKey: .stakingUser)
  }
}

/// Typed protocol response for TwapState.
public struct PerpsTwapState: Codable, Sendable {
  public let coin: String
  public let user: String
  public let side: String
  public let sz: Decimal
  public let executedSz: Decimal
  public let executedNtl: Decimal
  public let minutes: Int
  public let reduceOnly: Bool
  public let randomize: Bool
  public let timestamp: Int64
  enum CodingKeys: String, CodingKey {
    case coin, user, side, sz, executedSz, executedNtl, minutes, reduceOnly, randomize, timestamp
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let state: PerpsTwapState
  public let status: PerpsTwapStatus
  public let time: Int64
  enum CodingKeys: String, CodingKey { case state, status, time }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    state = try c.decode(PerpsTwapState.self, forKey: .state)
    status = try c.decode(PerpsTwapStatus.self, forKey: .status)
    time = try c.decode(Int64.self, forKey: .time)
  }
}

/// Typed protocol response for TwapStatus.
public struct PerpsTwapStatus: Codable, Sendable {
  public let status: String
  public let description: String?
  enum CodingKeys: String, CodingKey { case status, description }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    status = try c.decode(String.self, forKey: .status)
    description = try c.decodeIfPresent(String.self, forKey: .description)
  }
}

/// Typed protocol response for Fill.
public struct PerpsFill: Codable, Sendable {
  public let closedPnl: Decimal
  public let coin: String
  public let crossed: Bool
  public let dir: String
  public let hash: String
  public let oid: Int64
  public let px: Decimal
  public let side: String
  public let startPosition: Decimal
  public let sz: Decimal
  public let time: Int64
  public let fee: Decimal
  public let feeToken: String?
  public let builderFee: Decimal?
  public let tid: Int64
  enum CodingKeys: String, CodingKey {
    case closedPnl, coin, crossed, dir, hash, oid, px, side, startPosition, sz, time, fee, feeToken,
      builderFee, tid
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let fill: PerpsFill
  public let twapId: Int64
  enum CodingKeys: String, CodingKey { case fill, twapId }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    fill = try c.decode(PerpsFill.self, forKey: .fill)
    twapId = try c.decode(Int64.self, forKey: .twapId)
  }
}

/// Typed protocol response for HistoricalOrder.
public struct PerpsHistoricalOrder: Codable, Sendable {
  public let order: PerpsOrder
  public let status: String
  public let statusTimestamp: Int64
  enum CodingKeys: String, CodingKey { case order, status, statusTimestamp }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    order = try c.decode(PerpsOrder.self, forKey: .order)
    status = try c.decode(String.self, forKey: .status)
    statusTimestamp = try c.decode(Int64.self, forKey: .statusTimestamp)
  }
}

/// Typed protocol response for Order.
public struct PerpsOrder: Codable, Sendable {
  public let coin: String
  public let side: String
  public let limitPx: Decimal
  public let sz: Decimal
  public let oid: Int64
  public let timestamp: Int64
  public let origSz: Decimal?
  public let cloid: String?
  public let reduceOnly: Bool?
  public let isTrigger: Bool?
  public let isPositionTpsl: Bool?
  public let triggerPx: Decimal?
  public let triggerCondition: String?
  public let orderType: String?
  public let tif: String?
  enum CodingKeys: String, CodingKey {
    case coin, side, limitPx, sz, oid, timestamp, origSz, cloid, reduceOnly, isTrigger,
      isPositionTpsl, triggerPx, triggerCondition, orderType, tif
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let address: String
  public let name: String
  public let validUntil: Int64
  enum CodingKeys: String, CodingKey { case address, name, validUntil }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    address = try c.decode(String.self, forKey: .address)
    name = try c.decode(String.self, forKey: .name)
    validUntil = try c.decode(Int64.self, forKey: .validUntil)
  }
}

/// Typed protocol response for ApprovedBuilder.
public struct PerpsApprovedBuilder: Codable, Sendable {
  public let builder: String
  public let maxFeeRate: Int
  enum CodingKeys: String, CodingKey { case builder, maxFeeRate }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    builder = try c.decode(String.self, forKey: .builder)
    maxFeeRate = try c.decode(Int.self, forKey: .maxFeeRate)
  }
}

/// Typed protocol response for UserRole.
public struct PerpsUserRole: Codable, Sendable {
  public let role: String
  public let data: PerpsRoleData?
  enum CodingKeys: String, CodingKey { case role, data }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    role = try c.decode(String.self, forKey: .role)
    data = try c.decodeIfPresent(PerpsRoleData.self, forKey: .data)
  }
}

/// Typed protocol response for RoleData.
public struct PerpsRoleData: Codable, Sendable {
  public let user: String?
  public let master: String?
  public let name: String?
  public let authorizedUsers: [String]?
  public let threshold: Int?
  enum CodingKeys: String, CodingKey { case user, master, name, authorizedUsers, threshold }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let time: Int64
  public let hash: String
  public let delta: PerpsLedgerDelta
  enum CodingKeys: String, CodingKey { case time, hash, delta }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    time = try c.decode(Int64.self, forKey: .time)
    hash = try c.decode(String.self, forKey: .hash)
    delta = try c.decode(PerpsLedgerDelta.self, forKey: .delta)
  }
}

/// Typed protocol response for LedgerDelta.
public struct PerpsLedgerDelta: Codable, Sendable {
  public let type: String
  public let usdc: Decimal?
  public let amount: Decimal?
  public let fee: Decimal?
  public let token: String?
  public let user: String?
  public let destination: String?
  public let source: String?
  public let vault: String?
  public let isDeposit: Bool?
  public let toPerp: Bool?
  public let subAccount: String?
  public let sourceDex: String?
  public let destinationDex: String?
  public let nonce: Int64?
  enum CodingKeys: String, CodingKey {
    case type, usdc, amount, fee, token, user, destination, source, vault, isDeposit, toPerp,
      subAccount, sourceDex, destinationDex, nonce
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let accountValueHistory: [PerpsTimeValue]
  public let pnlHistory: [PerpsTimeValue]
  public let vlm: Decimal
  enum CodingKeys: String, CodingKey { case accountValueHistory, pnlHistory, vlm }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    accountValueHistory = try c.decode([PerpsTimeValue].self, forKey: .accountValueHistory)
    pnlHistory = try c.decode([PerpsTimeValue].self, forKey: .pnlHistory)
    vlm = try c.protocolDecimal(.vlm)
  }
}

/// Typed protocol response for UserFunding.
public struct PerpsUserFunding: Codable, Sendable {
  public let time: Int64
  public let coin: String
  public let usdc: Decimal
  public let szi: Decimal
  public let fundingRate: Decimal
  enum CodingKeys: String, CodingKey { case time, coin, usdc, szi, fundingRate }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let time: Int64
  public let hash: String
  public let delta: PerpsFundingDelta
  enum CodingKeys: String, CodingKey { case time, hash, delta }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    time = try c.decode(Int64.self, forKey: .time)
    hash = try c.decode(String.self, forKey: .hash)
    delta = try c.decode(PerpsFundingDelta.self, forKey: .delta)
  }
}

/// Typed protocol response for FundingDelta.
public struct PerpsFundingDelta: Codable, Sendable {
  public let type: String
  public let coin: String
  public let usdc: Decimal
  public let szi: Decimal
  public let fundingRate: Decimal
  public let nSamples: Int?
  enum CodingKeys: String, CodingKey { case type, coin, usdc, szi, fundingRate, nSamples }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let px: Decimal
  public let sz: Decimal
  public let n: Int
  enum CodingKeys: String, CodingKey { case px, sz, n }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    px = try c.protocolDecimal(.px)
    sz = try c.protocolDecimal(.sz)
    n = try c.decode(Int.self, forKey: .n)
  }
}

/// Typed protocol response for Book.
public struct PerpsBook: Codable, Sendable {
  public let coin: String
  public let levels: [[PerpsBookLevel]]
  public let time: Int64
  enum CodingKeys: String, CodingKey { case coin, levels, time }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    levels = try c.decode([[PerpsBookLevel]].self, forKey: .levels)
    time = try c.decode(Int64.self, forKey: .time)
  }
}

/// Typed protocol response for Bbo.
public struct PerpsBbo: Codable, Sendable {
  public let coin: String
  public let time: Int64
  public let bbo: [PerpsBookLevel?]
  enum CodingKeys: String, CodingKey { case coin, time, bbo }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    time = try c.decode(Int64.self, forKey: .time)
    bbo = try c.decode([PerpsBookLevel?].self, forKey: .bbo)
  }
}

/// Typed protocol response for Trade.
public struct PerpsTrade: Codable, Sendable {
  public let coin: String
  public let side: String
  public let px: Decimal
  public let sz: Decimal
  public let hash: String
  public let time: Int64
  public let tid: Int64
  public let users: [String]?
  enum CodingKeys: String, CodingKey { case coin, side, px, sz, hash, time, tid, users }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let t: Int64
  public let T: Int64
  public let s: String
  public let i: String
  public let o: Decimal
  public let c: Decimal
  public let h: Decimal
  public let l: Decimal
  public let v: Decimal
  public let n: Int
  enum CodingKeys: String, CodingKey { case t, T, s, i, o, c, h, l, v, n }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let lid: Int64
  public let liquidator: String
  public let liquidated_user: String
  public let liquidated_ntl_pos: Decimal
  public let liquidated_account_value: Decimal
  enum CodingKeys: String, CodingKey {
    case lid, liquidator, liquidated_user, liquidated_ntl_pos, liquidated_account_value
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let coin: String
  public let oid: Int64
  enum CodingKeys: String, CodingKey { case coin, oid }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    coin = try c.decode(String.self, forKey: .coin)
    oid = try c.decode(Int64.self, forKey: .oid)
  }
}

/// Typed protocol response for UserEvents.
public struct PerpsUserEvents: Codable, Sendable {
  public let fills: [PerpsFill]?
  public let funding: PerpsUserFunding?
  public let liquidation: PerpsLiquidation?
  public let nonUserCancel: [PerpsNonUserCancel]?
  enum CodingKeys: String, CodingKey { case fills, funding, liquidation, nonUserCancel }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let basis: Decimal
  public let value: Decimal
  enum CodingKeys: String, CodingKey { case basis, value }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    basis = try c.protocolDecimal(.basis)
    value = try c.protocolDecimal(.value)
  }
}

/// Typed protocol response for BorrowState.
public struct PerpsBorrowState: Codable, Sendable {
  public let borrow: PerpsBorrowValue
  public let supply: PerpsBorrowValue
  enum CodingKeys: String, CodingKey { case borrow, supply }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    borrow = try c.decode(PerpsBorrowValue.self, forKey: .borrow)
    supply = try c.decode(PerpsBorrowValue.self, forKey: .supply)
  }
}

/// Typed protocol response for BorrowLendUser.
public struct PerpsBorrowLendUser: Codable, Sendable {
  public let health: String?
  public let healthFactor: Decimal?
  public let tokenToState: [PerpsTokenBorrowState]
  enum CodingKeys: String, CodingKey { case tokenToState, health, healthFactor }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    health = try c.decodeIfPresent(String.self, forKey: .health)
    healthFactor = try c.optionalProtocolDecimal(.healthFactor)
    tokenToState = try c.decode([PerpsTokenBorrowState].self, forKey: .tokenToState)
  }
}

/// Typed protocol response for SubAccount.
public struct PerpsSubAccount: Codable, Sendable {
  public let name: String
  public let subAccountUser: String
  public let master: String
  public let clearinghouseState: PerpsAccountState
  public let spotState: PerpsSpotState?
  enum CodingKeys: String, CodingKey {
    case name, subAccountUser, master, clearinghouseState, spotState
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
  public let key: String
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
  public let key: Int
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
  public let key: Int
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
  public let key: String
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
  public let key: String
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
  public let key: String
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
  public let key: String
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
  public let key: Int64
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
  public let key: Int64
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
  public let key: String
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
  public let key: Int
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
  public let meta: PerpsMeta
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
  case standard, unifiedAccount, portfolioMargin, dexAbstraction, disabled, defaultMode
  case unknown(String)
  /// Decodes `AccountAbstraction` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    let value = try decoder.singleValueContainer().decode(String.self)
    switch value {
    case "standard": self = .standard
    case "unifiedAccount": self = .unifiedAccount
    case "portfolioMargin": self = .portfolioMargin
    case "dexAbstraction": self = .dexAbstraction
    case "disabled": self = .disabled
    case "default": self = .defaultMode
    default: self = .unknown(value)
    }
  }
  public var rawValue: String {
    switch self {
    case .standard: return "standard"
    case .unifiedAccount: return "unifiedAccount"
    case .portfolioMargin: return "portfolioMargin"
    case .dexAbstraction: return "dexAbstraction"
    case .disabled: return "disabled"
    case .defaultMode: return "default"
    case .unknown(let value): return value
    }
  }
  /// Encodes `AccountAbstraction` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    try c.encode(rawValue)
  }
  public var hasSharedCollateral: Bool { self == .unifiedAccount || self == .portfolioMargin }
  public var hasSeparateBalances: Bool {
    self == .standard || self == .disabled || self == .dexAbstraction
  }
  public var supportsClassTransfer: Bool { self == .standard || self == .disabled }
}

public struct TokenBalance: Sendable {
  public let coin: String
  public let token: Int
  public let total: Decimal
  public let held: Decimal
  public var unheld: Decimal { max(0, total - held) }
  public let availableAfterMaintenance: Decimal?
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

public struct PerpsDexBalance: Sendable {
  public let dex: String
  public let collateralToken: Int?
  public let accountValue: Decimal?
  public let marginUsed: Decimal?
  public let withdrawable: Decimal?
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

public struct AccountBalances: Sendable {
  public let address: String
  public let abstraction: AccountAbstraction
  public let spot: [TokenBalance]
  public let perps: [PerpsDexBalance]
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

extension PerpsActiveAssetData {
  public var availableToBuy: Decimal { availableToTrade[0] }
  public var availableToSell: Decimal { availableToTrade[1] }
  public var maxBuySize: Decimal { maxTradeSzs[0] }
  public var maxSellSize: Decimal { maxTradeSzs[1] }
}

public struct PerpsCategory: Codable, Sendable {
  public let coin: String
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
  case metadata(PerpsMeta)
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
  public var meta: PerpsMeta {
    switch self {
    case .metadata(let meta): return meta
    case .metadataAndContexts(let value): return value.meta
    }
  }
  /// Encodes `PerpsAllMetaEntry` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    switch self {
    case .metadata(let meta): try meta.encode(to: encoder)
    case .metadataAndContexts(let value): try value.encode(to: encoder)
    }
  }
}

public struct PerpsSpotToken: Codable, Sendable {
  public let name: String
  public let index: Int
  public let szDecimals: Int
  public let tokenId: String
  public let weiDecimals: Int?
  public let isCanonical: Bool?
}
public struct PerpsSpotMarket: Codable, Sendable {
  public let name: String
  public let index: Int
  public let tokens: [Int]
  public let isCanonical: Bool?
}
public struct PerpsSpotMeta: Codable, Sendable {
  public let tokens: [PerpsSpotToken]
  public let universe: [PerpsSpotMarket]
}
public struct PerpsBorrowReserve: Decodable, Sendable {
  public let borrowYearlyRate: Decimal
  public let supplyYearlyRate: Decimal
  public let balance: Decimal
  public let utilization: Decimal
  public let oraclePx: Decimal
  public let ltv: Decimal
  public let totalSupplied: Decimal
  public let totalBorrowed: Decimal
  enum CodingKeys: String, CodingKey {
    case borrowYearlyRate, supplyYearlyRate, balance, utilization, oraclePx, ltv, totalSupplied,
      totalBorrowed
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
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
public struct PerpsTokenReserve: Decodable, Sendable {
  public let token: Int
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
