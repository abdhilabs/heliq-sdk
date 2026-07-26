//
//  WebSocketMessageParser.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum WebSocketMessage {
  case subscribe(channel: String, payload: [String: Any]?)
  case unsubscribe(channel: String)
  case channelData(channel: String, data: Data)
  case data(Data)
  
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

public final class WebSocketMessageParser {
  public init() {}
  
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
      let payloadData = try JSONSerialization.data(withJSONObject: payload)
      return .channelData(channel: channel, data: payloadData)
    }

    return .data(data)
  }
  
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
