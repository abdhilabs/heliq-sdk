//
//  HyperliquidParity.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a set of supported values for j s o n value.
public enum JSONValue: Sendable, Codable, Equatable, Hashable {
  /// The `string` case.
  case string(String)
  /// The `number` case.
  case number(Double)
  /// The `bool` case.
  case bool(Bool)
  /// The `object` case.
  case object([String: JSONValue])
  /// The `array` case.
  case array([JSONValue])
  /// The `null` case.
  case null

  /// Creates an instance with the supplied values.
  public init(from decoder: Decoder) throws {
    let c = try decoder.singleValueContainer()
    if c.decodeNil() { self = .null }
    else if let v = try? c.decode(Bool.self) { self = .bool(v) }
    else if let v = try? c.decode(Double.self) { self = .number(v) }
    else if let v = try? c.decode(String.self) { self = .string(v) }
    else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
    else if let v = try? c.decode([JSONValue].self) { self = .array(v) }
    else { throw DecodingError.typeMismatch(JSONValue.self, .init(codingPath: decoder.codingPath, debugDescription: "Unsupported JSON value")) }
  }

  /// Encodes this value into the supplied encoder.
  public func encode(to encoder: Encoder) throws {
    var c = encoder.singleValueContainer()
    switch self {
    case .string(let v): try c.encode(v)
    case .number(let v): try c.encode(v)
    case .bool(let v): try c.encode(v)
    case .object(let v): try c.encode(v)
    case .array(let v): try c.encode(v)
    case .null: try c.encodeNil()
    }
  }
}

/// All current documented `POST /info` types. `custom` supports newly released
/// types without a blocking SDK release.
public enum HyperliquidInfoType: Sendable, Hashable, Codable {
  /// The `allMids` case.
  case allMids
  /// The `openOrders` case.
  case openOrders
  /// The `frontendOpenOrders` case.
  case frontendOpenOrders
  /// The `userFills` case.
  case userFills
  /// The `userFillsByTime` case.
  case userFillsByTime
  /// The `userRateLimit` case.
  case userRateLimit
  /// The `orderStatus` case.
  case orderStatus
  /// The `l2Book` case.
  case l2Book
  /// The `candleSnapshot` case.
  case candleSnapshot
  /// The `maxBuilderFee` case.
  case maxBuilderFee
  /// The `historicalOrders` case.
  case historicalOrders
  /// The `userTwapSliceFills` case.
  case userTwapSliceFills
  /// The `subAccounts` case.
  case subAccounts
  /// The `userStakingSummary` case.
  case userStakingSummary
  /// The `userStakingHistory` case.
  case userStakingHistory
  /// The `userStakingRewards` case.
  case userStakingRewards
  /// The `delegatorSummary` case.
  case delegatorSummary
  /// The `delegations` case.
  case delegations
  /// The `delegatorHistory` case.
  case delegatorHistory
  /// The `delegatorRewards` case.
  case delegatorRewards
  /// The `userRole` case.
  case userRole
  /// The `portfolio` case.
  case portfolio
  /// The `userFees` case.
  case userFees
  /// The `referral` case.
  case referral
  /// The `userState` case.
  case userState
  /// The `spotUserState` case.
  case spotUserState
  /// The `clearinghouseState` case.
  case clearinghouseState
  /// The `meta` case.
  case meta
  /// The `metaAndAssetCtxs` case.
  case metaAndAssetCtxs
  /// The `spotMeta` case.
  case spotMeta
  /// The `spotMetaAndAssetCtxs` case.
  case spotMetaAndAssetCtxs
  /// The `assetCtxs` case.
  case assetCtxs
  /// The `spotAssetCtxs` case.
  case spotAssetCtxs
  /// The `predictedFundings` case.
  case predictedFundings
  /// The `perpsAtOpenInterestCap` case.
  case perpsAtOpenInterestCap
  /// The `vaultDetails` case.
  case vaultDetails
  /// The `userVaultEquities` case.
  case userVaultEquities
  /// The `userNonFundingLedgerUpdates` case.
  case userNonFundingLedgerUpdates
  /// The `queryOrderByOid` case.
  case queryOrderByOid
  /// The `queryOrderByCloid` case.
  case queryOrderByCloid
  /// The `queryFills` case.
  case queryFills
  /// The `queryUserFundings` case.
  case queryUserFundings
  /// The `getTime` case.
  case getTime
  /// The `fetchBuilderFee` case.
  case fetchBuilderFee
  /// The `maxBuilderFeeApproval` case.
  case maxBuilderFeeApproval
  /// The `approvedBuilders` case.
  case approvedBuilders
  /// The `borrowLendUserState` case.
  case borrowLendUserState
  /// The `borrowLendReserveState` case.
  case borrowLendReserveState
  /// The `allBorrowLendReserveStates` case.
  case allBorrowLendReserveStates
  /// The `webData2` case.
  case webData2
  /// The `perpDexs` case.
  case perpDexs
  /// The `userDexAbstraction` case.
  case userDexAbstraction
  /// The `userAbstraction` case.
  case userAbstraction
  /// The `userFunding` case.
  case userFunding
  /// The `fundingHistory` case.
  case fundingHistory
  /// The `perpDeployAuctionStatus` case.
  case perpDeployAuctionStatus
  /// The `activeAssetData` case.
  case activeAssetData
  /// The `perpDexLimits` case.
  case perpDexLimits
  /// The `perpDexStatus` case.
  case perpDexStatus
  /// The `allPerpMetas` case.
  case allPerpMetas
  /// The `perpAnnotation` case.
  case perpAnnotation
  /// The `perpCategories` case.
  case perpCategories
  /// The `perpConciseAnnotations` case.
  case perpConciseAnnotations
  /// The `spotClearinghouseState` case.
  case spotClearinghouseState
  /// The `spotDeployState` case.
  case spotDeployState
  /// The `spotPairDeployAuctionStatus` case.
  case spotPairDeployAuctionStatus
  /// The `tokenDetails` case.
  case tokenDetails
  /// The `outcomeMeta` case.
  case outcomeMeta
  /// The `settledOutcome` case.
  case settledOutcome
  /// The `custom` case.
  case custom(String)

  /// The raw value value.
  public var rawValue: String {
    switch self {
    case .custom(let v): return v
    default: return String(describing: self)
    }
  }
}

/// Represents a value for hyperliquid info request.
public struct HyperliquidInfoRequest: Sendable, Codable {
  /// The type associated with this value.
  public let type: HyperliquidInfoType
  /// The parameters associated with this value.
  public let parameters: [String: JSONValue]
  /// Creates an instance with the supplied values.
  public init(type: HyperliquidInfoType, parameters: [String: JSONValue] = [:]) { self.type = type; self.parameters = parameters }
  /// Returns the request body for this value.
  public func body() -> [String: JSONValue] { parameters.merging(["type": .string(type.rawValue)]) { _, new in new } }
  /// Encodes the request body as JSON data.
  public func data() throws -> Data { try JSONEncoder().encode(body()) }

  /// Performs the user rate limit operation.
  public static func userRateLimit(user: String) -> Self {
    Self(type: .userRateLimit, parameters: ["user": .string(user)])
  }

  /// Performs the all mids operation.
  public static func allMids(dex: String? = nil) -> Self {
    var parameters: [String: JSONValue] = [:]
    if let dex { parameters["dex"] = .string(dex) }
    return Self(type: .allMids, parameters: parameters)
  }

  /// Performs the user fills operation.
  public static func userFills(user: String, aggregateByTime: Bool? = nil) -> Self {
    var parameters: [String: JSONValue] = ["user": .string(user)]
    if let aggregateByTime { parameters["aggregateByTime"] = .bool(aggregateByTime) }
    return Self(type: .userFills, parameters: parameters)
  }

  /// Performs the l2 book operation.
  public static func l2Book(coin: String, nSigFigs: Int? = nil, mantissa: Int? = nil) -> Self {
    var parameters: [String: JSONValue] = ["coin": .string(coin)]
    if let nSigFigs { parameters["nSigFigs"] = .number(Double(nSigFigs)) }
    if let mantissa { parameters["mantissa"] = .number(Double(mantissa)) }
    return Self(type: .l2Book, parameters: parameters)
  }

  /// Performs the frontend open orders operation.
  public static func frontendOpenOrders(user: String, dex: String? = nil) -> Self {
    var parameters: [String: JSONValue] = ["user": .string(user)]
    if let dex { parameters["dex"] = .string(dex) }
    return Self(type: .frontendOpenOrders, parameters: parameters)
  }

  /// Performs the open orders operation.
  public static func openOrders(user: String, dex: String? = nil) -> Self {
    var parameters: [String: JSONValue] = ["user": .string(user)]
    if let dex { parameters["dex"] = .string(dex) }
    return Self(type: .openOrders, parameters: parameters)
  }

  /// Performs the order status operation.
  public static func orderStatus(user: String, oid: Int64) -> Self {
    Self(type: .orderStatus, parameters: ["user": .string(user), "oid": .number(Double(oid))])
  }

  /// Performs the order status operation.
  public static func orderStatus(user: String, cloid: String) -> Self {
    Self(type: .orderStatus, parameters: ["user": .string(user), "oid": .string(cloid)])
  }

  /// Performs the user fills by time operation.
  public static func userFillsByTime(user: String, startTime: Date, endTime: Date? = nil) -> Self {
    var parameters: [String: JSONValue] = [
      "user": .string(user),
      "startTime": .number(Double(startTime.timeIntervalSince1970 * 1_000))
    ]
    if let endTime { parameters["endTime"] = .number(Double(endTime.timeIntervalSince1970 * 1_000)) }
    return Self(type: .custom("userFillsByTime"), parameters: parameters)
  }

  /// Performs the candle snapshot operation.
  public static func candleSnapshot(coin: String, interval: String, startTime: Date, endTime: Date) -> Self {
    Self(type: .custom("candleSnapshot"), parameters: [
      "req": .object([
        "coin": .string(coin),
        "interval": .string(interval),
        "startTime": .number(Double(startTime.timeIntervalSince1970 * 1_000)),
        "endTime": .number(Double(endTime.timeIntervalSince1970 * 1_000))
      ])
    ])
  }
}

/// All signed `/exchange` action types currently documented by Hyperliquid.
public enum HyperliquidExchangeActionType: Sendable, Hashable, Codable {
  /// The `order` case.
  case order
  /// The `cancel` case.
  case cancel
  /// The `cancelByCloid` case.
  case cancelByCloid
  /// The `scheduleCancel` case.
  case scheduleCancel
  /// The `modify` case.
  case modify
  /// The `batchModify` case.
  case batchModify
  /// The `updateLeverage` case.
  case updateLeverage
  /// The `updateIsolatedMargin` case.
  case updateIsolatedMargin
  /// The `agentSetAbstraction` case.
  case agentSetAbstraction
  /// The `userOutcome` case.
  case userOutcome
  /// The `validatorL1Stream` case.
  case validatorL1Stream
  /// The `authorizeAqav2Role` case.
  case authorizeAqav2Role
  /// The `claimRewards` case.
  case claimRewards
  /// The `usdSend` case.
  case usdSend
  /// The `withdraw3` case.
  case withdraw3
  /// The `spotSend` case.
  case spotSend
  /// The `usdClassTransfer` case.
  case usdClassTransfer
  /// The `vaultTransfer` case.
  case vaultTransfer
  /// The `createSubAccount` case.
  case createSubAccount
  /// The `subAccountTransfer` case.
  case subAccountTransfer
  /// The `approveAgent` case.
  case approveAgent
  /// The `approveBuilderFee` case.
  case approveBuilderFee
  /// The `updateBuilderFee` case.
  case updateBuilderFee
  /// The `tokenDelegate` case.
  case tokenDelegate
  /// The `cDeposit` case.
  case cDeposit
  /// The `cWithdraw` case.
  case cWithdraw
  /// The `twapOrder` case.
  case twapOrder
  /// The `twapCancel` case.
  case twapCancel
  /// The `setReferrer` case.
  case setReferrer
  /// The `convertToMultiSig` case.
  case convertToMultiSig
  /// The `multiSig` case.
  case multiSig
  /// The `reserveRequestWeight` case.
  case reserveRequestWeight
  /// The `noop` case.
  case noop
  /// The `custom` case.
  case custom(String)
  /// The raw value value.
  public var rawValue: String { if case .custom(let v) = self { return v }; return String(describing: self) }
}

/// Represents a value for hyperliquid exchange action.
public struct HyperliquidExchangeAction: Sendable, Codable {
  /// The type associated with this value.
  public let type: HyperliquidExchangeActionType
  /// The parameters associated with this value.
  public let parameters: [String: JSONValue]
  /// Creates an instance with the supplied values.
  public init(type: HyperliquidExchangeActionType, parameters: [String: JSONValue] = [:]) { self.type = type; self.parameters = parameters }
  /// Returns the request body for this value.
  public func body() -> [String: JSONValue] { parameters.merging(["type": .string(type.rawValue)]) { _, new in new } }
}

/// A signed envelope for `/exchange`. Signatures are externally generated until
/// the SDK's native EIP-712 signing implementation is completed.
public struct HyperliquidExchangeEnvelope: Sendable, Codable {
  /// The action associated with this value.
  public let action: HyperliquidExchangeAction
  /// The nonce associated with this value.
  public let nonce: Int64
  /// The signature associated with this value.
  public let signature: SignatureTypes
  /// The vault address associated with this value.
  public let vaultAddress: String?
  /// The expires after associated with this value.
  public let expiresAfter: Int64?
  /// Creates an instance with the supplied values.
  public init(action: HyperliquidExchangeAction, nonce: Int64, signature: SignatureTypes, vaultAddress: String? = nil, expiresAfter: Int64? = nil) { self.action = action; self.nonce = nonce; self.signature = signature; self.vaultAddress = vaultAddress; self.expiresAfter = expiresAfter }
  /// Returns the request body for this value.
  public func body() -> [String: JSONValue] {
    var result: [String: JSONValue] = ["action": .object(action.body()), "nonce": .number(Double(nonce)), "signature": .object(["r": .string(signature.r), "s": .string(signature.s), "v": .number(Double(signature.v))])]
    if let vaultAddress { result["vaultAddress"] = .string(vaultAddress) }
    if let expiresAfter { result["expiresAfter"] = .number(Double(expiresAfter)) }
    return result
  }
}

/// Represents a value for hyperliquid raw request.
public struct HyperliquidRawRequest: APIRouterProtocol, Sendable {
  /// The path associated with this value.
  public let path: String
  /// The method associated with this value.
  public let method: HTTPMethod = .post
  private let encodedBody: Data?
  /// The body value.
  public var body: Data? { encodedBody }
  /// Creates an instance with the supplied values.
  public init(path: String, body: [String: JSONValue]) throws { self.path = path; encodedBody = try JSONEncoder().encode(body) }
}

/// Lossless full-surface transport for Hyperliquid Info and Exchange APIs.
public final class HyperliquidAPI: @unchecked Sendable {
  private let apiClient: APIClient
  /// Creates an instance with the supplied values.
  public init(apiClient: APIClient) { self.apiClient = apiClient }
  /// Sends an information request.
  public func info(_ request: HyperliquidInfoRequest) async throws -> JSONValue { try await apiClient.request(HyperliquidRawRequest(path: "/info", body: request.body())) }
  /// Performs the user rate limit operation.
  public func userRateLimit(user: String) async throws -> HyperliquidUserRateLimit {
    let response = try await info(.userRateLimit(user: user))
    return try HyperliquidUserRateLimit.decode(JSONEncoder().encode(response))
  }

  /// Performs the all mids operation.
  public func allMids(dex: String? = nil) async throws -> [String: String] {
    let response = try await info(.allMids(dex: dex))
    return try JSONDecoder().decode([String: String].self, from: JSONEncoder().encode(response))
  }

  /// Performs the meta and asset ctxs operation.
  public func metaAndAssetCtxs() async throws -> HyperliquidMetaAndAssetCtxs {
    let response = try await info(.init(type: .metaAndAssetCtxs))
    return try HyperliquidMetaAndAssetCtxs.decode(JSONEncoder().encode(response))
  }

  /// Performs the order status operation.
  public func orderStatus(user: String, oid: Int64) async throws -> HyperliquidOrderStatus {
    try await decodeOrderStatus(.orderStatus(user: user, oid: oid))
  }

  /// Performs the order status operation.
  public func orderStatus(user: String, cloid: String) async throws -> HyperliquidOrderStatus {
    try await decodeOrderStatus(.orderStatus(user: user, cloid: cloid))
  }

  private func decodeOrderStatus(_ request: HyperliquidInfoRequest) async throws -> HyperliquidOrderStatus {
    let response = try await info(request)
    return try HyperliquidOrderStatus.decode(JSONEncoder().encode(response))
  }

  /// Performs the user fills by time operation.
  public func userFillsByTime(user: String, page: HyperliquidPageRequest) async throws -> [HyperliquidUserFill] {
    let response = try await info(.userFillsByTime(user: user, startTime: page.startTime, endTime: page.endTime))
    return try HyperliquidUserFill.decodeList(JSONEncoder().encode(response))
  }
  /// Performs the user fills operation.
  public func userFills(user: String, aggregateByTime: Bool? = nil) async throws -> [HyperliquidUserFill] {
    let response = try await info(.userFills(user: user, aggregateByTime: aggregateByTime))
    return try HyperliquidUserFill.decodeList(JSONEncoder().encode(response))
  }
  /// Performs the l2 book operation.
  public func l2Book(coin: String, nSigFigs: Int? = nil, mantissa: Int? = nil) async throws -> HyperliquidL2BookSnapshot {
    let response = try await info(.l2Book(coin: coin, nSigFigs: nSigFigs, mantissa: mantissa))
    return try HyperliquidL2BookSnapshot.decode(JSONEncoder().encode(response))
  }
  /// Performs the frontend open orders operation.
  public func frontendOpenOrders(user: String, dex: String? = nil) async throws -> [HyperliquidFrontendOpenOrder] {
    let response = try await info(.frontendOpenOrders(user: user, dex: dex))
    return try HyperliquidFrontendOpenOrder.decodeList(JSONEncoder().encode(response))
  }

  /// Performs the open orders operation.
  public func openOrders(user: String, dex: String? = nil) async throws -> [HyperliquidOpenOrder] {
    let response = try await info(.openOrders(user: user, dex: dex))
    return try HyperliquidOpenOrder.decodeList(JSONEncoder().encode(response))
  }
  /// Sends an exchange request.
  public func exchange(_ envelope: HyperliquidExchangeEnvelope) async throws -> JSONValue { try await apiClient.request(HyperliquidRawRequest(path: "/exchange", body: envelope.body())) }
}

/// Official WebSocket HTTP-equivalent post request. Hyperliquid accepts both
/// Info payloads and signed Exchange envelopes over the `post` method.
public enum HyperliquidWebSocketPostRequest: Sendable {
  /// Sends an Info request over the WebSocket `post` method.
  case info(id: Int, request: HyperliquidInfoRequest)
  /// Sends a signed Exchange envelope over the WebSocket `post` method.
  case action(id: Int, envelope: HyperliquidExchangeEnvelope)

  /// Returns this request as a WebSocket-compatible object.
  public func object() throws -> [String: Any] {
    switch self {
    case .info(let id, let request):
      return [
        "method": "post", "id": id,
        "request": ["type": "info", "payload": try foundationObject(request.body())]
      ]
    case .action(let id, let envelope):
      return [
        "method": "post", "id": id,
        "request": ["type": "action", "payload": try foundationObject(envelope.body())]
      ]
    }
  }

  private func foundationObject(_ body: [String: JSONValue]) throws -> [String: Any] {
    let data = try JSONEncoder().encode(body)
    guard let result = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw ValidationError.malformedData(reason: "Unable to encode WebSocket post payload")
    }
    return result
  }
}
