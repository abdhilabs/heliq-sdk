//
//  WebSocketDataParser.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines web socket data type values.
public enum WebSocketDataType: Sendable {
  /// The `allMids` option.
  case allMids(AllMids)
  /// The `l2Book` option.
  case l2Book(L2Book)
  /// The `trades` option.
  case trades([Trade])
  /// The `userFill` option.
  case userFill(Fill)
  /// The `userEvent` option.
  case userEvent(UserEvent)
  /// The `candle` option.
  case candle(Candle)
  /// The `orderUpdate` option.
  case orderUpdate(Order)
  /// The `userFunding` option.
  case userFunding(UserFunding)
  /// The `unknown` option.
  case unknown
}

/// Represents trade data.
public struct Trade: Sendable, Codable {
  /// The price.
  public let price: Double
  /// The size.
  public let size: Double
  /// The side.
  public let side: OrderSide
  /// The timestamp.
  public let timestamp: Date
  /// The hash.
  public let hash: String?
  
  /// Creates a trade.
  public init(price: Double, size: Double, side: OrderSide, timestamp: Date, hash: String? = nil) {
    self.price = price
    self.size = size
    self.side = side
    self.timestamp = timestamp
    self.hash = hash
  }
}

/// Defines user event type values.
public enum UserEventType: String, Sendable, Codable {
  /// The `orderPlaced` option.
  case orderPlaced = "orderPlaced"
  /// The `orderFilled` option.
  case orderFilled = "orderFilled"
  /// The `orderCancelled` option.
  case orderCancelled = "orderCancelled"
  /// The `orderUpdated` option.
  case orderUpdated = "orderUpdated"
}

/// Represents user event data.
public struct UserEvent: Sendable, Codable {
  /// The type.
  public let type: UserEventType
  /// The order id.
  public let orderId: String?
  /// The cloid.
  public let cloid: String?
  /// The filled size.
  public let filledSize: Double?
  /// The filled px.
  public let filledPx: Double?
  
  /// Creates a user event.
  public init(type: UserEventType, orderId: String? = nil, cloid: String? = nil, filledSize: Double? = nil, filledPx: Double? = nil) {
    self.type = type
    self.orderId = orderId
    self.cloid = cloid
    self.filledSize = filledSize
    self.filledPx = filledPx
  }
}

/// Provides web socket data parser functionality.
public final class WebSocketDataParser {
  /// Creates a web socket data parser.
  public init() {}
  
  /// Performs the parse operation.
  public func parse(channel: String, data: Data) throws -> WebSocketDataType {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw ValidationError.malformedData(reason: "Invalid JSON for channel \(channel)")
    }
    
    switch channel {
    case "allMids":
      return parseAllMids(json)
    case "l2Book":
      return parseL2Book(json)
    case "trades":
      return parseTrades(json)
    case "userFills":
      return parseUserFill(json)
    case "userEvents":
      return parseUserEvent(json)
    case "candle":
      return parseCandle(json)
    case "orderUpdates":
      return parseOrderUpdate(json)
    case "userFundings":
      return parseUserFunding(json)
    default:
      return .unknown
    }
  }
  
  private func parseAllMids(_ json: [String: Any]) -> WebSocketDataType {
    var prices: [String: Double] = [:]
    for (key, value) in json {
      if let price = value as? Double {
        prices[key] = price
      } else if let priceString = value as? String, let price = Double(priceString) {
        prices[key] = price
      }
    }
    return .allMids(AllMids(prices: prices))
  }
  
  private func parseL2Book(_ json: [String: Any]) -> WebSocketDataType {
    guard let coin = json["coin"] as? String else { return .unknown }
    
    var levels: [L2Level] = []
    
    if let bids = json["bids"] as? [[Double]] {
      for bid in bids {
        if bid.count >= 2 {
          let level = L2Level(price: bid[0], size: bid[1], side: .buy)
          levels.append(level)
        }
      }
    }
    
    if let asks = json["asks"] as? [[Double]] {
      for ask in asks {
        if ask.count >= 2 {
          let level = L2Level(price: ask[0], size: ask[1], side: .sell)
          levels.append(level)
        }
      }
    }
    
    let timestamp = Date()
    return .l2Book(L2Book(coin: coin, levels: levels, timestamp: timestamp))
  }
  
  private func parseTrades(_ json: [String: Any]) -> WebSocketDataType {
    guard let tradesArray = json["trades"] as? [[String: Any]] else { return .unknown }
    
    var trades: [Trade] = []
    for tradeData in tradesArray {
      guard let price = tradeData["price"] as? Double ?? (tradeData["price"] as? String).flatMap({ Double($0) }),
            let size = tradeData["size"] as? Double ?? (tradeData["size"] as? String).flatMap({ Double($0) }),
            let sideRaw = tradeData["side"] as? String else { continue }
      
      let side = sideRaw.lowercased() == "buy" ? OrderSide.buy : OrderSide.sell
      let timestamp = (tradeData["time"] as? Int).map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? Date()
      let hash = tradeData["hash"] as? String
      
      let trade = Trade(price: price, size: size, side: side, timestamp: timestamp, hash: hash)
      trades.append(trade)
    }
    
    return .trades(trades)
  }
  
  private func parseUserFill(_ json: [String: Any]) -> WebSocketDataType {
    guard let orderId = json["orderId"] as? String,
          let sideRaw = json["side"] as? String,
          let price = json["price"] as? Double ?? (json["price"] as? String).flatMap({ Double($0) }),
          let size = json["size"] as? Double ?? (json["size"] as? String).flatMap({ Double($0) }) else {
      return .unknown
    }
    
    let side = sideRaw.lowercased() == "buy" ? OrderSide.buy : OrderSide.sell
    let fee = json["fee"] as? Double ?? 0
    let timestamp = (json["time"] as? Int).map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? Date()
    let symbol = json["symbol"] as? String ?? ""
    let id = json["id"] as? String ?? UUID().uuidString
    
    let fill = Fill(id: id, orderId: orderId, side: side, price: price, size: size, fee: fee, timestamp: timestamp, symbol: symbol)
    return .userFill(fill)
  }
  
  private func parseUserEvent(_ json: [String: Any]) -> WebSocketDataType {
    guard let typeRaw = json["type"] as? String,
          let type = UserEventType(rawValue: typeRaw) else { return .unknown }
    
    let orderId = json["orderId"] as? String
    let cloid = json["cloid"] as? String
    let filledSize = json["filledSize"] as? Double ?? (json["filledSize"] as? String).flatMap({ Double($0) })
    let filledPx = json["filledPx"] as? Double ?? (json["filledPx"] as? String).flatMap({ Double($0) })
    
    let event = UserEvent(type: type, orderId: orderId, cloid: cloid, filledSize: filledSize, filledPx: filledPx)
    return .userEvent(event)
  }
  
  private func parseCandle(_ json: [String: Any]) -> WebSocketDataType {
    guard let open = json["open"] as? Double ?? (json["open"] as? String).flatMap({ Double($0) }),
          let high = json["high"] as? Double ?? (json["high"] as? String).flatMap({ Double($0) }),
          let low = json["low"] as? Double ?? (json["low"] as? String).flatMap({ Double($0) }),
          let close = json["close"] as? Double ?? (json["close"] as? String).flatMap({ Double($0) }),
          let volume = json["volume"] as? Double ?? (json["volume"] as? String).flatMap({ Double($0) }) else {
      return .unknown
    }
    
    let timestamp = (json["time"] as? Int).map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? Date()
    
    let candle = Candle(timestamp: timestamp, open: open, high: high, low: low, close: close, volume: volume)
    return .candle(candle)
  }
  
  private func parseOrderUpdate(_ json: [String: Any]) -> WebSocketDataType {
    guard let oid = json["oid"] as? String,
          let asset = json["asset"] as? Int,
          let sideRaw = json["side"] as? String else { return .unknown }
    
    let side = sideRaw.lowercased() == "buy" ? OrderSide.buy : OrderSide.sell
    let cloid = json["cloid"] as? String
    let size = json["size"] as? Double ?? 0
    let price = json["price"] as? Double
    let filled = json["filled"] as? Double ?? 0
    let statusRaw = json["status"] as? String ?? "open"
    let status = OrderStatus(rawValue: statusRaw) ?? .open
    let timestamp = (json["time"] as? Int).map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? Date()
    
    let order = Order(oid: oid, cloid: cloid, asset: asset, side: side, orderType: .limit, size: size, price: price, filled: filled, status: status, timestamp: timestamp)
    return .orderUpdate(order)
  }
  
  private func parseUserFunding(_ json: [String: Any]) -> WebSocketDataType {
    guard let asset = json["asset"] as? Int,
          let payment = json["payment"] as? Double ?? (json["payment"] as? String).flatMap({ Double($0) }),
          let rate = json["rate"] as? Double ?? (json["rate"] as? String).flatMap({ Double($0) }) else {
      return .unknown
    }
    
    let time = (json["time"] as? Int).map { Date(timeIntervalSince1970: Double($0) / 1000) } ?? Date()
    
    let funding = UserFunding(asset: asset, payment: payment, rate: rate, time: time)
    return .userFunding(funding)
  }
}
