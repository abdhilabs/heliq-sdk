//
//  HyperliquidFrontendOpenOrder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct HyperliquidFrontendOpenOrder: Sendable, Equatable {
  public let coin: String
  public let orderID: Int64
  public let side: String
  public let limitPrice: String
  public let originalSize: String
  public let size: String
  public let timestamp: Int64
  public let orderType: String
  public let isTrigger: Bool
  public let isPositionTpsl: Bool
  public let reduceOnly: Bool
  public let triggerCondition: String
  public let triggerPrice: String

  public static func decodeList(_ data: Data) throws -> [Self] {
    try JSONDecoder().decode([DTO].self, from: data).map(Self.init)
  }

  private struct DTO: Decodable {
    let coin: String
    let oid: Int64
    let side, limitPx, origSz, sz: String
    let timestamp: Int64
    let orderType: String
    let isTrigger, isPositionTpsl, reduceOnly: Bool
    let triggerCondition, triggerPx: String
  }

  private init(_ dto: DTO) {
    coin = dto.coin; orderID = dto.oid; side = dto.side; limitPrice = dto.limitPx
    originalSize = dto.origSz; size = dto.sz; timestamp = dto.timestamp; orderType = dto.orderType
    isTrigger = dto.isTrigger; isPositionTpsl = dto.isPositionTpsl; reduceOnly = dto.reduceOnly
    triggerCondition = dto.triggerCondition; triggerPrice = dto.triggerPx
  }
}
