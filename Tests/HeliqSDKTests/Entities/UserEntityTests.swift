//
//  UserEntityTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct UserEntityTests {
  @Test func testUserState_encodeAndDecode_succeeds() throws {
    let position = AssetPosition(
      asset: 0,
      positionSize: 1.0,
      entryPrice: 49000.0,
      unrealizedPnl: 1000.0,
      realizedPnl: 50.0,
      marginUsed: 500.0
    )
    let userState = UserState(
      accountAddress: "0x1234567890123456789012345678901234567890",
      assetPositions: [position],
      marginUsed: 500.0,
      marginTotal: 1000.0,
      marginMode: .cross,
      leverage: 10
    )
    
    let data = try JSONCoder.encode(userState)
    let decoded = try JSONCoder.decode(UserState.self, from: data)
    
    #expect(decoded.accountAddress == "0x1234567890123456789012345678901234567890")
    #expect(decoded.assetPositions.count == 1)
    #expect(decoded.marginMode == .cross)
    #expect(decoded.leverage == 10)
  }
  
  @Test func testAssetPosition_withNegativePnl_encodeAndDecode_succeeds() throws {
    let position = AssetPosition(
      asset: 1,
      positionSize: -0.5,
      entryPrice: 3000.0,
      unrealizedPnl: -100.0,
      realizedPnl: -10.0,
      marginUsed: 250.0
    )
    
    let data = try JSONCoder.encode(position)
    let decoded = try JSONCoder.decode(AssetPosition.self, from: data)
    
    #expect(decoded.unrealizedPnl == -100.0)
    #expect(decoded.realizedPnl == -10.0)
  }
  
  @Test func testMarginMode_cross_encodeCorrectly() throws {
    #expect(MarginMode.cross.rawValue == "cross")
    
    let data = try JSONCoder.encode(MarginMode.cross)
    let decoded = try JSONCoder.decode(MarginMode.self, from: data)
    #expect(decoded == .cross)
  }
  
  @Test func testMarginMode_isolated_encodeCorrectly() throws {
    #expect(MarginMode.isolated.rawValue == "isolated")
    
    let data = try JSONCoder.encode(MarginMode.isolated)
    let decoded = try JSONCoder.decode(MarginMode.self, from: data)
    #expect(decoded == .isolated)
  }
  
  @Test func testAgentType_allCases_encodeCorrectly() throws {
    #expect(AgentType.user.rawValue == "u")
    #expect(AgentType.paper.rawValue == "p")
    #expect(AgentType.info.rawValue == "i")
    
    let userData = try JSONCoder.encode(AgentType.user)
    let paperData = try JSONCoder.encode(AgentType.paper)
    let infoData = try JSONCoder.encode(AgentType.info)
    
    #expect(try JSONCoder.decode(AgentType.self, from: userData) == .user)
    #expect(try JSONCoder.decode(AgentType.self, from: paperData) == .paper)
    #expect(try JSONCoder.decode(AgentType.self, from: infoData) == .info)
  }
  
  @Test func testAgentAbstraction_encodeAndDecode_succeeds() throws {
    let agent = AgentAbstraction(agentType: .paper, address: "0x1234567890123456789012345678901234567890")
    
    let data = try JSONCoder.encode(agent)
    let decoded = try JSONCoder.decode(AgentAbstraction.self, from: data)
    
    #expect(decoded.agentType == .paper)
    #expect(decoded.address == "0x1234567890123456789012345678901234567890")
  }
  
  @Test func testAgentAbstraction_withoutAddress_encodeAndDecode_succeeds() throws {
    let agent = AgentAbstraction(agentType: .user, address: nil)
    
    let data = try JSONCoder.encode(agent)
    let decoded = try JSONCoder.decode(AgentAbstraction.self, from: data)
    
    #expect(decoded.agentType == .user)
    #expect(decoded.address == nil)
  }
  
  @Test func testUserState_withMultiplePositions_encodeAndDecode_succeeds() throws {
    let position1 = AssetPosition(asset: 0, positionSize: 1.0, entryPrice: 49000.0, unrealizedPnl: 1000.0, realizedPnl: 50.0, marginUsed: 500.0)
    let position2 = AssetPosition(asset: 1, positionSize: 2.0, entryPrice: 3000.0, unrealizedPnl: 200.0, realizedPnl: 10.0, marginUsed: 300.0)
    
    let userState = UserState(
      accountAddress: "0x1234567890123456789012345678901234567890",
      assetPositions: [position1, position2],
      marginUsed: 800.0,
      marginTotal: 2000.0,
      marginMode: .isolated,
      leverage: 5
    )
    
    let data = try JSONCoder.encode(userState)
    let decoded = try JSONCoder.decode(UserState.self, from: data)
    
    #expect(decoded.assetPositions.count == 2)
  }
}
