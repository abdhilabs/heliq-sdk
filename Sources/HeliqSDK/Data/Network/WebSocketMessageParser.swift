//
//  WebSocketMessageParser.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Defines web socket message values.
public enum WebSocketMessage {
  /// The `subscribe` option.
  case subscribe(channel: String, payload: [String: Any]?)
  /// The `unsubscribe` option.
  case unsubscribe(channel: String)
  /// The `channelData` option.
  case channelData(channel: String, data: Data)
  /// The `data` option.
  case data(Data)
  
  /// The channel.
  public var channel: String? {
    switch self {
    case .subscribe(let channel, _):
      return channel
    case .unsubscribe(let channel):
      return channel
    case .channelData(let channel, _):
      return channel
    case .data:
      return nil
    }
  }
}

/// Provides web socket message parser functionality.
public final class WebSocketMessageParser {
  /// Creates a web socket message parser.
  public init() {}
  
  /// Performs the parse operation.
  public func parse(_ data: Data) throws -> WebSocketMessage {
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw ValidationError.malformedData(reason: "Invalid JSON")
    }
    
    if let method = json["method"] as? String {
      switch method {
      case "subscribe":
        let channel = json["channel"] as? String ?? ""
        let payload = json["payload"] as? [String: Any]
        return .subscribe(channel: channel, payload: payload)
        
      case "unsubscribe":
        let channel = json["channel"] as? String ?? ""
        return .unsubscribe(channel: channel)
        
      default:
        break
      }
    }
    
    if let channel = json["channel"] as? String, let payload = json["data"] {
      let payloadData = try JSONSerialization.data(withJSONObject: payload, options: [.fragmentsAllowed])
      return .channelData(channel: channel, data: payloadData)
    }

    return .data(data)
  }
  
  /// Performs the encode operation.
  public func encode(_ message: WebSocketMessage) throws -> Data {
    var dict: [String: Any] = [:]
    
    switch message {
    case .subscribe(let channel, let payload):
      dict["method"] = "subscribe"
      dict["channel"] = channel
      if let payload = payload {
        dict["payload"] = payload
      }
      
    case .unsubscribe(let channel):
      dict["method"] = "unsubscribe"
      dict["channel"] = channel
      
    case .channelData(_, let data):
      return data

    case .data(let data):
      return data
    }
    
    return try JSONSerialization.data(withJSONObject: dict)
  }
}
