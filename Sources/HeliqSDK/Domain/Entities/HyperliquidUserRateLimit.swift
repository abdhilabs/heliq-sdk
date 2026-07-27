//
//  HyperliquidUserRateLimit.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct HyperliquidUserRateLimit: Sendable, Equatable {
  public let cumulativeVolume: String
  public let requestsUsed: Int64
  public let requestsCap: Int64
  public let requestsSurplus: Int64

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
