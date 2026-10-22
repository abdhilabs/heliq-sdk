//
//  OrderType.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a set of supported values for order side.
public enum OrderSide: String, Sendable, Codable {
  /// The `buy` case.
  case buy = "Buy"
  /// The `sell` case.
  case sell = "Sell"
}

/// Represents a set of supported values for order type.
public enum OrderType: Sendable, Codable {
  /// The `market` case.
  case market
  /// The `limit` case.
  case limit
  /// The `triggerMarket` case.
  case triggerMarket(TriggerParams)
  /// The `triggerLimit` case.
  case triggerLimit(TriggerParams)
  
  enum CodingKeys: String, CodingKey {
    /// The discriminator key for the encoded order type.
    case type = "type"
    /// The key for the trigger-market payload.
    case triggerMarket = "triggerMarket"
    /// The key for the trigger-limit payload.
    case triggerLimit = "triggerLimit"
    /// The key for trigger parameters.
    case trigger = "trigger"
  }
  
  /// Creates an instance with the supplied values.
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
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: container,
        debugDescription: "Unsupported order type: \(type)"
      )
    }
  }
  
  /// Encodes this value into the supplied encoder.
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

/// Represents a value for trigger params.
public struct TriggerParams: Sendable, Codable {
  /// The trigger px associated with this value.
  public let triggerPx: Double
  /// The tpsl associated with this value.
  public let tpsl: String
  
  /// Creates an instance with the supplied values.
  public init(triggerPx: Double, tpsl: String) {
    self.triggerPx = triggerPx
    self.tpsl = tpsl
  }
  
  enum CodingKeys: String, CodingKey {
    case triggerPx = "triggerPx"
    case tpsl = "tpsl"
  }
}

/// Represents a set of supported values for trigger order type.
public enum TriggerOrderType: String, Sendable, Codable {
  /// The `marketIfMarket` case.
  case marketIfMarket
  /// The `marketIfLimit` case.
  case marketIfLimit
  /// The `limitIfMarket` case.
  case limitIfMarket
  /// The `limitIfLimit` case.
  case limitIfLimit
  
  enum CodingKeys: String, CodingKey {
    /// The discriminator key for the encoded trigger order type.
    case type = "type"
  }
  
  /// Creates an instance with the supplied values.
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
      throw DecodingError.dataCorruptedError(
        forKey: .type,
        in: container,
        debugDescription: "Unsupported trigger order type: \(type)"
      )
    }
  }
  
  /// Encodes this value into the supplied encoder.
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

/// Represents a value for order request.
public struct OrderRequest: Sendable, Codable {
  /// The asset associated with this value.
  public let asset: Int
  /// The side associated with this value.
  public let side: OrderSide
  /// The order type associated with this value.
  public let orderType: OrderType
  /// The size associated with this value.
  public let size: Double
  /// The price associated with this value.
  public let price: Double?
  /// The reduce only associated with this value.
  public let reduceOnly: Bool
  /// The cloid associated with this value.
  public let cloid: String?
  
  /// Creates an instance with the supplied values.
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
