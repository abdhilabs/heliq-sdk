//
//  HyperliquidUserFill.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// A precision-preserving projection of Hyperliquid's `userFills` response.
public struct HyperliquidUserFill: Sendable, Equatable {
  public let closedPnl: String
  public let coin: String
  public let crossed: Bool
  public let direction: String
  public let hash: String
  public let orderID: Int64
  public let price: String
  public let side: String
  public let startPosition: String
  public let size: String
  public let timestamp: Date
  public let fee: String
  public let feeToken: String
  public let builderFee: String?
  public let tradeID: Int64

  public static func decodeList(_ data: Data) throws -> [Self] {
    try JSONDecoder().decode([DTO].self, from: data).map(Self.init)
  }

  private init(_ dto: DTO) {
    closedPnl = dto.closedPnl
    coin = dto.coin
    crossed = dto.crossed
    direction = dto.direction
    hash = dto.hash
    orderID = dto.orderID
    price = dto.price
    side = dto.side
    startPosition = dto.startPosition
    size = dto.size
    timestamp = Date(timeIntervalSince1970: Double(dto.timestamp) / 1_000)
    fee = dto.fee
    feeToken = dto.feeToken
    builderFee = dto.builderFee
    tradeID = dto.tradeID
  }

  private struct DTO: Decodable {
    let closedPnl: String
    let coin: String
    let crossed: Bool
    let direction: String
    let hash: String
    let orderID: Int64
    let price: String
    let side: String
    let startPosition: String
    let size: String
    let timestamp: Int64
    let fee: String
    let feeToken: String
    let builderFee: String?
    let tradeID: Int64

    enum CodingKeys: String, CodingKey {
      case closedPnl, coin, crossed, hash, side, fee, feeToken, builderFee
      case direction = "dir"
      case orderID = "oid"
      case price = "px"
      case startPosition
      case size = "sz"
      case timestamp = "time"
      case tradeID = "tid"
    }
  }
}
