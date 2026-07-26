//
//  HyperliquidInfoRequestTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidInfoRequestTests {
  @Test func openOrdersIncludesOptionalDex() throws {
    let body = try HyperliquidInfoRequest.openOrders(user: "0xabc", dex: "xyz").data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]

    #expect(object?["type"] as? String == "openOrders")
    #expect(object?["user"] as? String == "0xabc")
    #expect(object?["dex"] as? String == "xyz")
  }

  @Test func orderStatusUsesOfficialUserAndOidFields() throws {
    let body = try HyperliquidInfoRequest.orderStatus(user: "0xabc", oid: 123).data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]

    #expect(object?["type"] as? String == "orderStatus")
    #expect(object?["user"] as? String == "0xabc")
    #expect(object?["oid"] as? Int == 123)
    #expect(object?["coin"] == nil)
  }

  @Test func userFillsByTimeUsesOfficialTypeAndInclusiveBounds() throws {
    let body = try HyperliquidInfoRequest.userFillsByTime(
      user: "0xabc", startTime: Date(timeIntervalSince1970: 1), endTime: Date(timeIntervalSince1970: 2)
    ).data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]

    #expect(object?["type"] as? String == "userFillsByTime")
    #expect(object?["startTime"] as? Int == 1_000)
    #expect(object?["endTime"] as? Int == 2_000)
  }

  @Test func candleSnapshotNestsRequestUnderReq() throws {
    let body = try HyperliquidInfoRequest.candleSnapshot(
      coin: "BTC", interval: "1h", startTime: Date(timeIntervalSince1970: 1), endTime: Date(timeIntervalSince1970: 2)
    ).data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    let request = object?["req"] as? [String: Any]

    #expect(object?["type"] as? String == "candleSnapshot")
    #expect(request?["coin"] as? String == "BTC")
    #expect(request?["interval"] as? String == "1h")
    #expect(request?["startTime"] as? Int == 1_000)
    #expect(request?["endTime"] as? Int == 2_000)
  }
}
