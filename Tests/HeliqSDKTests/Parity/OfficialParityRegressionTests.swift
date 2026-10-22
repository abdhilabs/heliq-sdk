//
//  OfficialParityRegressionTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct OfficialParityRegressionTests {
  @Test func namedInfoTypes_coverPerpSpotAndAbstractionSurfaces() {
    #expect(HyperliquidInfoType.perpDexs.rawValue == "perpDexs")
    #expect(HyperliquidInfoType.userDexAbstraction.rawValue == "userDexAbstraction")
    #expect(HyperliquidInfoType.fundingHistory.rawValue == "fundingHistory")
    #expect(HyperliquidInfoType.spotClearinghouseState.rawValue == "spotClearinghouseState")
    #expect(HyperliquidInfoType.tokenDetails.rawValue == "tokenDetails")
    #expect(HyperliquidInfoType.settledOutcome.rawValue == "settledOutcome")
  }

  @Test func namedExchangeActions_coverCurrentOfficialSurface() {
    #expect(HyperliquidExchangeActionType.agentSetAbstraction.rawValue == "agentSetAbstraction")
    #expect(HyperliquidExchangeActionType.userOutcome.rawValue == "userOutcome")
    #expect(HyperliquidExchangeActionType.validatorL1Stream.rawValue == "validatorL1Stream")
    #expect(HyperliquidExchangeActionType.authorizeAqav2Role.rawValue == "authorizeAqav2Role")
    #expect(HyperliquidExchangeActionType.claimRewards.rawValue == "claimRewards")
  }

  @Test func parser_routesOfficialInboundChannelData() throws {
    let parser = WebSocketMessageParser()
    let input = Data("{\"channel\":\"allMids\",\"data\":{\"mids\":{\"BTC\":\"100000\"}}}".utf8)

    let parsed = try parser.parse(input)
    guard case .channelData(let channel, let data) = parsed else {
      Issue.record("Expected official channel/data message")
      return
    }
    #expect(channel == "allMids")
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    #expect((object?["mids"] as? [String: String])?["BTC"] == "100000")
  }

  @Test func webSocketPostRequest_encodesInfoAndActionEnvelopes() throws {
    let info = HyperliquidWebSocketPostRequest.info(id: 7, request: .init(type: .l2Book, parameters: ["coin": .string("ETH")]))
    let action = HyperliquidWebSocketPostRequest.action(id: 8, envelope: .init(
      action: .init(type: .claimRewards), nonce: 1,
      signature: .init(r: "0xr", s: "0xs", v: 27, signatureType: .eoa)
    ))

    let infoObject = try info.object()
    let actionObject = try action.object()
    #expect(infoObject["method"] as? String == "post")
    #expect(infoObject["id"] as? Int == 7)
    #expect(actionObject["id"] as? Int == 8)
  }
}
