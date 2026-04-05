//
//  TransactionBuilder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class TransactionBuilder: @unchecked Sendable {
  public init() {}
  
  public func buildOrderTransaction(
    order: OrderRequest,
    vaultAddress: String? = nil
  ) throws -> [String: Any] {
    var transaction: [String: Any] = [
      "type": "order",
      "asset": order.asset,
      "side": order.side.rawValue,
      "size": order.size,
      "reduceOnly": order.reduceOnly
    ]
    
    switch order.orderType {
    case .market:
      transaction["orderType"] = ["type": "market"]
    case .limit:
      if let price = order.price {
        transaction["orderType"] = ["type": "limit", "price": price]
      }
    case .triggerMarket(let trigger):
      let triggerDict: [String: Any] = [
        "triggerPx": trigger.triggerPx,
        "tpsl": trigger.tpsl
      ]
      transaction["orderType"] = [
        "type": "triggerMarket",
        "trigger": triggerDict
      ]
    case .triggerLimit(let trigger):
      if let price = order.price {
        let triggerDict: [String: Any] = [
          "triggerPx": trigger.triggerPx,
          "tpsl": trigger.tpsl
        ]
        transaction["orderType"] = [
          "type": "triggerLimit",
          "price": price,
          "trigger": triggerDict
        ]
      }
    }
    
    if let cloid = order.cloid {
      transaction["cloid"] = cloid
    }
    
    if let vaultAddress = vaultAddress {
      transaction["vaultAddress"] = vaultAddress
    }
    
    return transaction
  }
  
  public func buildCancelTransaction(orderId: String, asset: Int) -> [String: Any] {
    [
      "type": "cancel",
      "oid": orderId,
      "asset": asset
    ]
  }
  
  public func buildCancelByCloidTransaction(cloid: String, asset: Int) -> [String: Any] {
    [
      "type": "cancelByCloid",
      "cloid": cloid,
      "asset": asset
    ]
  }
  
  public func buildCancelAllTransaction(asset: Int? = nil) -> [String: Any] {
    var transaction: [String: Any] = ["type": "cancelAll"]
    if let asset = asset {
      transaction["asset"] = asset
    }
    return transaction
  }
  
  public func buildSetLeverageTransaction(asset: Int, leverage: Int) -> [String: Any] {
    [
      "type": "setLeverage",
      "asset": asset,
      "leverage": leverage
    ]
  }
}
