//
//  HyperliquidUserFill.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// A precision-preserving projection of Hyperliquid's `userFills` response.
public struct HyperliquidUserFill: Sendable, Equatable {
  /// The closed pnl associated with this value.
  public let closedPnl: String
  /// The coin associated with this value.
  public let coin: String
  /// The crossed associated with this value.
  public let crossed: Bool
  /// The direction associated with this value.
  public let direction: String
  /// The hash associated with this value.
  public let hash: String
  /// The order i d associated with this value.
  public let orderID: Int64
  /// The price associated with this value.
  public let price: String
  /// The side associated with this value.
  public let side: String
  /// The start position associated with this value.
  public let startPosition: String
  /// The size associated with this value.
  public let size: String
  /// The timestamp associated with this value.
  public let timestamp: Date
  /// The fee associated with this value.
  public let fee: String
  /// The fee token associated with this value.
  public let feeToken: String
  /// The builder fee associated with this value.
  public let builderFee: String?
  /// The trade i d associated with this value.
  public let tradeID: Int64

  /// Decodes values from the supplied response data.
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
