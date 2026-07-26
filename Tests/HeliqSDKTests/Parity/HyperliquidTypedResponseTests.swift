//
//  HyperliquidTypedResponseTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidTypedResponseTests {
  @Test func decodesMetaAndAssetContextsWithoutLosingOptionalFields() throws {
    let json = #"""
    [{"universe":[{"name":"BTC","szDecimals":5,"maxLeverage":50,"onlyIsolated":true}]},[{"funding":"0.0001","markPx":"97500.5","openInterest":"123.4","midPx":null}]]
    """#

    let decoded = try HyperliquidMetaAndAssetCtxs.decode(Data(json.utf8))

    #expect(decoded.universe[0].name == "BTC")
    #expect(decoded.universe[0].onlyIsolated == true)
    #expect(decoded.assetContexts[0].markPx == "97500.5")
    #expect(decoded.assetContexts[0].midPx == nil)
  }

  @Test func pageRequestEmitsInclusiveMillisecondBounds() {
    let request = HyperliquidPageRequest(startTime: Date(timeIntervalSince1970: 1), endTime: Date(timeIntervalSince1970: 2), limit: 100)
    let parameters = request.parameters

    #expect(parameters["startTime"] == .number(1000))
    #expect(parameters["endTime"] == .number(2000))
    #expect(parameters["limit"] == .number(100))
  }

  @Test func orderStatusSupportsOfficialCancellationStates() {
    #expect(OrderStatus(rawValue: "triggered") == .triggered)
    #expect(OrderStatus(rawValue: "reduceOnlyCanceled") == .reduceOnlyCanceled)
    #expect(OrderStatus(rawValue: "siblingFilledCanceled") == .siblingFilledCanceled)
  }
}
