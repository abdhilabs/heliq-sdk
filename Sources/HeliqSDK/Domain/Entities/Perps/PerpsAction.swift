//
//  PerpsAction.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

public enum PerpsMarket: Sendable, Hashable {
  case asset(Int)
  /// Use the exact metadata name, including the HIP-3 DEX prefix.
  case coin(String)
}

public enum PerpsTimeInForce: String, Codable, Sendable {
  case gtc = "Gtc"
  case ioc = "Ioc"
  case alo = "Alo"
}
public enum PerpsGrouping: String, Codable, Sendable {
  case none = "na"
  case normalTpsl, positionTpsl
}
public enum PerpsTriggerKind: String, Codable, Sendable {
  case takeProfit = "tp"
  case stopLoss = "sl"
}
public enum PerpsOrderKind: Sendable {
  case limit(PerpsTimeInForce)
  case market(slippage: Decimal = Decimal(string: "0.05")!)
  case trigger(price: Decimal, kind: PerpsTriggerKind, market: Bool)
}

public struct PerpsOrderRequest: Sendable {
  public let market: PerpsMarket
  public let side: OrderSide
  public let size: Decimal
  public let price: Decimal?
  public let kind: PerpsOrderKind
  public let reduceOnly: Bool
  public let cloid: String?
  /// Creates a decimal order; price is required for limit orders and market slippage is validated
  /// on submission.
  public init(
    market: PerpsMarket, side: OrderSide, size: Decimal, price: Decimal? = nil,
    kind: PerpsOrderKind = .limit(.gtc), reduceOnly: Bool = false, cloid: String? = nil
  ) {
    self.market = market
    self.side = side
    self.size = size
    self.price = price
    self.kind = kind
    self.reduceOnly = reduceOnly
    self.cloid = cloid
  }
}

public enum PerpsOrderIdentifier: Sendable {
  case orderID(Int64)
  case cloid(String)
}
public struct PerpsCancellation: Sendable {
  public let market: PerpsMarket
  public let identifier: PerpsOrderIdentifier
  /// Selects an order to cancel by market and exchange or client order identifier.
  public init(market: PerpsMarket, identifier: PerpsOrderIdentifier) {
    self.market = market
    self.identifier = identifier
  }
}
public struct PerpsModification: Sendable {
  public let identifier: PerpsOrderIdentifier
  public let order: PerpsOrderRequest
  /// Pairs an existing order identifier with its replacement order parameters.
  public init(identifier: PerpsOrderIdentifier, order: PerpsOrderRequest) {
    self.identifier = identifier
    self.order = order
  }
}
public struct PerpsBuilderFee: Sendable {
  public let address: String
  /// Fee in tenths of a basis point, matching the protocol's `f` field.
  public let fee: Int
  /// Sets the builder address and fee in tenths of a basis point, validated before submission.
  public init(address: String, fee: Int) {
    self.address = address
    self.fee = fee
  }
}
public struct PerpsExecutionContext: Sendable {
  public let vaultAddress: String?
  public let expiresAfter: Date?
  /// Sets optional vault execution and expiration; unsupported user-signed actions reject this
  /// context.
  public init(vaultAddress: String? = nil, expiresAfter: Date? = nil) {
    self.vaultAddress = vaultAddress
    self.expiresAfter = expiresAfter
  }
}
public enum PerpsLedger: Sendable {
  case spot
  case perps(dex: String = "")
  var wire: String {
    switch self {
    case .spot: return "spot"
    case .perps(let dex): return dex
    }
  }
}
public enum PerpsAccountMode: String, Sendable {
  case standard = "disabled"
  case unifiedAccount, portfolioMargin
}
public enum PerpsAgentMode: String, Sendable {
  case standard = "i"
  case unifiedAccount = "u"
  case portfolioMargin = "p"
}
public enum PerpsRetracement: Sendable {
  case percent(Decimal)
  case price(Decimal)
}

/// Typed, signed operations. Unknown operations remain available through `sdk.raw`.
public indirect enum PerpsAction: Sendable {
  case orders([PerpsOrderRequest], grouping: PerpsGrouping = .none, builder: PerpsBuilderFee? = nil)
  case cancel([PerpsCancellation], fast: Bool = false)
  case modify([PerpsModification], alwaysPlace: Bool = false)
  case modifyOrder(PerpsModification, alwaysPlace: Bool = false)
  case scheduleCancel(Date?)
  case leverage(market: PerpsMarket, value: Int, cross: Bool)
  case isolatedMargin(market: PerpsMarket, amount: Decimal)
  case isolatedLeverage(market: PerpsMarket, leverage: Decimal)
  case marketClose(
    market: PerpsMarket, size: Decimal? = nil, slippage: Decimal = Decimal(string: "0.05")!)
  case twap(
    market: PerpsMarket, side: OrderSide, size: Decimal, minutes: Int, reduceOnly: Bool,
    randomize: Bool)
  case cancelTwap(market: PerpsMarket, id: Int64)
  case trailingStop(
    market: PerpsMarket, side: OrderSide, size: Decimal, reduceOnly: Bool,
    retracement: PerpsRetracement, activationPrice: Decimal?)
  case usdClassTransfer(amount: Decimal, toPerp: Bool)
  case sendAsset(
    destination: String, source: PerpsLedger, destinationLedger: PerpsLedger,
    token: String, amount: Decimal, fromSubAccount: String = "")
  case agentSendAsset(
    account: String, source: PerpsLedger, destinationLedger: PerpsLedger,
    token: String, amount: Decimal, fromSubAccount: String = "")
  case approveAgent(address: String, name: String?)
  case userAbstraction(address: String, mode: PerpsAccountMode)
  case agentAbstraction(PerpsAgentMode)
  case legacyUserDexAbstraction(address: String, enabled: Bool)
  case legacyAgentDexAbstraction
  case createSubAccount(name: String)
  case subAccountTransfer(address: String, deposit: Bool, amount: Decimal)
  case subAccountSpotTransfer(address: String, deposit: Bool, token: String, amount: Decimal)
  case reserveRequestWeight(Int, destination: String? = nil)
  case invalidateNonce(Int64)
  case withdraw(destination: String, amount: Decimal)
  case approveBuilder(address: String, maxFeePercent: Decimal)
  case vaultTransfer(address: String, deposit: Bool, amount: Decimal)
  case setReferrer(code: String)
  case convertMultisig(authorizedUsers: [String], threshold: Int)
  case restoreNormalAccount
  case deploy(PerpsDeployAction)
  case liquidatorTransfer(dex: String, amount: Decimal, deposit: Bool)
}

public enum PerpsOrderStatus: Sendable {
  case resting(orderID: Int64)
  case filled(orderID: Int64, size: Decimal, price: Decimal)
  case waitingForFill, waitingForTrigger
  case rejected(String)
}
public enum PerpsCancellationStatus: Sendable {
  case success
  case rejected(String)
}
public enum PerpsActionResult: Sendable {
  case success
  case orders([PerpsOrderStatus])
  case cancellations([PerpsCancellationStatus])
  case twap(id: Int64)
  case trailingStop(orderID: Int64)
}

/// Converts a date to a validated integer protocol timestamp in milliseconds.
func perpsMilliseconds(_ date: Date) throws -> Int64 {
  let value = date.timeIntervalSince1970 * 1000
  guard value.isFinite, value >= 0, value < 9_007_199_254_740_992 else {
    throw ValidationError.malformedData(reason: "Invalid timestamp")
  }
  return Int64(value)
}
