//
//  HyperliquidUserRateLimit.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for hyperliquid user rate limit.
public struct HyperliquidUserRateLimit: Sendable, Equatable {
  /// The cumulative volume associated with this value.
  public let cumulativeVolume: String
  /// The requests used associated with this value.
  public let requestsUsed: Int64
  /// The requests cap associated with this value.
  public let requestsCap: Int64
  /// The requests surplus associated with this value.
  public let requestsSurplus: Int64

  /// Decodes this value from the supplied response data.
  public static func decode(_ data: Data) throws -> Self {
    let dto = try JSONDecoder().decode(DTO.self, from: data)
    return .init(cumulativeVolume: dto.cumVlm, requestsUsed: dto.nRequestsUsed,
                 requestsCap: dto.nRequestsCap, requestsSurplus: dto.nRequestsSurplus)
  }

  private struct DTO: Decodable {
    let cumVlm: String
    let nRequestsUsed, nRequestsCap, nRequestsSurplus: Int64
  }
}
