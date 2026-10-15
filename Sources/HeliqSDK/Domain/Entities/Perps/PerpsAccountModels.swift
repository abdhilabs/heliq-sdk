//
//  PerpsAccountModels.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

public struct PerpsVaultFollower: Codable, Sendable {
  public let user: String?
  public let vaultEquity: Decimal
  public let pnl: Decimal
  public let allTimePnl: Decimal
  public let daysFollowing: Int
  public let vaultEntryTime: Int64?
  public let lockupUntil: Int64?
  enum CodingKeys: String, CodingKey {
    case user, vaultEquity, pnl, allTimePnl, daysFollowing, vaultEntryTime, lockupUntil
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    user = try c.decodeIfPresent(String.self, forKey: .user)
    vaultEquity = try c.protocolDecimal(.vaultEquity)
    pnl = try c.protocolDecimal(.pnl)
    allTimePnl = try c.protocolDecimal(.allTimePnl)
    daysFollowing = try c.decode(Int.self, forKey: .daysFollowing)
    vaultEntryTime = try c.decodeIfPresent(Int64.self, forKey: .vaultEntryTime)
    lockupUntil = try c.decodeIfPresent(Int64.self, forKey: .lockupUntil)
  }
}

public struct PerpsVaultRelationshipData: Codable, Sendable {
  public let childAddresses: [String]?
  public let parentAddress: String?
  enum CodingKeys: String, CodingKey { case childAddresses, parentAddress }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    childAddresses = try c.decodeIfPresent([String].self, forKey: .childAddresses)
    parentAddress = try c.decodeIfPresent(String.self, forKey: .parentAddress)
  }
}

public struct PerpsVaultRelationship: Codable, Sendable {
  public let type: String
  public let data: PerpsVaultRelationshipData?
  enum CodingKeys: String, CodingKey { case type, data }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    data = try c.decodeIfPresent(PerpsVaultRelationshipData.self, forKey: .data)
  }
}

public struct PerpsVaultDetails: Codable, Sendable {
  public let name: String
  public let vaultAddress: String
  public let leader: String
  public let description: String
  public let portfolio: [PerpsPortfolioPeriod]
  public let apr: Decimal
  public let followerState: PerpsVaultFollower?
  public let leaderFraction: Decimal
  public let leaderCommission: Decimal
  public let followers: [PerpsVaultFollower]
  public let maxDistributable: Decimal
  public let maxWithdrawable: Decimal
  public let isClosed: Bool
  public let relationship: PerpsVaultRelationship
  public let allowDeposits: Bool
  public let alwaysCloseOnWithdraw: Bool
  enum CodingKeys: String, CodingKey {
    case name, vaultAddress, leader, description, portfolio, apr, followerState, leaderFraction,
      leaderCommission, followers, maxDistributable, maxWithdrawable, isClosed, relationship,
      allowDeposits, alwaysCloseOnWithdraw
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    name = try c.decode(String.self, forKey: .name)
    vaultAddress = try c.decode(String.self, forKey: .vaultAddress)
    leader = try c.decode(String.self, forKey: .leader)
    description = try c.decode(String.self, forKey: .description)
    portfolio = try c.decode([PerpsPortfolioPeriod].self, forKey: .portfolio)
    apr = try c.protocolDecimal(.apr)
    followerState = try c.decodeIfPresent(PerpsVaultFollower.self, forKey: .followerState)
    leaderFraction = try c.protocolDecimal(.leaderFraction)
    leaderCommission = try c.protocolDecimal(.leaderCommission)
    followers = try c.decode([PerpsVaultFollower].self, forKey: .followers)
    maxDistributable = try c.protocolDecimal(.maxDistributable)
    maxWithdrawable = try c.protocolDecimal(.maxWithdrawable)
    isClosed = try c.decode(Bool.self, forKey: .isClosed)
    relationship = try c.decode(PerpsVaultRelationship.self, forKey: .relationship)
    allowDeposits = try c.decode(Bool.self, forKey: .allowDeposits)
    alwaysCloseOnWithdraw = try c.decode(Bool.self, forKey: .alwaysCloseOnWithdraw)
  }
}

public struct PerpsVaultEquity: Codable, Sendable {
  public let vaultAddress: String
  public let equity: Decimal
  enum CodingKeys: String, CodingKey { case vaultAddress, equity }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    vaultAddress = try c.decode(String.self, forKey: .vaultAddress)
    equity = try c.protocolDecimal(.equity)
  }
}

public struct PerpsReferralOwner: Codable, Sendable {
  public let referrer: String
  public let code: String
  enum CodingKeys: String, CodingKey { case referrer, code }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    referrer = try c.decode(String.self, forKey: .referrer)
    code = try c.decode(String.self, forKey: .code)
  }
}

public struct PerpsReferralRewardTotals: Codable, Sendable {
  public let cumVlm: Decimal
  public let unclaimedRewards: Decimal
  public let claimedRewards: Decimal
  public let builderRewards: Decimal
  enum CodingKeys: String, CodingKey {
    case cumVlm, unclaimedRewards, claimedRewards, builderRewards
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cumVlm = try c.protocolDecimal(.cumVlm)
    unclaimedRewards = try c.protocolDecimal(.unclaimedRewards)
    claimedRewards = try c.protocolDecimal(.claimedRewards)
    builderRewards = try c.protocolDecimal(.builderRewards)
  }
}

public struct PerpsReferredUser: Codable, Sendable {
  public let cumVlm: Decimal
  public let cumRewardedFeesSinceReferred: Decimal
  public let cumFeesRewardedToReferrer: Decimal
  public let timeJoined: Int64
  public let user: String
  enum CodingKeys: String, CodingKey {
    case cumVlm, cumRewardedFeesSinceReferred, cumFeesRewardedToReferrer, timeJoined, user
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cumVlm = try c.protocolDecimal(.cumVlm)
    cumRewardedFeesSinceReferred = try c.protocolDecimal(.cumRewardedFeesSinceReferred)
    cumFeesRewardedToReferrer = try c.protocolDecimal(.cumFeesRewardedToReferrer)
    timeJoined = try c.decode(Int64.self, forKey: .timeJoined)
    user = try c.decode(String.self, forKey: .user)
  }
}

public struct PerpsReferralData: Codable, Sendable {
  public let code: String?
  public let required: Decimal?
  public let referralStates: [PerpsReferredUser]?
  enum CodingKeys: String, CodingKey { case code, required, referralStates }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    code = try c.decodeIfPresent(String.self, forKey: .code)
    required = try c.optionalProtocolDecimal(.required)
    referralStates = try c.decodeIfPresent([PerpsReferredUser].self, forKey: .referralStates)
  }
}

public struct PerpsReferrerState: Codable, Sendable {
  public let stage: String
  public let data: PerpsReferralData?
  enum CodingKeys: String, CodingKey { case stage, data }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    stage = try c.decode(String.self, forKey: .stage)
    data = try c.decodeIfPresent(PerpsReferralData.self, forKey: .data)
  }
}

public struct PerpsReferral: Codable, Sendable {
  public let referredBy: PerpsReferralOwner?
  public let cumVlm: Decimal
  public let unclaimedRewards: Decimal
  public let claimedRewards: Decimal
  public let builderRewards: Decimal
  public let tokenToState: [PerpsTokenReferralTotals]?
  public let referrerState: PerpsReferrerState
  enum CodingKeys: String, CodingKey {
    case referredBy, cumVlm, unclaimedRewards, claimedRewards, builderRewards, tokenToState,
      referrerState
  }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    referredBy = try c.decodeIfPresent(PerpsReferralOwner.self, forKey: .referredBy)
    cumVlm = try c.protocolDecimal(.cumVlm)
    unclaimedRewards = try c.protocolDecimal(.unclaimedRewards)
    claimedRewards = try c.protocolDecimal(.claimedRewards)
    builderRewards = try c.protocolDecimal(.builderRewards)
    tokenToState = try c.decodeIfPresent([PerpsTokenReferralTotals].self, forKey: .tokenToState)
    referrerState = try c.decode(PerpsReferrerState.self, forKey: .referrerState)
  }
}

public struct PerpsStakingDiscount: Codable, Sendable {
  public let bpsOfMaxSupply: Decimal
  public let discount: Decimal
  enum CodingKeys: String, CodingKey { case bpsOfMaxSupply, discount }
  /// Decodes `CodingKeys` from its protocol response representation; invalid required values throw.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bpsOfMaxSupply = try c.protocolDecimal(.bpsOfMaxSupply)
    discount = try c.protocolDecimal(.discount)
  }
}

public struct PerpsTokenReferralTotals: Codable, Sendable {
  public let token: Int
  public let totals: PerpsReferralRewardTotals
  /// Decodes `PerpsTokenReferralTotals` from its protocol response representation; invalid required
  /// values throw.
  public init(from decoder: Decoder) throws {
    var c = try decoder.unkeyedContainer()
    token = try c.decode(Int.self)
    totals = try c.decode(PerpsReferralRewardTotals.self)
    guard c.isAtEnd else { throw APIError.invalidResponse }
  }
  /// Encodes `PerpsTokenReferralTotals` using its protocol field or tuple representation.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.unkeyedContainer()
    try c.encode(token)
    try c.encode(totals)
  }
}
