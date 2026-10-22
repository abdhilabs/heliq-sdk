//
//  PerpsAccountModels.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

/// A follower's equity, profit, and withdrawal-lock information for a vault.
public struct PerpsVaultFollower: Codable, Sendable {
  /// Follower account address, when included in the response.
  public let user: String?
  /// The follower's current equity held in the vault.
  public let vaultEquity: Decimal
  /// Profit or loss reported for the follower's current vault participation.
  public let pnl: Decimal
  /// The follower's cumulative vault profit or loss.
  public let allTimePnl: Decimal
  /// Number of days the account has followed the vault.
  public let daysFollowing: Int
  /// Server-reported vault entry timestamp, when supplied.
  public let vaultEntryTime: Int64?
  /// Server-reported withdrawal-lock expiration timestamp, when supplied.
  public let lockupUntil: Int64?
  enum CodingKeys: String, CodingKey {
    case user, vaultEquity, pnl, allTimePnl, daysFollowing, vaultEntryTime, lockupUntil
  }
  /// Decodes follower amounts and optional lock timestamps from a vault response.
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

/// Addresses describing a vault's parent or child relationships.
public struct PerpsVaultRelationshipData: Codable, Sendable {
  /// Child vault addresses, absent when the relationship does not provide children.
  public let childAddresses: [String]?
  /// Parent vault address, absent when the relationship does not provide a parent.
  public let parentAddress: String?
  enum CodingKeys: String, CodingKey { case childAddresses, parentAddress }
  /// Decodes the optional parent and child addresses for a vault relationship.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    childAddresses = try c.decodeIfPresent([String].self, forKey: .childAddresses)
    parentAddress = try c.decodeIfPresent(String.self, forKey: .parentAddress)
  }
}

/// A server-defined vault relationship and its optional address details.
public struct PerpsVaultRelationship: Codable, Sendable {
  /// Relationship discriminator preserved as returned by the server.
  public let type: String
  /// Parent or child addresses, when present for this relationship type.
  public let data: PerpsVaultRelationshipData?
  enum CodingKeys: String, CodingKey { case type, data }
  /// Decodes the relationship discriminator and any associated address data.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    type = try c.decode(String.self, forKey: .type)
    data = try c.decodeIfPresent(PerpsVaultRelationshipData.self, forKey: .data)
  }
}

/// Vault configuration, performance, and follower-specific withdrawal information.
public struct PerpsVaultDetails: Codable, Sendable {
  /// Display name of the vault.
  public let name: String
  /// Address identifying the vault account.
  public let vaultAddress: String
  /// Address of the account leading the vault.
  public let leader: String
  /// Description published for the vault.
  public let description: String
  /// Performance histories grouped by the server's reporting periods.
  public let portfolio: [PerpsPortfolioPeriod]
  /// Server-reported annual percentage rate, retained without percentage conversion.
  public let apr: Decimal
  /// Queried user's follower state, absent when the server provides none.
  public let followerState: PerpsVaultFollower?
  /// Server-reported fraction of vault equity belonging to the leader.
  public let leaderFraction: Decimal
  /// Server-reported leader commission fraction.
  public let leaderCommission: Decimal
  /// Follower equity and performance entries returned for the vault.
  public let followers: [PerpsVaultFollower]
  /// Maximum amount the server currently permits the vault to distribute.
  public let maxDistributable: Decimal
  /// Maximum withdrawable amount reported by the server, not inferred from equity.
  public let maxWithdrawable: Decimal
  /// Whether the server marks the vault as closed.
  public let isClosed: Bool
  /// The vault's relationship to any parent or child vaults.
  public let relationship: PerpsVaultRelationship
  /// Whether the vault currently accepts deposits.
  public let allowDeposits: Bool
  /// Whether withdrawals require positions to be closed according to vault policy.
  public let alwaysCloseOnWithdraw: Bool
  enum CodingKeys: String, CodingKey {
    case name, vaultAddress, leader, description, portfolio, apr, followerState, leaderFraction,
      leaderCommission, followers, maxDistributable, maxWithdrawable, isClosed, relationship,
      allowDeposits, alwaysCloseOnWithdraw
  }
  /// Decodes vault details, preserving exact decimal amounts and an optional follower state.
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

/// A user's equity attributed to one vault.
public struct PerpsVaultEquity: Codable, Sendable {
  /// Address of the vault holding the equity.
  public let vaultAddress: String
  /// Equity amount reported for this vault.
  public let equity: Decimal
  enum CodingKeys: String, CodingKey { case vaultAddress, equity }
  /// Decodes a vault address and its protocol decimal equity amount.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    vaultAddress = try c.decode(String.self, forKey: .vaultAddress)
    equity = try c.protocolDecimal(.equity)
  }
}

/// The referrer account and referral code associated with a referred user.
public struct PerpsReferralOwner: Codable, Sendable {
  /// Address of the referring account.
  public let referrer: String
  /// Referral code used to establish the relationship.
  public let code: String
  enum CodingKeys: String, CodingKey { case referrer, code }
  /// Decodes the referring account address and its referral code.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    referrer = try c.decode(String.self, forKey: .referrer)
    code = try c.decode(String.self, forKey: .code)
  }
}

/// Cumulative volume and referral rewards for a reported reward ledger.
public struct PerpsReferralRewardTotals: Codable, Sendable {
  /// Cumulative trading volume reported for this reward ledger.
  public let cumVlm: Decimal
  /// Accrued referral rewards not yet claimed.
  public let unclaimedRewards: Decimal
  /// Referral rewards already claimed.
  public let claimedRewards: Decimal
  /// Builder rewards reported for this ledger.
  public let builderRewards: Decimal
  enum CodingKeys: String, CodingKey {
    case cumVlm, unclaimedRewards, claimedRewards, builderRewards
  }
  /// Decodes cumulative volume and reward amounts without floating-point conversion.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cumVlm = try c.protocolDecimal(.cumVlm)
    unclaimedRewards = try c.protocolDecimal(.unclaimedRewards)
    claimedRewards = try c.protocolDecimal(.claimedRewards)
    builderRewards = try c.protocolDecimal(.builderRewards)
  }
}

/// Trading volume and reward accounting for one referred account.
public struct PerpsReferredUser: Codable, Sendable {
  /// Cumulative trading volume reported for the referred user.
  public let cumVlm: Decimal
  /// Fees since referral that were eligible for referral rewards.
  public let cumRewardedFeesSinceReferred: Decimal
  /// Cumulative fees rewarded to the referrer for this user.
  public let cumFeesRewardedToReferrer: Decimal
  /// Referral join timestamp as supplied by the server.
  public let timeJoined: Int64
  /// Address of the referred account.
  public let user: String
  enum CodingKeys: String, CodingKey {
    case cumVlm, cumRewardedFeesSinceReferred, cumFeesRewardedToReferrer, timeJoined, user
  }
  /// Decodes a referred account's join time, volume, and fee accounting.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    cumVlm = try c.protocolDecimal(.cumVlm)
    cumRewardedFeesSinceReferred = try c.protocolDecimal(.cumRewardedFeesSinceReferred)
    cumFeesRewardedToReferrer = try c.protocolDecimal(.cumFeesRewardedToReferrer)
    timeJoined = try c.decode(Int64.self, forKey: .timeJoined)
    user = try c.decode(String.self, forKey: .user)
  }
}

/// Stage-dependent referral details; unavailable fields remain absent.
public struct PerpsReferralData: Codable, Sendable {
  /// The account's referral code, when available at its current stage.
  public let code: String?
  /// Requirement amount reported for the current referral stage, when supplied.
  public let required: Decimal?
  /// Referred-account statistics, when included for the current stage.
  public let referralStates: [PerpsReferredUser]?
  enum CodingKeys: String, CodingKey { case code, required, referralStates }
  /// Decodes optional fields without inventing values for an inapplicable referral stage.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    code = try c.decodeIfPresent(String.self, forKey: .code)
    required = try c.optionalProtocolDecimal(.required)
    referralStates = try c.decodeIfPresent([PerpsReferredUser].self, forKey: .referralStates)
  }
}

/// The account's server-defined stage in the referral program.
public struct PerpsReferrerState: Codable, Sendable {
  /// Stage discriminator preserved without restricting future server values.
  public let stage: String
  /// Additional details available at this stage, if any.
  public let data: PerpsReferralData?
  enum CodingKeys: String, CodingKey { case stage, data }
  /// Decodes the referral stage and its optional details.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    stage = try c.decode(String.self, forKey: .stage)
    data = try c.decodeIfPresent(PerpsReferralData.self, forKey: .data)
  }
}

/// Referral relationships, reward totals, and the account's referrer-program state.
public struct PerpsReferral: Codable, Sendable {
  /// Existing referrer relationship, or nil when the server reports none.
  public let referredBy: PerpsReferralOwner?
  /// Cumulative trading volume reported by the referral endpoint.
  public let cumVlm: Decimal
  /// Accrued referral rewards not yet claimed.
  public let unclaimedRewards: Decimal
  /// Referral rewards already claimed.
  public let claimedRewards: Decimal
  /// Builder rewards reported by the referral endpoint.
  public let builderRewards: Decimal
  /// Per-token reward ledgers, when provided; amounts from different tokens are not combined.
  public let tokenToState: [PerpsTokenReferralTotals]?
  /// Current referral-program stage and any associated details.
  public let referrerState: PerpsReferrerState
  enum CodingKeys: String, CodingKey {
    case referredBy, cumVlm, unclaimedRewards, claimedRewards, builderRewards, tokenToState,
      referrerState
  }
  /// Decodes account referral data and optional token-specific reward ledgers.
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

/// A fee-discount tier indexed by the staked share of maximum token supply.
public struct PerpsStakingDiscount: Codable, Sendable {
  /// Staking threshold expressed in basis points of maximum supply.
  public let bpsOfMaxSupply: Decimal
  /// Server-reported discount fraction for this threshold.
  public let discount: Decimal
  enum CodingKeys: String, CodingKey { case bpsOfMaxSupply, discount }
  /// Decodes the staking threshold and its discount using protocol decimals.
  public init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    bpsOfMaxSupply = try c.protocolDecimal(.bpsOfMaxSupply)
    discount = try c.protocolDecimal(.discount)
  }
}

/// One token's referral rewards decoded from a protocol `[token, totals]` tuple.
public struct PerpsTokenReferralTotals: Codable, Sendable {
  /// Spot token index identifying the reward denomination.
  public let token: Int
  /// Volume and reward totals associated with this token.
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
