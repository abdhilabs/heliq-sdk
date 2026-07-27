//
//  TransactionBuilder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Provides transaction builder functionality.
public final class TransactionBuilder: @unchecked Sendable {
  /// Creates a transaction builder.
  public init() {}
  
  /// Performs the build order transaction operation.
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
  
  /// Performs the build cancel transaction operation.
  public func buildCancelTransaction(orderId: String, asset: Int) -> [String: Any] {
    [
      "type": "cancel",
      "oid": orderId,
      "asset": asset
    ]
  }
  
  /// Performs the build cancel by cloid transaction operation.
  public func buildCancelByCloidTransaction(cloid: String, asset: Int) -> [String: Any] {
    [
      "type": "cancelByCloid",
      "cloid": cloid,
      "asset": asset
    ]
  }
  
  /// Performs the build cancel all transaction operation.
  public func buildCancelAllTransaction(asset: Int? = nil) -> [String: Any] {
    var transaction: [String: Any] = ["type": "cancelAll"]
    if let asset = asset {
      transaction["asset"] = asset
    }
    return transaction
  }
  
  /// Performs the build set leverage transaction operation.
  public func buildSetLeverageTransaction(asset: Int, leverage: Int) -> [String: Any] {
    [
      "type": "setLeverage",
      "asset": asset,
      "leverage": leverage
    ]
  }
}
