//
//  HyperliquidTypedResponses.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Shared inclusive time window for Hyperliquid history endpoints.
public struct HyperliquidPageRequest: Sendable, Equatable {
  /// The start time associated with this value.
  public let startTime: Date
  /// The end time associated with this value.
  public let endTime: Date?
  /// The limit associated with this value.
  public let limit: Int?

  /// Creates an instance with the supplied values.
  public init(startTime: Date, endTime: Date? = nil, limit: Int? = nil) {
    self.startTime = startTime
    self.endTime = endTime
    self.limit = limit
  }

  /// The parameters value.
  public var parameters: [String: JSONValue] {
    var result: [String: JSONValue] = ["startTime": .number(startTime.timeIntervalSince1970 * 1_000)]
    if let endTime { result["endTime"] = .number(endTime.timeIntervalSince1970 * 1_000) }
    if let limit { result["limit"] = .number(Double(limit)) }
    return result
  }
}

/// Typed representation of `metaAndAssetCtxs`, keeping protocol decimal values as strings.
public struct HyperliquidMetaAndAssetCtxs: Sendable, Equatable {
  /// Represents a value for universe asset.
  public struct UniverseAsset: Sendable, Codable, Equatable {
    /// The name associated with this value.
    public let name: String
    /// The sz decimals associated with this value.
    public let szDecimals: Int
    /// The max leverage associated with this value.
    public let maxLeverage: Int
    /// The only isolated associated with this value.
    public let onlyIsolated: Bool?
  }

  /// Represents a value for asset context.
  public struct AssetContext: Sendable, Codable, Equatable {
    /// The funding associated with this value.
    public let funding: String?
    /// The mark px associated with this value.
    public let markPx: String?
    /// The open interest associated with this value.
    public let openInterest: String?
    /// The mid px associated with this value.
    public let midPx: String?
  }

  /// The universe associated with this value.
  public let universe: [UniverseAsset]
  /// The asset contexts associated with this value.
  public let assetContexts: [AssetContext]

  /// Decodes this value from the supplied response data.
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
