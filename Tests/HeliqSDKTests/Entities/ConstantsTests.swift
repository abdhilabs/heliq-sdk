//
//  ConstantsTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct ConstantsTests {
  @Test func testMainnetBaseURL_returnsCorrectURL() throws {
    #expect(Constants.API.mainnetBaseURL == "https://api.hyperliquid.xyz")
  }
  
  @Test func testTestnetBaseURL_returnsCorrectURL() throws {
    #expect(Constants.API.testnetBaseURL == "https://api.hyperliquid-testnet.xyz")
  }
  
  @Test func testLocalBaseURL_returnsCorrectURL() throws {
    #expect(Constants.API.localBaseURL == "http://localhost:3000")
  }
  
  @Test func testBaseURLForEnvironment_mainnet_returnsMainnetURL() throws {
    #expect(Constants.API.baseURL(for: .mainnet) == "https://api.hyperliquid.xyz")
  }
  
  @Test func testBaseURLForEnvironment_testnet_returnsTestnetURL() throws {
    #expect(Constants.API.baseURL(for: .testnet) == "https://api.hyperliquid-testnet.xyz")
  }
  
  @Test func testBaseURLForEnvironment_local_returnsLocalURL() throws {
    #expect(Constants.API.baseURL(for: .local) == "http://localhost:3000")
  }
  
  @Test func testInfoEndpoint_returnsCorrectPath() throws {
    #expect(Constants.API.infoEndpoint == "/info")
  }
  
  @Test func testTradeEndpoint_returnsCorrectPath() throws {
    #expect(Constants.API.tradeEndpoint == "/trade")
  }
  
  @Test func testWebSocketMainnetURL_returnsCorrectURL() throws {
    #expect(Constants.WebSocket.mainnetURL == "wss://api.hyperliquid.xyz/ws")
  }
  
  @Test func testWebSocketTestnetURL_returnsCorrectURL() throws {
    #expect(Constants.WebSocket.testnetURL == "wss://api.hyperliquid-testnet.xyz/ws")
  }
  
  @Test func testWebSocketLocalURL_returnsCorrectURL() throws {
    #expect(Constants.WebSocket.localURL == "ws://localhost:3000/ws")
  }
  
  @Test func testWebSocketPingInterval_returns50Seconds() throws {
    #expect(Constants.WebSocket.pingInterval == 50.0)
  }
  
  @Test func testWebSocketPongTimeout_returns10Seconds() throws {
    #expect(Constants.WebSocket.pongTimeout == 10.0)
  }
  
  @Test func testRateLimitingDefaultRequestsPerWindow_returns100() throws {
    #expect(Constants.RateLimiting.defaultRequestsPerWindow == 100)
  }
  
  @Test func testRateLimitingDefaultWindowDuration_returns10Seconds() throws {
    #expect(Constants.RateLimiting.defaultWindowDuration == 10.0)
  }
  
  @Test func testRetryMaxRetries_returns3() throws {
    #expect(Constants.Retry.maxRetries == 3)
  }
  
  @Test func testRetryBaseDelay_returns1Second() throws {
    #expect(Constants.Retry.baseDelay == 1.0)
  }
  
  @Test func testRetryMultiplier_returns2() throws {
    #expect(Constants.Retry.multiplier == 2.0)
  }
  
  @Test func testCacheAssetMetaTTL_returns3600Seconds() throws {
    #expect(Constants.Cache.assetMetaTTL == 3600.0)
  }
  
  @Test func testHeliqEnvironment_mainnet_caseMatches() throws {
    #expect(HeliqEnvironment.mainnet == HeliqEnvironment.mainnet)
  }
  
  @Test func testHeliqEnvironment_testnet_caseMatches() throws {
    #expect(HeliqEnvironment.testnet == HeliqEnvironment.testnet)
  }
  
  @Test func testHeliqEnvironment_local_caseMatches() throws {
    #expect(HeliqEnvironment.local == HeliqEnvironment.local)
  }
}
