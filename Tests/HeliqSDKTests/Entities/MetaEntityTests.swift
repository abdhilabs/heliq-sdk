//
//  MetaEntityTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct MetaEntityTests {
  @Test func testMeta_encodeAndDecode_succeeds() throws {
    let asset = MetaAsset(
      asset: 0,
      name: "BTC",
      szDecimals: 6,
      weiDecimals: 8,
      isPerpetual: true,
      onlyIsolatedMargin: false
    )
    let spotConfig = SpotAssetConfig(tokenCfg: nil)
    let meta = Meta(universe: [asset], spotAssetConfigs: ["BTC": spotConfig])
    
    let data = try JSONCoder.encode(meta)
    let decoded = try JSONCoder.decode(Meta.self, from: data)
    
    #expect(decoded.universe.count == 1)
    #expect(decoded.spotAssetConfigs.keys.contains("BTC"))
  }
  
  @Test func testMetaAsset_id_returnsAssetValue() throws {
    let asset = MetaAsset(
      asset: 42,
      name: "ETH",
      szDecimals: 6,
      weiDecimals: 8,
      isPerpetual: true,
      onlyIsolatedMargin: false
    )
    
    #expect(asset.id == 42)
  }
  
  @Test func testMetaAsset_encodeAndDecode_succeeds() throws {
    let asset = MetaAsset(
      asset: 0,
      name: "BTC",
      szDecimals: 6,
      weiDecimals: 8,
      isPerpetual: true,
      onlyIsolatedMargin: false
    )
    
    let data = try JSONCoder.encode(asset)
    let decoded = try JSONCoder.decode(MetaAsset.self, from: data)
    
    #expect(decoded.asset == 0)
    #expect(decoded.name == "BTC")
    #expect(decoded.szDecimals == 6)
    #expect(decoded.weiDecimals == 8)
    #expect(decoded.isPerpetual == true)
    #expect(decoded.onlyIsolatedMargin == false)
  }
  
  @Test func testMetaAsset_withOnlyIsolatedMargin_encodeAndDecode_succeeds() throws {
    let asset = MetaAsset(
      asset: 1,
      name: "DOGE",
      szDecimals: 0,
      weiDecimals: 18,
      isPerpetual: true,
      onlyIsolatedMargin: true
    )
    
    let data = try JSONCoder.encode(asset)
    let decoded = try JSONCoder.decode(MetaAsset.self, from: data)
    
    #expect(decoded.onlyIsolatedMargin == true)
  }
  
  @Test func testSpotAssetConfig_withNilTokenCfg_encodeAndDecode_succeeds() throws {
    let config = SpotAssetConfig(tokenCfg: nil)
    
    let data = try JSONCoder.encode(config)
    let decoded = try JSONCoder.decode(SpotAssetConfig.self, from: data)
    
    #expect(decoded.tokenCfg == nil)
  }
  
  @Test func testSpotAssetConfig_withTokenCfg_encodeAndDecode_succeeds() throws {
    let tokenCfg = TokenConfig(name: "USD Coin", symbol: "USDC", decimals: 6)
    let config = SpotAssetConfig(tokenCfg: tokenCfg)
    
    let data = try JSONCoder.encode(config)
    let decoded = try JSONCoder.decode(SpotAssetConfig.self, from: data)
    
    #expect(decoded.tokenCfg != nil)
    #expect(decoded.tokenCfg?.symbol == "USDC")
  }
  
  @Test func testTokenConfig_encodeAndDecode_succeeds() throws {
    let tokenConfig = TokenConfig(name: "USD Coin", symbol: "USDC", decimals: 6)
    
    let data = try JSONCoder.encode(tokenConfig)
    let decoded = try JSONCoder.decode(TokenConfig.self, from: data)
    
    #expect(decoded.name == "USD Coin")
    #expect(decoded.symbol == "USDC")
    #expect(decoded.decimals == 6)
  }
  
  @Test func testBuilderInfo_encodeAndDecode_succeeds() throws {
    let builderInfo = BuilderInfo(
      builderAddress: "0x1234567890123456789012345678901234567890",
      role: .builder,
      commissionBps: 100
    )
    
    let data = try JSONCoder.encode(builderInfo)
    let decoded = try JSONCoder.decode(BuilderInfo.self, from: data)
    
    #expect(decoded.builderAddress == "0x1234567890123456789012345678901234567890")
    #expect(decoded.role == .builder)
    #expect(decoded.commissionBps == 100)
  }
  
  @Test func testBuilderRole_builder_encodeCorrectly() throws {
    #expect(BuilderRole.builder.rawValue == "Builder")
    
    let data = try JSONCoder.encode(BuilderRole.builder)
    let decoded = try JSONCoder.decode(BuilderRole.self, from: data)
    #expect(decoded == .builder)
  }
  
  @Test func testBuilderRole_router_encodeCorrectly() throws {
    #expect(BuilderRole.router.rawValue == "Router")
    
    let data = try JSONCoder.encode(BuilderRole.router)
    let decoded = try JSONCoder.decode(BuilderRole.self, from: data)
    #expect(decoded == .router)
  }
}
