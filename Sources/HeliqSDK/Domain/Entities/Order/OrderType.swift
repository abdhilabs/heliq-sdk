//
//  OrderType.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum OrderSide: String, Sendable, Codable {
  case buy = "Buy"
  case sell = "Sell"
}

public enum OrderType: Sendable, Codable {
  case market
  case limit
  case triggerMarket(TriggerParams)
  case triggerLimit(TriggerParams)
  
  enum CodingKeys: String, CodingKey {
    case type = "type"
    case triggerMarket = "triggerMarket"
    case triggerLimit = "triggerLimit"
    case trigger = "trigger"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    
    switch type {
    case "market":
      self = .market
    case "limit":
      self = .limit
    case "triggerMarket":
      let trigger = try container.decode(TriggerParams.self, forKey: .trigger)
      self = .triggerMarket(trigger)
    case "triggerLimit":
      let trigger = try container.decode(TriggerParams.self, forKey: .trigger)
      self = .triggerLimit(trigger)
    default:
      self = .limit
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    switch self {
    case .market:
      try container.encode("market", forKey: .type)
    case .limit:
      try container.encode("limit", forKey: .type)
    case .triggerMarket(let trigger):
      try container.encode("triggerMarket", forKey: .type)
      try container.encode(trigger, forKey: .trigger)
    case .triggerLimit(let trigger):
      try container.encode("triggerLimit", forKey: .type)
      try container.encode(trigger, forKey: .trigger)
    }
  }
}

public struct TriggerParams: Sendable, Codable {
  public let triggerPx: Double
  public let tpsl: String
  
  public init(triggerPx: Double, tpsl: String) {
    self.triggerPx = triggerPx
    self.tpsl = tpsl
  }
  
  enum CodingKeys: String, CodingKey {
    case triggerPx = "triggerPx"
    case tpsl = "tpsl"
  }
}

public enum TriggerOrderType: String, Sendable, Codable {
  case marketIfMarket
  case marketIfLimit
  case limitIfMarket
  case limitIfLimit
  
  enum CodingKeys: String, CodingKey {
    case type = "type"
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)
    
    switch type {
    case "marketIfMarket":
      self = .marketIfMarket
    case "marketIfLimit":
      self = .marketIfLimit
    case "limitIfMarket":
      self = .limitIfMarket
    case "limitIfLimit":
      self = .limitIfLimit
    default:
      self = .limitIfLimit
    }
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    switch self {
    case .marketIfMarket:
      try container.encode("marketIfMarket", forKey: .type)
    case .marketIfLimit:
      try container.encode("marketIfLimit", forKey: .type)
    case .limitIfMarket:
      try container.encode("limitIfMarket", forKey: .type)
    case .limitIfLimit:
      try container.encode("limitIfLimit", forKey: .type)
    }
  }
}

public struct OrderRequest: Sendable, Codable {
  public let asset: Int
  public let side: OrderSide
  public let orderType: OrderType
  public let size: Double
  public let price: Double?
  public let reduceOnly: Bool
  public let cloid: String?
  
  public init(
    asset: Int,
    side: OrderSide,
    orderType: OrderType,
    size: Double,
    price: Double? = nil,
    reduceOnly: Bool = false,
    cloid: String? = nil
  ) {
    self.asset = asset
    self.side = side
    self.orderType = orderType
    self.size = size
    self.price = price
    self.reduceOnly = reduceOnly
    self.cloid = cloid
  }
}
