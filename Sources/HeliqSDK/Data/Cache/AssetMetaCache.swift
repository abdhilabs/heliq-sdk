//
//  AssetMetaCache.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public actor AssetMetaCache {
  private var coinToAsset: [String: Int] = [:]
  private var assetToCoin: [Int: String] = [:]
  private var lastUpdate: Date?
  
  private let ttl: TimeInterval
  
  public init(ttl: TimeInterval = Constants.Cache.assetMetaTTL) {
    self.ttl = ttl
  }
  
  public func getAsset(coin: String) -> Int? {
    guard !isExpired() else {
      Logger.shared.info("cache lookup=asset outcome=miss", category: .cache)
      return nil
    }
    let value = coinToAsset[coin]
    Logger.shared.info("cache lookup=asset outcome=\(value == nil ? "miss" : "hit")", category: .cache)
    return value
  }
  
  public func getCoin(asset: Int) -> String? {
    guard !isExpired() else {
      Logger.shared.info("cache lookup=coin outcome=miss", category: .cache)
      return nil
    }
    let value = assetToCoin[asset]
    Logger.shared.info("cache lookup=coin outcome=\(value == nil ? "miss" : "hit")", category: .cache)
    return value
  }
  
  public func setMapping(coin: String, asset: Int) {
    coinToAsset[coin] = asset
    assetToCoin[asset] = coin
    lastUpdate = Date()
  }
  
  public func setMappings(mappings: [(coin: String, asset: Int)]) {
    for mapping in mappings {
      coinToAsset[mapping.coin] = mapping.asset
      assetToCoin[mapping.asset] = mapping.coin
    }
    lastUpdate = Date()
  }
  
  public func invalidate() {
    coinToAsset.removeAll()
    assetToCoin.removeAll()
    lastUpdate = nil
  }
  
  public func refresh() async {
    lastUpdate = nil
  }
  
  private func isExpired() -> Bool {
    guard let lastUpdate = lastUpdate else { return true }
    return Date().timeIntervalSince(lastUpdate) > ttl
  }
}
