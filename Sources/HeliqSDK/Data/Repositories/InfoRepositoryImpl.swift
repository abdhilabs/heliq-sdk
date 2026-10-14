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
  /// Info requests are read-only and safe to retry.
  public var isRetryable: Bool { true }
  
  /// Creates a info apirequest.
  public init(endpoint: InfoEndpoint, body: Data?) {
    self.endpoint = endpoint
    self._body = body
  }
}

/// Provides info repository impl functionality.
public final class InfoRepositoryImpl: InfoRepository, @unchecked Sendable {
  private let apiClient: APIClient
  private let defaultUserAddress: String?
  private let assetCache = AssetMetaCache()
  
  /// Creates a info repository impl.
  public init(apiClient: APIClient, defaultUserAddress: String? = nil) {
    self.apiClient = apiClient
    self.defaultUserAddress = defaultUserAddress
  }
  
  /// Performs the get user state operation.
  public func getUserState(address: String) async throws -> UserState {
    try validateAddress(address)
    let response: ClearinghouseResponse = try await request(.init(
      type: .clearinghouseState, parameters: ["user": .string(address)]
    ))
    var positions: [AssetPosition] = []
    for item in response.assetPositions {
      let position = item.position
      guard let mode = MarginMode(rawValue: position.leverage.type) else {
        throw ValidationError.invalidEnumValue(type: "MarginMode", value: position.leverage.type)
      }
      positions.append(AssetPosition(
        asset: try await asset(for: position.coin),
        positionSize: try decimal(position.szi),
        entryPrice: try position.entryPx.map(decimal),
        unrealizedPnl: try decimal(position.unrealizedPnl),
        realizedPnl: nil,
        marginUsed: try decimal(position.marginUsed),
        marginMode: mode, leverage: position.leverage.value
      ))
    }
    let modes = Set(positions.compactMap(\.marginMode))
    let leverages = Set(positions.compactMap(\.leverage))
    return UserState(
      accountAddress: address, assetPositions: positions,
      marginUsed: try decimal(response.marginSummary.totalMarginUsed),
      marginTotal: try decimal(response.marginSummary.accountValue),
      marginMode: modes.count == 1 ? modes.first : nil,
      leverage: leverages.count == 1 ? leverages.first : nil
    )
  }

  /// Retrieves balances from the official spot clearinghouse endpoint.
  public func getSpotUserState(address: String) async throws -> SpotUserState {
    try validateAddress(address)
    let response: SpotClearinghouseResponse = try await request(.init(
      type: .spotClearinghouseState, parameters: ["user": .string(address)]
    ))
    return SpotUserState(
      accountAddress: address,
      spotPositions: try response.balances.map {
        SpotPosition(asset: $0.token, totalSize: try decimal($0.total), hold: try decimal($0.hold))
      },
      totalUsdc: try response.balances.filter { $0.coin == "USDC" }.reduce(0) { try $0 + decimal($1.total) }
    )
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
    let response: [CandleResponse] = try await apiClient.request(request)
    return try response.map { try $0.candle() }
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
    guard let address = defaultUserAddress else {
      throw ValidationError.missingRequiredField(field: "address")
    }
    return try await queryOrderByOid(orderId: orderId, address: address)
  }

  /// Looks up an order for an explicit user address.
  public func queryOrderByOid(orderId: String, address: String) async throws -> [Order] {
    try validateAddress(address)
    guard let oid = Int64(orderId), oid >= 0 else {
      throw ValidationError.invalidFieldFormat(field: "orderId", expected: "non-negative Int64")
    }
    return try await orders(for: .orderStatus(user: address, oid: oid))
  }

  /// Looks up a client order ID using the client's configured wallet.
  public func queryOrderByCloid(cloid: String) async throws -> [Order] {
    guard let address = defaultUserAddress else {
      throw ValidationError.missingRequiredField(field: "address")
    }
    return try await queryOrderByCloid(cloid: cloid, address: address)
  }

  /// Looks up a client order ID for an explicit user address.
  public func queryOrderByCloid(cloid: String, address: String) async throws -> [Order] {
    try validateAddress(address)
    guard cloid.hasPrefix("0x"), cloid.count == 34, cloid.isValidHex else {
      throw ValidationError.invalidFieldFormat(field: "cloid", expected: "0x-prefixed 16-byte hex ID")
    }
    return try await orders(for: .orderStatus(user: address, cloid: cloid))
  }

  /// Retrieves fills from the official userFills endpoint.
  public func queryFills(address: String) async throws -> [Fill] {
    try validateAddress(address)
    let data = try await apiClient.requestData(HyperliquidRawRequest(
      path: "/info", body: HyperliquidInfoRequest.userFills(user: address).body()
    ))
    return try HyperliquidUserFill.decodeList(data).map {
      Fill(id: String($0.tradeID), orderId: String($0.orderID), side: try side($0.side),
           price: try decimal($0.price), size: try decimal($0.size), fee: try decimal($0.fee),
           timestamp: $0.timestamp, symbol: $0.coin)
    }
  }

  /// Retrieves funding history from the official userFunding endpoint.
  public func queryUserFundings(address: String) async throws -> [UserFunding] {
    try validateAddress(address)
    let response: [FundingResponse] = try await request(.init(
      type: .userFunding, parameters: ["user": .string(address), "startTime": .number(0)]
    ))
    var fundings: [UserFunding] = []
    for item in response {
      fundings.append(UserFunding(
        asset: try await asset(for: item.delta.coin), payment: try decimal(item.delta.usdc),
        rate: try decimal(item.delta.fundingRate),
        time: Date(timeIntervalSince1970: Double(item.time) / 1_000)
      ))
    }
    return fundings
  }

  /// Performs the get meta operation.
  public func getMeta() async throws -> Meta {
    let response: PerpetualMetadataResponse = try await request(.init(type: .meta))
    return Meta(
      universe: response.universe.enumerated().map { index, asset in
        MetaAsset(asset: index, name: asset.name, szDecimals: asset.szDecimals,
                  weiDecimals: nil, isPerpetual: true,
                  onlyIsolatedMargin: (asset.onlyIsolated ?? false) || ["strictIsolated", "noCross"].contains(asset.marginMode ?? ""))
      },
      spotAssetConfigs: [:]
    )
  }

  /// Retrieves spot market definitions and their base-token configuration.
  public func getSpotMeta() async throws -> Meta {
    let response: SpotMetadataResponse = try await request(.init(type: .spotMeta))
    var universe: [MetaAsset] = []
    var configs: [String: SpotAssetConfig] = [:]
    for market in response.universe {
      guard market.tokens.count == 2,
            let base = response.tokens.first(where: { $0.index == market.tokens[0] }),
            response.tokens.contains(where: { $0.index == market.tokens[1] }),
            market.index >= 0, market.index <= Int.max - 10_000 else {
        throw ValidationError.malformedData(reason: "Invalid spot market token references")
      }
      let asset = 10_000 + market.index
      universe.append(MetaAsset(
        asset: asset, name: market.name, szDecimals: base.szDecimals,
        weiDecimals: base.weiDecimals, isPerpetual: false
      ))
      configs[String(asset)] = SpotAssetConfig(tokenCfg: TokenConfig(
        name: base.fullName ?? base.name, symbol: base.name, decimals: base.weiDecimals
      ))
    }
    return Meta(universe: universe, spotAssetConfigs: configs)
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
    guard let address = defaultUserAddress else {
      throw ValidationError.missingRequiredField(field: "address")
    }
    return try await fetchBuilderFee(builderAddress: builderAddress, address: address)
  }

  /// Retrieves builder approval for an explicit user address.
  public func fetchBuilderFee(builderAddress: String, address: String) async throws -> BuilderFee {
    try validateAddress(address)
    try validateAddress(builderAddress, field: "builderAddress")
    let tenthsOfBps: Int = try await request(.init(type: .maxBuilderFee, parameters: [
      "user": .string(address), "builder": .string(builderAddress)
    ]))
    guard tenthsOfBps >= 0 else {
      throw ValidationError.malformedData(reason: "Negative builder fee approval")
    }
    return BuilderFee(builderAddress: builderAddress, feeBps: Double(tenthsOfBps) / 10)
  }

  private func request<T: Decodable>(_ request: HyperliquidInfoRequest) async throws -> T {
    let data = try await apiClient.requestData(HyperliquidRawRequest(path: "/info", body: request.body()))
    return try JSONDecoder().decode(T.self, from: data)
  }

  private func validateAddress(_ address: String, field: String = "address") throws {
    guard address.hasPrefix("0x"), address.isValidEthereumAddress else {
      throw ValidationError.invalidFieldFormat(field: field, expected: "0x-prefixed 20-byte hex address")
    }
  }

  private func decimal(_ value: String) throws -> Double {
    guard let number = Double(value), number.isFinite else {
      throw ValidationError.malformedData(reason: "Invalid decimal in Info response")
    }
    return number
  }

  private func side(_ value: String) throws -> OrderSide {
    switch value {
    case "B": return .buy
    case "A": return .sell
    default: throw ValidationError.invalidEnumValue(type: "OrderSide", value: value)
    }
  }

  private func asset(for coin: String) async throws -> Int {
    if coin.hasPrefix("@"), let index = Int(coin.dropFirst()), index >= 0, index <= Int.max - 10_000 {
      return 10_000 + index
    }
    if let asset = await assetCache.getAsset(coin: coin) { return asset }
    let meta: AssetUniverseResponse = try await request(.init(type: .meta))
    await assetCache.setMappings(mappings: meta.universe.enumerated().map { ($0.element.name, $0.offset) })
    if let asset = await assetCache.getAsset(coin: coin) { return asset }
    let spot: SpotUniverseResponse = try await request(.init(type: .spotMeta))
    await assetCache.setMappings(mappings: spot.universe.map { ($0.name, 10_000 + $0.index) })
    guard let asset = await assetCache.getAsset(coin: coin) else {
      throw ValidationError.malformedData(reason: "Unknown asset in Info response: \(coin)")
    }
    return asset
  }

  private func orders(for request: HyperliquidInfoRequest) async throws -> [Order] {
    let data = try await apiClient.requestData(HyperliquidRawRequest(path: "/info", body: request.body()))
    let response = try HyperliquidOrderStatus.decode(data)
    guard let order = response.order else {
      guard response.status == "unknownOid" else {
        throw ValidationError.malformedData(reason: "Unexpected order status: \(response.status)")
      }
      return []
    }
    let status: OrderStatus
    if response.status == "canceled" { status = .cancelled }
    else if let value = OrderStatus(rawValue: response.status) { status = value }
    else { throw ValidationError.invalidEnumValue(type: "OrderStatus", value: response.status) }
    let type: OrderType
    switch order.orderType {
    case "Market": type = .market
    case "Limit": type = .limit
    case "Stop Market", "Take Profit Market":
      type = .triggerMarket(.init(triggerPx: try decimal(order.triggerPrice),
                                 tpsl: order.orderType == "Stop Market" ? "sl" : "tp"))
    case "Stop Limit", "Take Profit Limit":
      type = .triggerLimit(.init(triggerPx: try decimal(order.triggerPrice),
                                tpsl: order.orderType == "Stop Limit" ? "sl" : "tp"))
    default: throw ValidationError.invalidEnumValue(type: "OrderType", value: order.orderType)
    }
    let originalSize = try decimal(order.originalSize)
    let size = try decimal(order.size)
    guard size >= 0, originalSize >= size else {
      throw ValidationError.malformedData(reason: "Invalid order sizes")
    }
    return [Order(
      oid: String(order.orderID), cloid: order.cloid, asset: try await asset(for: order.coin),
      side: try side(order.side), orderType: type, size: size,
      price: try decimal(order.limitPrice), filled: originalSize - size,
      status: status, timestamp: order.timestamp
    )]
  }

}

private struct TimeResponse: Decodable {
  let time: Int
  
  var date: Date {
    Date(timeIntervalSince1970: Double(time) / 1000)
  }
}

private struct CandleResponse: Decodable {
  let t: Int64
  let o: String
  let h: String
  let l: String
  let c: String
  let v: String

  func candle() throws -> Candle {
    guard let open = Double(o), let high = Double(h), let low = Double(l),
          let close = Double(c), let volume = Double(v),
          [open, high, low, close, volume].allSatisfy({ $0.isFinite }) else {
      throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Invalid candle decimal"))
    }
    return Candle(
      timestamp: Date(timeIntervalSince1970: Double(t) / 1_000),
      open: open, high: high, low: low, close: close, volume: volume
    )
  }
}

private struct ClearinghouseResponse: Decodable {
  struct MarginSummary: Decodable {
    let accountValue: String
    let totalMarginUsed: String
  }
  struct AssetPosition: Decodable {
    struct Position: Decodable {
      struct Leverage: Decodable { let type: String; let value: Int }
      let coin: String
      let szi: String
      let entryPx: String?
      let unrealizedPnl: String
      let marginUsed: String
      let leverage: Leverage
    }
    let position: Position
  }
  let marginSummary: MarginSummary
  let assetPositions: [AssetPosition]
}

private struct SpotClearinghouseResponse: Decodable {
  struct Balance: Decodable {
    let coin: String
    let token: Int
    let total: String
    let hold: String
  }
  let balances: [Balance]
}

private struct FundingResponse: Decodable {
  struct Delta: Decodable { let coin: String; let usdc: String; let fundingRate: String }
  let time: Int64
  let delta: Delta
}

private struct AssetUniverseResponse: Decodable {
  struct Asset: Decodable { let name: String }
  let universe: [Asset]
}

private struct SpotUniverseResponse: Decodable {
  struct Asset: Decodable { let name: String; let index: Int }
  let universe: [Asset]
}

private struct PerpetualMetadataResponse: Decodable {
  struct Asset: Decodable {
    let name: String
    let szDecimals: Int
    let onlyIsolated: Bool?
    let marginMode: String?
  }
  let universe: [Asset]
}

private struct SpotMetadataResponse: Decodable {
  struct Token: Decodable {
    let name: String
    let index: Int
    let szDecimals: Int
    let weiDecimals: Int
    let fullName: String?
  }
  struct Market: Decodable {
    let name: String
    let index: Int
    let tokens: [Int]
  }
  let tokens: [Token]
  let universe: [Market]
}
