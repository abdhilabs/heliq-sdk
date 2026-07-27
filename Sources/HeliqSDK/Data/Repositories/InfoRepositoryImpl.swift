//
//  InfoRepositoryImpl.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents info request body data.
public struct InfoRequestBody: Encodable {
  let type: String
  let user: String?
  let coin: String?
  let interval: String?
  let startTime: Int?
  let endTime: Int?
}

/// Defines info endpoint values.
public enum InfoEndpoint: Sendable {
  /// The `userState` option.
  case userState
  /// The `spotUserState` option.
  case spotUserState
  /// The `allMids` option.
  case allMids
  /// The `assetCtxs` option.
  case assetCtxs
  /// The `spotAssetCtxs` option.
  case spotAssetCtxs
  /// The `candleSnapshot` option.
  case candleSnapshot
  /// The `l2Book` option.
  case l2Book
  /// The `queryOrderByOid` option.
  case queryOrderByOid
  /// The `queryOrderByCloid` option.
  case queryOrderByCloid
  /// The `queryFills` option.
  case queryFills
  /// The `queryUserFundings` option.
  case queryUserFundings
  /// The `meta` option.
  case meta
  /// The `spotMeta` option.
  case spotMeta
  /// The `getTime` option.
  case getTime
  /// The `fetchBuilderFee` option.
  case fetchBuilderFee
  
  var path: String { "/info" }
}

/// Represents info apirequest data.
public struct InfoAPIRequest: APIRouterProtocol, Sendable {
  /// The endpoint.
  public let endpoint: InfoEndpoint
  private let _body: Data?
  
  /// The path.
  public var path: String { endpoint.path }
  /// The method.
  public var method: HTTPMethod { .post }
  /// The body.
  public var body: Data? { _body }
  
  /// Creates a info apirequest.
  public init(endpoint: InfoEndpoint, body: Data?) {
    self.endpoint = endpoint
    self._body = body
  }
}

/// Provides info repository impl functionality.
public final class InfoRepositoryImpl: InfoRepository, @unchecked Sendable {
  private let apiClient: APIClient
  
  /// Creates a info repository impl.
  public init(apiClient: APIClient) {
    self.apiClient = apiClient
  }
  
  /// Performs the get user state operation.
  public func getUserState(address: String) async throws -> UserState {
    let body = InfoRequestBody(type: "userState", user: address, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .userState, body: data)
    return try await apiClient.request(request) as UserState
  }
  
  /// Performs the get spot user state operation.
  public func getSpotUserState(address: String) async throws -> SpotUserState {
    let body = InfoRequestBody(type: "spotUserState", user: address, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .spotUserState, body: data)
    return try await apiClient.request(request) as SpotUserState
  }
  
  /// Performs the get all mids operation.
  public func getAllMids() async throws -> AllMids {
    let body = InfoRequestBody(type: "allMids", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .allMids, body: data)
    return try await apiClient.request(request) as AllMids
  }
  
  /// Performs the get asset ctxs operation.
  public func getAssetCtxs() async throws -> [AssetContext] {
    let request = try HyperliquidRawRequest(
      path: "/info",
      body: HyperliquidInfoRequest(type: .metaAndAssetCtxs).body()
    )
    let data = try await apiClient.requestData(request)
    return try HyperliquidMetaAndAssetCtxs.decode(data).sdkAssetContexts
  }
  
  /// Performs the get spot asset ctxs operation.
  public func getSpotAssetCtxs() async throws -> [SpotAssetContext] {
    let request = try HyperliquidRawRequest(
      path: "/info",
      body: HyperliquidInfoRequest(type: .spotMetaAndAssetCtxs).body()
    )
    let data = try await apiClient.requestData(request)
    return try HyperliquidSpotMetaAndAssetCtxs.decode(data).sdkAssetContexts
  }
  
  /// Performs the get candle snapshot operation.
  public func getCandleSnapshot(coin: String, interval: String, startTime: Date, endTime: Date) async throws -> [Candle] {
    let data = try HyperliquidInfoRequest.candleSnapshot(
      coin: coin,
      interval: interval,
      startTime: startTime,
      endTime: endTime
    ).data()
    let request = InfoAPIRequest(endpoint: .candleSnapshot, body: data)
    return try await apiClient.request(request) as [Candle]
  }
  
  /// Performs the get l2 book operation.
  public func getL2Book(coin: String) async throws -> L2Book {
    let request = try HyperliquidRawRequest(
      path: "/info",
      body: HyperliquidInfoRequest.l2Book(coin: coin).body()
    )
    let data = try await apiClient.requestData(request)
    return try L2Book.decodeLiveWire(data)
  }
  
  /// Performs the query order by oid operation.
  public func queryOrderByOid(orderId: String) async throws -> [Order] {
    let body = InfoRequestBody(type: "queryOrderByOid", user: nil, coin: orderId, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .queryOrderByOid, body: data)
    return try await apiClient.request(request) as [Order]
  }
  
  /// Performs the query order by cloid operation.
  public func queryOrderByCloid(cloid: String) async throws -> [Order] {
    let body = InfoRequestBody(type: "queryOrderByCloid", user: nil, coin: cloid, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .queryOrderByCloid, body: data)
    return try await apiClient.request(request) as [Order]
  }
  
  /// Performs the query fills operation.
  public func queryFills(address: String) async throws -> [Fill] {
    let body = InfoRequestBody(type: "queryFills", user: address, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .queryFills, body: data)
    return try await apiClient.request(request) as [Fill]
  }
  
  /// Performs the query user fundings operation.
  public func queryUserFundings(address: String) async throws -> [UserFunding] {
    let body = InfoRequestBody(type: "queryUserFundings", user: address, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .queryUserFundings, body: data)
    return try await apiClient.request(request) as [UserFunding]
  }
  
  /// Performs the get meta operation.
  public func getMeta() async throws -> Meta {
    let body = InfoRequestBody(type: "meta", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .meta, body: data)
    return try await apiClient.request(request) as Meta
  }
  
  /// Performs the get spot meta operation.
  public func getSpotMeta() async throws -> Meta {
    let body = InfoRequestBody(type: "spotMeta", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .spotMeta, body: data)
    return try await apiClient.request(request) as Meta
  }
  
  /// Performs the get time operation.
  public func getTime() async throws -> Date {
    let body = InfoRequestBody(type: "getTime", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .getTime, body: data)
    let response: TimeResponse = try await apiClient.request(request)
    return response.date
  }
  
  /// Performs the fetch builder fee operation.
  public func fetchBuilderFee(builderAddress: String) async throws -> BuilderFee {
    let body = InfoRequestBody(type: "fetchBuilderFee", user: builderAddress, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .fetchBuilderFee, body: data)
    return try await apiClient.request(request) as BuilderFee
  }
}

private struct TimeResponse: Decodable {
  let time: Int
  
  var date: Date {
    Date(timeIntervalSince1970: Double(time) / 1000)
  }
}
