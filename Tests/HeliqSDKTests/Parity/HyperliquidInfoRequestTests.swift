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
  @Test func allMidsIncludesOptionalDex() throws {
    let body = try HyperliquidInfoRequest.allMids(dex: "xyz").data()
    let object = try JSONSerialization.jsonObject(with: body) as! [String: Any]

    #expect(object["type"] as? String == "allMids")
    #expect(object["dex"] as? String == "xyz")
  }

  @Test func userFillsIncludesOptionalAggregationFlag() throws {
    let body = try HyperliquidInfoRequest.userFills(user: "0xabc", aggregateByTime: true).data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]

    #expect(object?["type"] as? String == "userFills")
    #expect(object?["user"] as? String == "0xabc")
    #expect(object?["aggregateByTime"] as? Bool == true)
  }

  @Test func l2BookIncludesOptionalPrecisionControls() throws {
    let body = try HyperliquidInfoRequest.l2Book(coin: "BTC", nSigFigs: 5, mantissa: 2).data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]

    #expect(object?["type"] as? String == "l2Book")
    #expect(object?["coin"] as? String == "BTC")
    #expect(object?["nSigFigs"] as? Int == 5)
    #expect(object?["mantissa"] as? Int == 2)
  }

  @Test func openOrdersIncludesOptionalDex() throws {
    let body = try HyperliquidInfoRequest.openOrders(user: "0xabc", dex: "xyz").data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]

    #expect(object?["type"] as? String == "openOrders")
    #expect(object?["user"] as? String == "0xabc")
    #expect(object?["dex"] as? String == "xyz")
  }

  @Test func orderStatusAcceptsOfficialClientOrderID() throws {
    let body = try HyperliquidInfoRequest.orderStatus(user: "0xabc", cloid: "0x1234").data()
    let object = try JSONSerialization.jsonObject(with: body) as! [String: Any]
    #expect(object["type"] as? String == "orderStatus")
    #expect(object["user"] as? String == "0xabc")
    #expect(object["oid"] as? String == "0x1234")
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
      user: "0xabc", startTime: Date(timeIntervalSince1970: 1.1234), endTime: Date(timeIntervalSince1970: 2.4567)
    ).data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]

    #expect(object?["type"] as? String == "userFillsByTime")
    #expect(object?["startTime"] as? Int == 1_123)
    #expect(object?["endTime"] as? Int == 2_456)
  }

  @Test func candleSnapshotNestsRequestUnderReq() throws {
    let body = try HyperliquidInfoRequest.candleSnapshot(
      coin: "BTC", interval: "1h", startTime: Date(timeIntervalSince1970: 1.1234), endTime: Date(timeIntervalSince1970: 2.4567)
    ).data()
    let object = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    let request = object?["req"] as? [String: Any]

    #expect(object?["type"] as? String == "candleSnapshot")
    #expect(request?["coin"] as? String == "BTC")
    #expect(request?["interval"] as? String == "1h")
    #expect(request?["startTime"] as? Int == 1_123)
    #expect(request?["endTime"] as? Int == 2_456)
  }
}
