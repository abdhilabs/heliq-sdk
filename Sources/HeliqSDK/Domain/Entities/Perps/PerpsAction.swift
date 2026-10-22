//
//  PerpsAction.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

/// Selects a perpetual market by protocol asset index or metadata name.
public enum PerpsMarket: Sendable, Hashable {
  /// The protocol asset index, including the DEX-specific offset for HIP-3 markets.
  case asset(Int)
  /// Use the exact metadata name, including the HIP-3 DEX prefix.
  case coin(String)
}

/// Execution and resting policy for a limit order.
public enum PerpsTimeInForce: String, Codable, Sendable {
  /// Keeps the unfilled quantity resting until canceled.
  case gtc = "Gtc"
  /// Executes immediately available quantity and cancels the remainder.
  case ioc = "Ioc"
  /// Adds liquidity only rather than immediately taking liquidity.
  case alo = "Alo"
}
/// Protocol grouping for standalone orders and take-profit/stop-loss orders.
public enum PerpsGrouping: String, Codable, Sendable {
  /// Submits orders without TP/SL grouping.
  case none = "na"
  /// Groups ordinary take-profit/stop-loss orders.
  case normalTpsl
  /// Groups take-profit/stop-loss orders associated with a position.
  case positionTpsl
}
/// Whether a trigger represents a profit target or a loss limit.
public enum PerpsTriggerKind: String, Codable, Sendable {
  /// A take-profit trigger.
  case takeProfit = "tp"
  /// A stop-loss trigger.
  case stopLoss = "sl"
}
/// Order execution style; prices and sizes are validated against market metadata on submission.
public enum PerpsOrderKind: Sendable {
  /// A limit order requiring an explicit request price.
  case limit(PerpsTimeInForce)
  /// An IOC limit order; absent an explicit price, derives one from the midpoint and slippage.
  /// Slippage is a fraction in `0..<1`; `0.05` means 5%, not a fill guarantee.
  case market(slippage: Decimal = Decimal(string: "0.05")!)
  /// A trigger at the supplied price. Nonmarket triggers require a request price; market
  /// triggers without one derive a limit price 5% beyond the trigger in the order direction.
  case trigger(price: Decimal, kind: PerpsTriggerKind, market: Bool)
}

/// Decimal order parameters, resolved and validated when submitted rather than at initialization.
public struct PerpsOrderRequest: Sendable {
  /// Market whose metadata defines size and price precision.
  public let market: PerpsMarket
  /// Buy or sell direction.
  public let side: OrderSide
  /// Positive quantity in base-asset units, respecting the market's size decimals.
  public let size: Decimal
  /// Limit execution price in quote units per base unit; may be derived for market-style orders.
  public let price: Decimal?
  /// Execution style and any trigger or slippage parameters.
  public let kind: PerpsOrderKind
  /// Requests that execution only reduce an existing position.
  public let reduceOnly: Bool
  /// Optional client order ID, validated as a protocol cloid on submission.
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

/// Selects an order by its exchange-assigned ID or client-supplied cloid.
public enum PerpsOrderIdentifier: Sendable {
  /// Exchange-assigned order number.
  case orderID(Int64)
  /// Client-supplied protocol cloid.
  case cloid(String)
}
/// One market-specific cancellation within a cancellation action.
public struct PerpsCancellation: Sendable {
  /// Market containing the order.
  public let market: PerpsMarket
  /// Exchange order ID or client cloid to cancel.
  public let identifier: PerpsOrderIdentifier
  /// Selects an order to cancel by market and exchange or client order identifier.
  public init(market: PerpsMarket, identifier: PerpsOrderIdentifier) {
    self.market = market
    self.identifier = identifier
  }
}
/// Replacement parameters for an existing order.
public struct PerpsModification: Sendable {
  /// Existing order to replace.
  public let identifier: PerpsOrderIdentifier
  /// Complete replacement order, including its market.
  public let order: PerpsOrderRequest
  /// Pairs an existing order identifier with its replacement order parameters.
  public init(identifier: PerpsOrderIdentifier, order: PerpsOrderRequest) {
    self.identifier = identifier
    self.order = order
  }
}
/// Builder attribution and fee attached to an order action.
public struct PerpsBuilderFee: Sendable {
  /// Builder's address, validated before submission.
  public let address: String
  /// Fee in tenths of a basis point, matching the protocol's `f` field.
  public let fee: Int
  /// Sets the builder address and fee in tenths of a basis point, validated before submission.
  public init(address: String, fee: Int) {
    self.address = address
    self.fee = fee
  }
}
/// Optional execution envelope for actions that support vaults and expiration.
public struct PerpsExecutionContext: Sendable {
  /// Vault on whose behalf to execute, or `nil` for the signing account.
  public let vaultAddress: String?
  /// Expiration date encoded as Unix milliseconds; unsupported user-signed actions reject it.
  public let expiresAfter: Date?
  /// Sets optional vault execution and expiration; unsupported user-signed actions reject this
  /// context.
  public init(vaultAddress: String? = nil, expiresAfter: Date? = nil) {
    self.vaultAddress = vaultAddress
    self.expiresAfter = expiresAfter
  }
}
/// Source or destination balance ledger for asset transfers.
public enum PerpsLedger: Sendable {
  /// Spot balances, encoded as `spot`.
  case spot
  /// Perpetual collateral ledger; the empty DEX name selects the default perpetual DEX.
  case perps(dex: String = "")
  var wire: String {
    switch self {
    case .spot: return "spot"
    case .perps(let dex): return dex
    }
  }
}
/// User-signed account abstraction setting, using the protocol's full wire names.
public enum PerpsAccountMode: String, Sendable {
  /// Separate standard ledgers; encoded as `disabled`.
  case standard = "disabled"
  /// Unified-account abstraction.
  case unifiedAccount
  /// Portfolio-margin abstraction.
  case portfolioMargin
}
/// Agent-signed account abstraction setting, using compact protocol codes.
public enum PerpsAgentMode: String, Sendable {
  /// Standard account mode (`i`).
  case standard = "i"
  /// Unified-account mode (`u`).
  case unifiedAccount = "u"
  /// Portfolio-margin mode (`p`).
  case portfolioMargin = "p"
}
/// Distance used by a trailing stop, expressed in percentage points or price units.
public enum PerpsRetracement: Sendable {
  /// Positive percentage points below 100; `5` is encoded as `5%`.
  case percent(Decimal)
  /// Positive price distance respecting the market's price precision.
  case price(Decimal)
}

/// Typed, signed operations. Unknown operations remain available through `sdk.raw`.
public indirect enum PerpsAction: Sendable {
  /// Places orders with optional TP/SL grouping and builder attribution.
  case orders([PerpsOrderRequest], grouping: PerpsGrouping = .none, builder: PerpsBuilderFee? = nil)
  /// Cancels orders; `fast` selects the protocol's fast cancellation variant.
  case cancel([PerpsCancellation], fast: Bool = false)
  /// Replaces multiple orders; `alwaysPlace` can place the new order even if cancellation fails.
  /// Without it, the SDK accepts only Gtc/Alo limit replacements, not IOC or trigger orders.
  case modify([PerpsModification], alwaysPlace: Bool = false)
  /// Replaces one order using the single-order endpoint, with the same `alwaysPlace` rules as a batch.
  case modifyOrder(PerpsModification, alwaysPlace: Bool = false)
  /// Schedules cancellation at a date, or clears the schedule with `nil`.
  case scheduleCancel(Date?)
  /// Sets integer leverage within the market maximum and selects cross or isolated margin.
  case leverage(market: PerpsMarket, value: Int, cross: Bool)
  /// Adds or removes nonzero collateral in exact six-decimal units; strict isolated forbids removal.
  case isolatedMargin(market: PerpsMarket, amount: Decimal)
  /// Tops up isolated-only margin using positive target leverage within the market maximum.
  case isolatedLeverage(market: PerpsMarket, leverage: Decimal)
  /// Closes the current position with a reduce-only IOC order. Nil size closes its full size;
  /// explicit base-asset size cannot exceed it. Slippage is a fraction (`0.05` is 5%).
  case marketClose(
    market: PerpsMarket, size: Decimal? = nil, slippage: Decimal = Decimal(string: "0.05")!)
  /// Places a time-weighted order in base-asset units over 5...1440 minutes, optionally randomized.
  case twap(
    market: PerpsMarket, side: OrderSide, size: Decimal, minutes: Int, reduceOnly: Bool,
    randomize: Bool)
  /// Cancels a TWAP by market and positive protocol TWAP ID.
  case cancelTwap(market: PerpsMarket, id: Int64)
  /// Places a trailing stop in base-asset units, optionally activated at a market-valid price.
  case trailingStop(
    market: PerpsMarket, side: OrderSide, size: Decimal, reduceOnly: Bool,
    retracement: PerpsRetracement, activationPrice: Decimal?)
  /// Moves a positive six-decimal USDC amount between Spot and Perps in standard account mode.
  /// `toPerp` selects the destination; shared-collateral modes reject this operation.
  case usdClassTransfer(amount: Decimal, toPerp: Bool)
  /// User-signed transfer in token units between ledgers. Token metadata determines precision;
  /// `fromSubAccount` is empty for the main account or a subaccount address.
  case sendAsset(
    destination: String, source: PerpsLedger, destinationLedger: PerpsLedger,
    token: String, amount: Decimal, fromSubAccount: String = "")
  /// Agent-signed asset transfer to `account`, with the same token and ledger checks as sendAsset.
  case agentSendAsset(
    account: String, source: PerpsLedger, destinationLedger: PerpsLedger,
    token: String, amount: Decimal, fromSubAccount: String = "")
  /// Authorizes an agent address; nil name is encoded as an empty name.
  case approveAgent(address: String, name: String?)
  /// User-signed abstraction setting for the supplied address.
  case userAbstraction(address: String, mode: PerpsAccountMode)
  /// Agent-signed abstraction setting using compact mode codes.
  case agentAbstraction(PerpsAgentMode)
  /// Legacy user-signed DEX abstraction toggle for the supplied address.
  case legacyUserDexAbstraction(address: String, enabled: Bool)
  /// Legacy agent-signed request to enable DEX abstraction.
  case legacyAgentDexAbstraction
  /// Creates a subaccount with a nonempty name.
  case createSubAccount(name: String)
  /// Moves a positive exact six-decimal USDC amount into or out of a subaccount.
  case subAccountTransfer(address: String, deposit: Bool, amount: Decimal)
  /// Moves a positive metadata-precision token amount into or out of a subaccount's spot ledger.
  case subAccountSpotTransfer(address: String, deposit: Bool, token: String, amount: Decimal)
  /// Reserves positive request weight, optionally for a destination address.
  case reserveRequestWeight(Int, destination: String? = nil)
  /// Submits a no-op at the supplied nonce to invalidate it.
  case invalidateNonce(Int64)
  /// User-signed withdrawal of a positive USDC amount to a destination address.
  case withdraw(destination: String, amount: Decimal)
  /// Approves a builder's maximum fee in percentage points, from 0 through 1 inclusive.
  case approveBuilder(address: String, maxFeePercent: Decimal)
  /// Moves a positive exact six-decimal USDC amount into or out of a vault.
  case vaultTransfer(address: String, deposit: Bool, amount: Decimal)
  /// Sets a nonempty referral code.
  case setReferrer(code: String)
  /// Converts to multisig with 1...10 unique addresses and a threshold within that count.
  case convertMultisig(authorizedUsers: [String], threshold: Int)
  /// Requests conversion from multisig back to a normal account.
  case restoreNormalAccount
  /// Submits a signed HIP-3 deployment operation; authorization is enforced by the service.
  case deploy(PerpsDeployAction)
  /// Transfers liquidator collateral for a named DEX in positive multiples of 1000 tokens.
  case liquidatorTransfer(dex: String, amount: Decimal, deposit: Bool)
}

/// Per-order outcome returned by an order submission.
public enum PerpsOrderStatus: Sendable {
  /// Order is resting with an exchange-assigned ID.
  case resting(orderID: Int64)
  /// Execution details: exchange ID, base-asset size, and execution price.
  case filled(orderID: Int64, size: Decimal, price: Decimal)
  /// Order is waiting for a fill.
  case waitingForFill
  /// Conditional order is waiting for its trigger.
  case waitingForTrigger
  /// Service-provided rejection reason.
  case rejected(String)
}
/// Per-order outcome returned by cancellation.
public enum PerpsCancellationStatus: Sendable {
  /// Service reported a successful cancellation.
  case success
  /// Service-provided rejection reason.
  case rejected(String)
}
/// Typed response to a submitted perpetual action.
public enum PerpsActionResult: Sendable {
  /// Successful action without a more specific result payload.
  case success
  /// Individual order outcomes, which can include rejections.
  case orders([PerpsOrderStatus])
  /// Individual cancellation outcomes, which can include rejections.
  case cancellations([PerpsCancellationStatus])
  /// Identifier assigned to a TWAP order.
  case twap(id: Int64)
  /// Identifier assigned to a trailing-stop order.
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
