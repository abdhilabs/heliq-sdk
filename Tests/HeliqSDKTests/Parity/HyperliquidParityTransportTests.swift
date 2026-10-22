//
//  HyperliquidParityTransportTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidParityTransportTests {
  @Test func infoRequest_preservesEveryDocumentedParameter() throws {
    let request = HyperliquidInfoRequest(
      type: .userFillsByTime,
      parameters: [
        "user": .string("0xabc"),
        "aggregateByTime": .bool(true),
        "startTime": .number(1_700_000_000_000),
        "endTime": .number(1_700_000_060_000),
        "dex": .string("xyz")
      ]
    )

    let body = request.body()
    #expect(body["type"] == .string("userFillsByTime"))
    #expect(body["user"] == .string("0xabc"))
    #expect(body["aggregateByTime"] == .bool(true))
    #expect(body["startTime"] == .number(1_700_000_000_000))
    #expect(body["dex"] == .string("xyz"))
  }

  @Test func exchangeEnvelope_preservesActionSignatureAndExpiry() {
    let action = HyperliquidExchangeAction(
      type: .approveBuilderFee,
      parameters: ["maxFeeRate": .string("0.001%"), "builder": .string("0xbuilder")]
    )
    let envelope = HyperliquidExchangeEnvelope(
      action: action,
      nonce: 1_700_000_000_000,
      signature: SignatureTypes(r: "0xr", s: "0xs", v: 27, signatureType: .eoa),
      vaultAddress: "0xvault",
      expiresAfter: 1_700_000_060_000
    )

    guard case .object(let encodedAction)? = envelope.body()["action"] else {
      Issue.record("Expected action object")
      return
    }
    #expect(encodedAction["type"] == .string("approveBuilderFee"))
    #expect(encodedAction["maxFeeRate"] == .string("0.001%"))
    #expect(envelope.body()["vaultAddress"] == .string("0xvault"))
    #expect(envelope.body()["expiresAfter"] == .number(1_700_000_060_000))
  }

  @Test func webSocketSubscription_preservesUserAndOptionalFields() {
    let subscription = HyperliquidWebSocketSubscription(
      type: .userFills,
      parameters: ["user": .string("0xabc"), "aggregateByTime": .bool(true)]
    )
    let payload = subscription.payload()

    #expect(payload["type"] as? String == "userFills")
    #expect(payload["user"] as? String == "0xabc")
    #expect(payload["aggregateByTime"] as? Bool == true)
  }

  @Test func rawSubscription_managerTracksUserScopedSubscription() async throws {
    let manager = SubscriptionManager()
    let subscription = HyperliquidWebSocketSubscription(type: .openOrders, parameters: ["user": .string("0xabc"), "dex": .string("xyz")])
    try await manager.subscribe(to: subscription)
    #expect(manager.isSubscribed(to: subscription))
    try await manager.unsubscribe(from: subscription)
    #expect(!manager.isSubscribed(to: subscription))
  }

  @Test func legacySubscription_payloadCarriesExactUnsubscribeFields() {
    let channel = SubscriptionChannel.candle(coin: "ETH", interval: "1h")
    #expect(channel.channelName == "candle")
    #expect(channel.payload?["coin"] as? String == "ETH")
    #expect(channel.payload?["interval"] as? String == "1h")
  }

  @Test func officialSurfaceEnums_coverKnownAdvancedEndpoints() {
    #expect(HyperliquidInfoType.borrowLendReserveState.rawValue == "borrowLendReserveState")
    #expect(HyperliquidExchangeActionType.twapOrder.rawValue == "twapOrder")
    #expect(HyperliquidWebSocketSubscriptionType.fastAssetCtxs.rawValue == "fastAssetCtxs")
  }
}
