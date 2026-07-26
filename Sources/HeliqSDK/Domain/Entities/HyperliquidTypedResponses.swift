//
//  HyperliquidTypedResponses.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Shared inclusive time window for Hyperliquid history endpoints.
public struct HyperliquidPageRequest: Sendable, Equatable {
  public let startTime: Date
  public let endTime: Date?
  public let limit: Int?

  public init(startTime: Date, endTime: Date? = nil, limit: Int? = nil) {
    self.startTime = startTime
    self.endTime = endTime
    self.limit = limit
  }

  public var parameters: [String: JSONValue] {
    var result: [String: JSONValue] = ["startTime": .number(startTime.timeIntervalSince1970 * 1_000)]
    if let endTime { result["endTime"] = .number(endTime.timeIntervalSince1970 * 1_000) }
    if let limit { result["limit"] = .number(Double(limit)) }
    return result
  }
}

/// Typed representation of `metaAndAssetCtxs`, keeping protocol decimal values as strings.
public struct HyperliquidMetaAndAssetCtxs: Sendable, Equatable {
  public struct UniverseAsset: Sendable, Codable, Equatable {
    public let name: String
    public let szDecimals: Int
    public let maxLeverage: Int
    public let onlyIsolated: Bool?
  }

  public struct AssetContext: Sendable, Codable, Equatable {
    public let funding: String?
    public let markPx: String?
    public let openInterest: String?
    public let midPx: String?
  }

  public let universe: [UniverseAsset]
  public let assetContexts: [AssetContext]

  public static func decode(_ data: Data) throws -> Self {
    struct Meta: Decodable { let universe: [UniverseAsset] }
    let root = try JSONDecoder().decode([JSONValue].self, from: data)
    guard root.count == 2 else { throw ValidationError.malformedData(reason: "metaAndAssetCtxs requires metadata and contexts") }
    let metaData = try JSONEncoder().encode(root[0])
    let contextData = try JSONEncoder().encode(root[1])
    return .init(universe: try JSONDecoder().decode(Meta.self, from: metaData).universe,
                 assetContexts: try JSONDecoder().decode([AssetContext].self, from: contextData))
  }
}
