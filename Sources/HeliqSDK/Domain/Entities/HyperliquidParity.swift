//
//  HyperliquidParity.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum JSONValue: Sendable, Codable, Equatable, Hashable {
  case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null

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
  case allMids, openOrders, frontendOpenOrders, userFills, userFillsByTime, userRateLimit, orderStatus, l2Book, candleSnapshot, maxBuilderFee, historicalOrders, userTwapSliceFills, subAccounts, userStakingSummary, userStakingHistory, userStakingRewards, delegatorSummary, delegations, delegatorHistory, delegatorRewards, userRole, portfolio, userFees, referral, userState, spotUserState, clearinghouseState, meta, metaAndAssetCtxs, spotMeta, spotMetaAndAssetCtxs, assetCtxs, spotAssetCtxs, predictedFundings, perpsAtOpenInterestCap, vaultDetails, userVaultEquities, userNonFundingLedgerUpdates, queryOrderByOid, queryOrderByCloid, queryFills, queryUserFundings, getTime, fetchBuilderFee, maxBuilderFeeApproval, approvedBuilders, borrowLendUserState, borrowLendReserveState, allBorrowLendReserveStates, webData2, perpDexs, userDexAbstraction, userAbstraction, userFunding, fundingHistory, perpDeployAuctionStatus, activeAssetData, perpDexLimits, perpDexStatus, allPerpMetas, perpAnnotation, perpCategories, perpConciseAnnotations, spotClearinghouseState, spotDeployState, spotPairDeployAuctionStatus, tokenDetails, outcomeMeta, settledOutcome, custom(String)

  public var rawValue: String {
    switch self {
    case .custom(let v): return v
    default: return String(describing: self)
    }
  }
}

public struct HyperliquidInfoRequest: Sendable, Codable {
  public let type: HyperliquidInfoType
  public let parameters: [String: JSONValue]
  public init(type: HyperliquidInfoType, parameters: [String: JSONValue] = [:]) { self.type = type; self.parameters = parameters }
  public func body() -> [String: JSONValue] { parameters.merging(["type": .string(type.rawValue)]) { _, new in new } }
}

/// All signed `/exchange` action types currently documented by Hyperliquid.
public enum HyperliquidExchangeActionType: Sendable, Hashable, Codable {
  case order, cancel, cancelByCloid, scheduleCancel, modify, batchModify, updateLeverage, updateIsolatedMargin, agentSetAbstraction, userOutcome, validatorL1Stream, authorizeAqav2Role, claimRewards, usdSend, withdraw3, spotSend, usdClassTransfer, vaultTransfer, createSubAccount, subAccountTransfer, approveAgent, approveBuilderFee, updateBuilderFee, tokenDelegate, cDeposit, cWithdraw, twapOrder, twapCancel, setReferrer, convertToMultiSig, multiSig, reserveRequestWeight, noop, custom(String)
  public var rawValue: String { if case .custom(let v) = self { return v }; return String(describing: self) }
}

public struct HyperliquidExchangeAction: Sendable, Codable {
  public let type: HyperliquidExchangeActionType
  public let parameters: [String: JSONValue]
  public init(type: HyperliquidExchangeActionType, parameters: [String: JSONValue] = [:]) { self.type = type; self.parameters = parameters }
  public func body() -> [String: JSONValue] { parameters.merging(["type": .string(type.rawValue)]) { _, new in new } }
}

/// A signed envelope for `/exchange`. Signatures are externally generated until
/// the SDK's native EIP-712 signing implementation is completed.
public struct HyperliquidExchangeEnvelope: Sendable, Codable {
  public let action: HyperliquidExchangeAction
  public let nonce: Int64
  public let signature: SignatureTypes
  public let vaultAddress: String?
  public let expiresAfter: Int64?
  public init(action: HyperliquidExchangeAction, nonce: Int64, signature: SignatureTypes, vaultAddress: String? = nil, expiresAfter: Int64? = nil) { self.action = action; self.nonce = nonce; self.signature = signature; self.vaultAddress = vaultAddress; self.expiresAfter = expiresAfter }
  public func body() -> [String: JSONValue] {
    var result: [String: JSONValue] = ["action": .object(action.body()), "nonce": .number(Double(nonce)), "signature": .object(["r": .string(signature.r), "s": .string(signature.s), "v": .number(Double(signature.v))])]
    if let vaultAddress { result["vaultAddress"] = .string(vaultAddress) }
    if let expiresAfter { result["expiresAfter"] = .number(Double(expiresAfter)) }
    return result
  }
}

public struct HyperliquidRawRequest: APIRouterProtocol, Sendable {
  public let path: String
  public let method: HTTPMethod = .post
  private let encodedBody: Data?
  public var body: Data? { encodedBody }
  public init(path: String, body: [String: JSONValue]) throws { self.path = path; encodedBody = try JSONEncoder().encode(body) }
}

/// Lossless full-surface transport for Hyperliquid Info and Exchange APIs.
public final class HyperliquidAPI: @unchecked Sendable {
  private let apiClient: APIClient
  public init(apiClient: APIClient) { self.apiClient = apiClient }
  public func info(_ request: HyperliquidInfoRequest) async throws -> JSONValue { try await apiClient.request(HyperliquidRawRequest(path: "/info", body: request.body())) }
  public func exchange(_ envelope: HyperliquidExchangeEnvelope) async throws -> JSONValue { try await apiClient.request(HyperliquidRawRequest(path: "/exchange", body: envelope.body())) }
}

/// Official WebSocket HTTP-equivalent post request. Hyperliquid accepts both
/// Info payloads and signed Exchange envelopes over the `post` method.
public enum HyperliquidWebSocketPostRequest: Sendable {
  case info(id: Int, request: HyperliquidInfoRequest)
  case action(id: Int, envelope: HyperliquidExchangeEnvelope)

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
