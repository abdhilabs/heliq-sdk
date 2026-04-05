//
//  InfoRepositoryImpl.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct InfoRequestBody: Encodable {
  let type: String
  let user: String?
  let coin: String?
  let interval: String?
  let startTime: Int?
  let endTime: Int?
}

public enum InfoEndpoint: Sendable {
  case userState
  case spotUserState
  case allMids
  case assetCtxs
  case spotAssetCtxs
  case candleSnapshot
  case l2Book
  case queryOrderByOid
  case queryOrderByCloid
  case queryFills
  case queryUserFundings
  case meta
  case spotMeta
  case getTime
  case fetchBuilderFee
  
  var path: String { "/info" }
}

public struct InfoAPIRequest: APIRouterProtocol, Sendable {
  public let endpoint: InfoEndpoint
  private let _body: Data?
  
  public var path: String { endpoint.path }
  public var method: HTTPMethod { .post }
  public var body: Data? { _body }
  
  public init(endpoint: InfoEndpoint, body: Data?) {
    self.endpoint = endpoint
    self._body = body
  }
}

public final class InfoRepositoryImpl: InfoRepository, @unchecked Sendable {
  private let apiClient: APIClient
  
  public init(apiClient: APIClient) {
    self.apiClient = apiClient
  }
  
  public func getUserState(address: String) async throws -> UserState {
    let body = InfoRequestBody(type: "userState", user: address, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .userState, body: data)
    return try await apiClient.request(request) as UserState
  }
  
  public func getSpotUserState(address: String) async throws -> SpotUserState {
    let body = InfoRequestBody(type: "spotUserState", user: address, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .spotUserState, body: data)
    return try await apiClient.request(request) as SpotUserState
  }
  
  public func getAllMids() async throws -> AllMids {
    let body = InfoRequestBody(type: "allMids", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .allMids, body: data)
    return try await apiClient.request(request) as AllMids
  }
  
  public func getAssetCtxs() async throws -> [AssetContext] {
    let body = InfoRequestBody(type: "assetCtxs", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .assetCtxs, body: data)
    return try await apiClient.request(request) as [AssetContext]
  }
  
  public func getSpotAssetCtxs() async throws -> [SpotAssetContext] {
    let body = InfoRequestBody(type: "spotAssetCtxs", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .spotAssetCtxs, body: data)
    return try await apiClient.request(request) as [SpotAssetContext]
  }
  
  public func getCandleSnapshot(coin: String, interval: String, startTime: Date, endTime: Date) async throws -> [Candle] {
    let body = InfoRequestBody(
      type: "candleSnapshot",
      user: nil,
      coin: coin,
      interval: interval,
      startTime: Int(startTime.timeIntervalSince1970 * 1000),
      endTime: Int(endTime.timeIntervalSince1970 * 1000)
    )
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .candleSnapshot, body: data)
    return try await apiClient.request(request) as [Candle]
  }
  
  public func getL2Book(coin: String) async throws -> L2Book {
    let body = InfoRequestBody(type: "l2Book", user: nil, coin: coin, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .l2Book, body: data)
    return try await apiClient.request(request) as L2Book
  }
  
  public func queryOrderByOid(orderId: String) async throws -> [Order] {
    let body = InfoRequestBody(type: "queryOrderByOid", user: nil, coin: orderId, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .queryOrderByOid, body: data)
    return try await apiClient.request(request) as [Order]
  }
  
  public func queryOrderByCloid(cloid: String) async throws -> [Order] {
    let body = InfoRequestBody(type: "queryOrderByCloid", user: nil, coin: cloid, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .queryOrderByCloid, body: data)
    return try await apiClient.request(request) as [Order]
  }
  
  public func queryFills(address: String) async throws -> [Fill] {
    let body = InfoRequestBody(type: "queryFills", user: address, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .queryFills, body: data)
    return try await apiClient.request(request) as [Fill]
  }
  
  public func queryUserFundings(address: String) async throws -> [UserFunding] {
    let body = InfoRequestBody(type: "queryUserFundings", user: address, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .queryUserFundings, body: data)
    return try await apiClient.request(request) as [UserFunding]
  }
  
  public func getMeta() async throws -> Meta {
    let body = InfoRequestBody(type: "meta", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .meta, body: data)
    return try await apiClient.request(request) as Meta
  }
  
  public func getSpotMeta() async throws -> Meta {
    let body = InfoRequestBody(type: "spotMeta", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .spotMeta, body: data)
    return try await apiClient.request(request) as Meta
  }
  
  public func getTime() async throws -> Date {
    let body = InfoRequestBody(type: "getTime", user: nil, coin: nil, interval: nil, startTime: nil, endTime: nil)
    let data = try JSONCoder.encode(body)
    let request = InfoAPIRequest(endpoint: .getTime, body: data)
    let response: TimeResponse = try await apiClient.request(request)
    return response.date
  }
  
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
