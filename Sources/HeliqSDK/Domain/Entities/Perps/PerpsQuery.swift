//
//  PerpsQuery.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

/// Typed read request. Factories bind each endpoint to its response schema.
///
/// Submit a factory result through `info.perps(_:)`. An empty `dex` selects validator Perps;
/// HIP-3 markets use their registered DEX name and exact prefixed metadata coin name.
/// Account queries take the account address, rather than an approved agent’s address.
public struct PerpsQuery<Response: Sendable>: Sendable {
  public let request: HyperliquidInfoRequest
  private let decodeResponse: @Sendable (Data) throws -> Response
  /// Binds an info endpoint and its parameters to a concrete response decoder.
  init(
    type: String, parameters: [String: JSONValue] = [:],
    decode: @escaping @Sendable (Data) throws -> Response
  ) {
    request = .init(type: .custom(type), parameters: parameters)
    self.decodeResponse = decode
  }
  /// Decodes response bytes using the request’s bound response schema; malformed data throws.
  public func decode(_ data: Data) throws -> Response { try decodeResponse(data) }
}

/// Builds a sendable JSON decoder for the specified response type.
private func decoded<T: Decodable & Sendable>(_ type: T.Type) -> @Sendable (Data) throws -> T {
  { try JSONDecoder().decode(T.self, from: $0) }
}

extension PerpsQuery where Response == [PerpsDex?] {
  /// Lists validator and HIP-3 DEX registry entries, preserving null registry slots.
  public static func dexs() -> Self {
    .init(type: "perpDexs", parameters: [:], decode: decoded([PerpsDex?].self))
  }
}

extension PerpsQuery where Response == PerpsMeta {
  /// Requests market precision, leverage limits, margin tables, and collateral metadata for a DEX.
  public static func meta(dex: String = "") -> Self {
    .init(type: "meta", parameters: ["dex": .string(dex)], decode: decoded(PerpsMeta.self))
  }
}

extension PerpsQuery where Response == PerpsMetaAndContexts {
  /// Requests DEX metadata together with asset contexts in matching universe order.
  public static func metaAndContexts(dex: String = "") -> Self {
    .init(
      type: "metaAndAssetCtxs", parameters: ["dex": .string(dex)],
      decode: decoded(PerpsMetaAndContexts.self))
  }
}

extension PerpsQuery where Response == [PerpsAllMetaEntry] {
  /// Requests metadata for all Perps DEXs.
  public static func allMetas() -> Self {
    .init(type: "allPerpMetas", parameters: [:], decode: decoded([PerpsAllMetaEntry].self))
  }
}

extension PerpsQuery where Response == PerpsAccountState {
  /// Requests positions and margin summaries for an address on the selected DEX.
  public static func account(address: String, dex: String = "") -> Self {
    .init(
      type: "clearinghouseState", parameters: ["user": .string(address), "dex": .string(dex)],
      decode: decoded(PerpsAccountState.self))
  }
}

extension PerpsQuery where Response == PerpsSpotState {
  /// Requests Spot token totals, held funds, and any server-provided maintenance availability.
  public static func spotState(address: String) -> Self {
    .init(
      type: "spotClearinghouseState", parameters: ["user": .string(address)],
      decode: decoded(PerpsSpotState.self))
  }
}

extension PerpsQuery where Response == PerpsActiveAssetData {
  /// Requests coin-specific leverage, available trade amounts, and maximum order sizes.
  public static func activeAsset(address: String, coin: String) -> Self {
    .init(
      type: "activeAssetData", parameters: ["user": .string(address), "coin": .string(coin)],
      decode: decoded(PerpsActiveAssetData.self))
  }
}

extension PerpsQuery where Response == AccountAbstraction {
  /// Requests the account mode used to interpret separate or shared collateral.
  public static func abstraction(address: String) -> Self {
    .init(
      type: "userAbstraction", parameters: ["user": .string(address)],
      decode: decoded(AccountAbstraction.self))
  }
}

extension PerpsQuery where Response == Bool? {
  /// Requests the legacy DEX abstraction flag, preserving an absent value.
  public static func legacyDexAbstraction(address: String) -> Self {
    .init(
      type: "userDexAbstraction", parameters: ["user": .string(address)],
      decode: decoded(Bool?.self))
  }
}

extension PerpsQuery where Response == [PerpsFunding] {
  /// Requests historical funding rates for a coin within timestamp pagination bounds.
  public static func fundingHistory(coin: String, page: HyperliquidPageRequest) -> Self {
    .init(
      type: "fundingHistory",
      parameters: page.parameters.merging(["coin": .string(coin)]) { _, new in new },
      decode: decoded([PerpsFunding].self))
  }
}

extension PerpsQuery where Response == [PerpsPredictedFundingEntry] {
  /// Requests predicted funding rates and settlement times across venues.
  public static func predictedFunding() -> Self {
    .init(
      type: "predictedFundings", parameters: [:], decode: decoded([PerpsPredictedFundingEntry].self)
    )
  }
}

extension PerpsQuery where Response == [String] {
  /// Lists markets currently at their open-interest cap on the selected DEX.
  public static func openInterestCaps(dex: String = "") -> Self {
    .init(
      type: "perpsAtOpenInterestCap", parameters: ["dex": .string(dex)],
      decode: decoded([String].self))
  }
}

extension PerpsQuery where Response == PerpsDeployAuction {
  /// Requests the current Perps deployment auction status.
  public static func deployAuction() -> Self {
    .init(
      type: "perpDeployAuctionStatus", parameters: [:], decode: decoded(PerpsDeployAuction.self))
  }
}

extension PerpsQuery where Response == PerpsDexLimits {
  /// Requests deployment and trading limits for a HIP-3 DEX.
  public static func dexLimits(dex: String) -> Self {
    .init(
      type: "perpDexLimits", parameters: ["dex": .string(dex)], decode: decoded(PerpsDexLimits.self)
    )
  }
}

extension PerpsQuery where Response == PerpsDexStatus {
  /// Requests the selected DEX status and available deployment settings.
  public static func dexStatus(dex: String = "") -> Self {
    .init(
      type: "perpDexStatus", parameters: ["dex": .string(dex)], decode: decoded(PerpsDexStatus.self)
    )
  }
}

extension PerpsQuery where Response == PerpsAnnotation? {
  /// Requests descriptive annotations for a coin.
  public static func annotation(coin: String) -> Self {
    .init(
      type: "perpAnnotation", parameters: ["coin": .string(coin)],
      decode: decoded(PerpsAnnotation?.self))
  }
}

extension PerpsQuery where Response == [PerpsCategory] {
  /// Requests the available Perps market categories.
  public static func categories() -> Self {
    .init(type: "perpCategories", parameters: [:], decode: decoded([PerpsCategory].self))
  }
}

extension PerpsQuery where Response == [PerpsConciseAnnotation] {
  /// Requests the compact market annotation listing.
  public static func conciseAnnotations() -> Self {
    .init(
      type: "perpConciseAnnotations", parameters: [:],
      decode: decoded([PerpsConciseAnnotation].self))
  }
}

extension PerpsQuery where Response == [PerpsOrder] {
  /// Requests resting orders for an address on the selected DEX.
  public static func openOrders(address: String, dex: String = "") -> Self {
    .init(
      type: "openOrders", parameters: ["user": .string(address), "dex": .string(dex)],
      decode: decoded([PerpsOrder].self))
  }
}

extension PerpsQuery where Response == [PerpsOrder] {
  /// Requests open orders with frontend trigger and grouping details.
  public static func frontendOpenOrders(address: String, dex: String = "") -> Self {
    .init(
      type: "frontendOpenOrders", parameters: ["user": .string(address), "dex": .string(dex)],
      decode: decoded([PerpsOrder].self))
  }
}

extension PerpsQuery where Response == [PerpsHistoricalOrder] {
  /// Requests the account’s recent historical orders and statuses.
  public static func historicalOrders(address: String) -> Self {
    .init(
      type: "historicalOrders", parameters: ["user": .string(address)],
      decode: decoded([PerpsHistoricalOrder].self))
  }
}

extension PerpsQuery where Response == [PerpsFill] {
  /// Requests recent account fills, optionally aggregating fills by time.
  public static func fills(address: String, aggregateByTime: Bool = false) -> Self {
    .init(
      type: "userFills",
      parameters: ["user": .string(address), "aggregateByTime": .bool(aggregateByTime)],
      decode: decoded([PerpsFill].self))
  }
}

extension PerpsQuery where Response == [PerpsFill] {
  /// Requests account fills within timestamp pagination bounds.
  public static func fillsByTime(
    address: String, page: HyperliquidPageRequest, aggregateByTime: Bool = false
  ) -> Self {
    .init(
      type: "userFillsByTime",
      parameters: page.parameters.merging([
        "user": .string(address), "aggregateByTime": .bool(aggregateByTime),
      ]) { _, new in new }, decode: decoded([PerpsFill].self))
  }
}

extension PerpsQuery where Response == HyperliquidUserRateLimit {
  /// Requests the account’s request-weight usage and capacity.
  public static func rateLimit(address: String) -> Self {
    .init(
      type: "userRateLimit", parameters: ["user": .string(address)],
      decode: { try HyperliquidUserRateLimit.decode($0) })
  }
}

extension PerpsQuery where Response == PerpsUserFees {
  /// Requests the account’s fee schedule, volume, and discount information.
  public static func fees(address: String) -> Self {
    .init(
      type: "userFees", parameters: ["user": .string(address)], decode: decoded(PerpsUserFees.self))
  }
}

extension PerpsQuery where Response == [PerpsTwapSliceFill] {
  /// Requests fills produced by the account’s TWAP slices.
  public static func twapSliceFills(address: String) -> Self {
    .init(
      type: "userTwapSliceFills", parameters: ["user": .string(address)],
      decode: decoded([PerpsTwapSliceFill].self))
  }
}

extension PerpsQuery where Response == PerpsUserRole {
  /// Requests the address role, including agent or multisig configuration.
  public static func role(address: String) -> Self {
    .init(
      type: "userRole", parameters: ["user": .string(address)], decode: decoded(PerpsUserRole.self))
  }
}

extension PerpsQuery where Response == [PerpsSubAccount]? {
  /// Requests the user’s subaccounts and their account states.
  public static func subAccounts(address: String) -> Self {
    .init(
      type: "subAccounts", parameters: ["user": .string(address)],
      decode: decoded([PerpsSubAccount]?.self))
  }
}

extension PerpsQuery where Response == [PerpsApprovedAgent] {
  /// Requests the user’s approved trading agents.
  public static func agents(address: String) -> Self {
    .init(
      type: "extraAgents", parameters: ["user": .string(address)],
      decode: decoded([PerpsApprovedAgent].self))
  }
}

extension PerpsQuery where Response == [String] {
  /// Requests builders approved by the user and their fee limits.
  public static func approvedBuilders(address: String) -> Self {
    .init(
      type: "approvedBuilders", parameters: ["user": .string(address)],
      decode: decoded([String].self))
  }
}

extension PerpsQuery where Response == HyperliquidOrderStatus {
  /// Looks up an account order by its exchange ID or hexadecimal client order ID.
  public static func orderStatus(address: String, orderID: Int64) -> Self {
    .init(
      type: "orderStatus",
      parameters: ["user": .string(address), "oid": .protocolInteger(orderID)],
      decode: { try HyperliquidOrderStatus.decode($0) })
  }
}

extension PerpsQuery where Response == HyperliquidOrderStatus {
  /// Looks up an account order by its exchange ID or hexadecimal client order ID.
  public static func orderStatus(address: String, cloid: String) -> Self {
    .init(
      type: "orderStatus", parameters: ["user": .string(address), "oid": .string(cloid)],
      decode: { try HyperliquidOrderStatus.decode($0) })
  }
}

extension PerpsQuery where Response == [String: Decimal] {
  /// Requests market midpoint prices for the selected DEX.
  public static func mids(dex: String = "") -> Self {
    .init(
      type: "allMids", parameters: ["dex": .string(dex)],
      decode: {
        try JSONDecoder().decode([String: String].self, from: $0).mapValues(perpsDecimal)
      })
  }
}

extension PerpsQuery where Response == [PerpsLedgerEntry] {
  /// Requests non-funding ledger updates within timestamp pagination bounds.
  public static func ledger(address: String, page: HyperliquidPageRequest) -> Self {
    .init(
      type: "userNonFundingLedgerUpdates",
      parameters: page.parameters.merging(["user": .string(address)]) { _, new in new },
      decode: decoded([PerpsLedgerEntry].self))
  }
}

extension PerpsQuery where Response == [PerpsFundingEntry] {
  /// Requests account funding payments within timestamp pagination bounds.
  public static func userFunding(address: String, page: HyperliquidPageRequest) -> Self {
    .init(
      type: "userFunding",
      parameters: page.parameters.merging(["user": .string(address)]) { _, new in new },
      decode: decoded([PerpsFundingEntry].self))
  }
}

extension PerpsQuery where Response == [PerpsPortfolioPeriod] {
  /// Requests the account’s portfolio history and performance summaries.
  public static func portfolio(address: String) -> Self {
    .init(
      type: "portfolio", parameters: ["user": .string(address)],
      decode: decoded([PerpsPortfolioPeriod].self))
  }
}

extension PerpsQuery where Response == PerpsBorrowLendUser {
  /// Requests the account’s borrow/lend balances and state.
  public static func borrowLendUser(address: String) -> Self {
    .init(
      type: "borrowLendUserState", parameters: ["user": .string(address)],
      decode: decoded(PerpsBorrowLendUser.self))
  }
}

extension PerpsQuery where Response == Int {
  /// Requests the maximum fee approved by a user for a builder.
  public static func builderFee(address: String, builder: String) -> Self {
    .init(
      type: "maxBuilderFee", parameters: ["user": .string(address), "builder": .string(builder)],
      decode: decoded(Int.self))
  }
}

extension PerpsQuery where Response == PerpsBook {
  /// Requests the coin’s order book with optional price-level aggregation.
  public static func book(coin: String, nSigFigs: Int? = nil, mantissa: Int? = nil) -> Self {
    var parameters: [String: JSONValue] = ["coin": .string(coin)]
    if let nSigFigs { parameters["nSigFigs"] = .number(Double(nSigFigs)) }
    if let mantissa { parameters["mantissa"] = .number(Double(mantissa)) }
    return .init(type: "l2Book", parameters: parameters, decode: decoded(PerpsBook.self))
  }
}
extension PerpsQuery where Response == [PerpsCandle] {
  /// Requests OHLCV candles for a coin, interval, and timestamp range.
  public static func candles(
    coin: String, interval: PerpsCandleInterval, page: HyperliquidPageRequest
  ) -> Self {
    let parameters = page.parameters.merging([
      "coin": .string(coin), "interval": .string(interval.rawValue),
    ]) { _, new in new }
    return .init(
      type: "candleSnapshot", parameters: ["req": .object(parameters)],
      decode: decoded([PerpsCandle].self))
  }
}

extension PerpsQuery where Response == PerpsSpotMeta {
  /// Requests Spot token metadata used to resolve transfer tokens and precision.
  public static func spotMeta() -> Self {
    .init(type: "spotMeta", decode: decoded(PerpsSpotMeta.self))
  }
}
extension PerpsQuery where Response == PerpsBorrowReserve {
  /// Requests borrow/lend reserve data for a token index.
  public static func borrowReserve(token: Int) -> Self {
    .init(
      type: "borrowLendReserveState", parameters: ["token": .number(Double(token))],
      decode: decoded(PerpsBorrowReserve.self))
  }
}
extension PerpsQuery where Response == [PerpsTokenReserve] {
  /// Requests all borrow/lend reserve entries.
  public static func borrowReserves() -> Self {
    .init(type: "allBorrowLendReserveStates", decode: decoded([PerpsTokenReserve].self))
  }
}

extension PerpsQuery where Response == PerpsVaultDetails? {
  /// Requests vault details, optionally including a user’s participation; absent vaults return nil.
  public static func vaultDetails(address: String, user: String? = nil) -> Self {
    var parameters: [String: JSONValue] = ["vaultAddress": .string(address)]
    if let user { parameters["user"] = .string(user) }
    return .init(
      type: "vaultDetails", parameters: parameters, decode: decoded(PerpsVaultDetails?.self))
  }
}
extension PerpsQuery where Response == [PerpsVaultEquity] {
  /// Requests the user’s vault equity entries.
  public static func vaultEquities(address: String) -> Self {
    .init(
      type: "userVaultEquities", parameters: ["user": .string(address)],
      decode: decoded([PerpsVaultEquity].self))
  }
}
extension PerpsQuery where Response == PerpsReferral {
  /// Requests referral configuration and account referral statistics.
  public static func referral(address: String) -> Self {
    .init(
      type: "referral", parameters: ["user": .string(address)], decode: decoded(PerpsReferral.self))
  }
}
