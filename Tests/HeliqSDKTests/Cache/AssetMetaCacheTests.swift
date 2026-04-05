//
//  AssetMetaCacheTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct AssetMetaCacheTests {
  
  @Test
  func testGetAsset_withValidCoin_returnsAsset() async {
    let cache = AssetMetaCache(ttl: 60)
    
    await cache.setMapping(coin: "BTC", asset: 1)
    await cache.setMapping(coin: "ETH", asset: 2)
    
    let asset = await cache.getAsset(coin: "BTC")
    #expect(asset == 1)
  }
  
  @Test
  func testGetAsset_withNonExistentCoin_returnsNil() async {
    let cache = AssetMetaCache(ttl: 60)
    
    await cache.setMapping(coin: "BTC", asset: 1)
    
    let asset = await cache.getAsset(coin: "ETH")
    #expect(asset == nil)
  }
  
  @Test
  func testGetAsset_withExpiredCache_returnsNil() async {
    let cache = AssetMetaCache(ttl: 0)
    
    await cache.setMapping(coin: "BTC", asset: 1)
    
    try? await Task.sleep(for: .milliseconds(10))
    
    let asset = await cache.getAsset(coin: "BTC")
    #expect(asset == nil)
  }
  
  @Test
  func testGetCoin_withValidAsset_returnsCoin() async {
    let cache = AssetMetaCache(ttl: 60)
    
    await cache.setMapping(coin: "BTC", asset: 1)
    
    let coin = await cache.getCoin(asset: 1)
    #expect(coin == "BTC")
  }
  
  @Test
  func testGetCoin_withNonExistentAsset_returnsNil() async {
    let cache = AssetMetaCache(ttl: 60)
    
    await cache.setMapping(coin: "BTC", asset: 1)
    
    let coin = await cache.getCoin(asset: 2)
    #expect(coin == nil)
  }
  
  @Test
  func testGetCoin_withExpiredCache_returnsNil() async {
    let cache = AssetMetaCache(ttl: 0)
    
    await cache.setMapping(coin: "BTC", asset: 1)
    
    try? await Task.sleep(for: .milliseconds(10))
    
    let coin = await cache.getCoin(asset: 1)
    #expect(coin == nil)
  }
  
  @Test
  func testSetMapping_storesBidirectionalMapping() async {
    let cache = AssetMetaCache(ttl: 60)
    
    await cache.setMapping(coin: "BTC", asset: 1)
    
    let asset = await cache.getAsset(coin: "BTC")
    let coin = await cache.getCoin(asset: 1)
    
    #expect(asset == 1)
    #expect(coin == "BTC")
  }
  
  @Test
  func testSetMappings_storesMultipleMappings() async {
    let cache = AssetMetaCache(ttl: 60)
    
    await cache.setMappings(mappings: [
      (coin: "BTC", asset: 1),
      (coin: "ETH", asset: 2),
      (coin: "SOL", asset: 3)
    ])
    
    let btc = await cache.getAsset(coin: "BTC")
    let eth = await cache.getAsset(coin: "ETH")
    let sol = await cache.getAsset(coin: "SOL")
    
    #expect(btc == 1)
    #expect(eth == 2)
    #expect(sol == 3)
  }
  
  @Test
  func testInvalidate_clearsAllMappings() async {
    let cache = AssetMetaCache(ttl: 60)
    
    await cache.setMappings(mappings: [
      (coin: "BTC", asset: 1),
      (coin: "ETH", asset: 2)
    ])
    
    await cache.invalidate()
    
    let btc = await cache.getAsset(coin: "BTC")
    let eth = await cache.getCoin(asset: 2)
    
    #expect(btc == nil)
    #expect(eth == nil)
  }
  
  @Test
  func testRefresh_setsLastUpdateToNil() async {
    let cache = AssetMetaCache(ttl: 60)
    
    await cache.setMapping(coin: "BTC", asset: 1)
    
    await cache.refresh()
    
    let asset = await cache.getAsset(coin: "BTC")
    #expect(asset == nil)
  }
}
