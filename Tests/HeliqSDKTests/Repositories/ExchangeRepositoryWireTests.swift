//
//  ExchangeRepositoryWireTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import Testing

@testable import HeliqSDK

@Suite(.serialized)
struct ExchangeRepositoryWireTests {
  private let address = "0x1234567890123456789012345678901234567890"
  private let cloid = "0x1234567890abcdef1234567890abcdef"
  private let metadata =
    #"{"universe":[{"name":"BTC","szDecimals":5},{"name":"ETH","szDecimals":4}]}"#
  private let defaultResponse = #"{"status":"ok","response":{"type":"default"}}"#

  private func repository(
    response: String, expected: [String: JSONValue], info: [String: String] = [:],
    orderStatuses: [String] = []
  ) -> ExchangeRepositoryImpl {
    let sequence = OrderStatusSequence(orderStatuses)
    ExchangeWireProtocol.handler = { request in
      var data = request.httpBody ?? Data()
      if let stream = request.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
          let count = stream.read(&buffer, maxLength: buffer.count)
          if count < 0 { throw stream.streamError ?? APIError.invalidResponse }
          if count == 0 { break }
          data.append(contentsOf: buffer.prefix(count))
        }
      }
      let body = try JSONDecoder().decode([String: JSONValue].self, from: data)
      if request.url?.path == "/info", case .string(let type) = body["type"] {
        if type == "orderStatus", let response = sequence.next() { return Data(response.utf8) }
        if let fixture = info[type] { return Data(fixture.utf8) }
        if type == "userAbstraction" { return Data("\"standard\"".utf8) }
      }
      #expect(request.url?.path == "/exchange")
      guard case .object(let action) = body["action"], case .number(let nonce) = body["nonce"],
        case .object(let signature) = body["signature"]
      else { throw APIError.invalidResponse }
      #expect(nonce > 0)
      #expect(signature.keys.sorted() == ["r", "s", "v"])
      #expect(
        action
          == expected.merging(
            action.filter {
              ["time", "nonce", "signatureChainId", "hyperliquidChain"].contains($0.key)
            }
          ) { a, _ in a })
      if action["signatureChainId"] != nil {
        #expect(action["signatureChainId"] == .string("0x66eee"))
        #expect(action["hyperliquidChain"] == .string("Testnet"))
        #expect(action["time"] == .number(nonce) || action["nonce"] == .number(nonce))
      }
      return Data(response.utf8)
    }
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [ExchangeWireProtocol.self]
    return ExchangeRepositoryImpl(
      apiClient: APIClient(environment: .testnet, session: URLSession(configuration: config)),
      wallet: FixtureWallet(address: address))
  }

  private func orderWire(tif: String = "Gtc", price: String = "50000") -> JSONValue {
    .object([
      "a": .number(0), "b": .bool(true), "p": .string(price), "s": .string("0.001"),
      "r": .bool(false), "t": .object(["limit": .object(["tif": .string(tif)])]),
      "c": .string(cloid),
    ])
  }

  @Test func limitMarketAndBulkUseSignedOrderEnvelope() async throws {
    for market in [false, true] {
      let repo = repository(
        response:
          #"{"status":"ok","response":{"type":"order","data":{"statuses":[{"resting":{"oid":123}}]}}}"#,
        expected: [
          "type": .string("order"),
          "orders": .array([
            orderWire(tif: market ? "Ioc" : "Gtc", price: market ? "52500" : "50000")
          ]), "grouping": .string("na"),
        ],
        info: ["meta": metadata, "allMids": #"{"BTC":"50000"}"#])
      let response = try await repo.placeOrder(
        .init(
          asset: 0, side: .buy, orderType: market ? .market : .limit, size: 0.001,
          price: market ? nil : 50000, cloid: cloid))
      #expect(response.orderId == "123")
      #expect(response.status == "resting")
    }
    let order = OrderRequest(
      asset: 0, side: .buy, orderType: .limit, size: 0.001, price: 50000, cloid: cloid)
    let repo = repository(
      response:
        #"{"status":"ok","response":{"type":"order","data":{"statuses":[{"filled":{"oid":124,"totalSz":"0.001","avgPx":"49999"}},{"error":"Insufficient margin"}]}}}"#,
      expected: [
        "type": .string("order"), "orders": .array([orderWire(), orderWire()]),
        "grouping": .string("na"),
      ])
    let result = try await repo.bulkOrders([order, order])
    #expect(result.responses[0].filledPx == 49999)
    #expect(result.responses[1].error == "Insufficient margin")
  }

  @Test func triggerOrdersEncodeTriggerSchemaAndRejectInvalidConditions() async throws {
    for market in [false, true] {
      let trigger: JSONValue = .object([
        "trigger": .object([
          "isMarket": .bool(market), "triggerPx": .string("49000"), "tpsl": .string("sl"),
        ])
      ])
      let wire: JSONValue = .object([
        "a": .number(0), "b": .bool(false), "p": .string("48000"), "s": .string("0.001"),
        "r": .bool(true), "t": trigger,
      ])
      let repo = repository(
        response:
          #"{"status":"ok","response":{"type":"order","data":{"statuses":["waitingForTrigger"]}}}"#,
        expected: ["type": .string("order"), "orders": .array([wire]), "grouping": .string("na")])
      let params = TriggerParams(triggerPx: 49000, tpsl: "sl")
      let result = try await repo.placeOrder(
        .init(
          asset: 0, side: .sell, orderType: market ? .triggerMarket(params) : .triggerLimit(params),
          size: 0.001, price: 48000, reduceOnly: true))
      #expect(result.status == "waitingForTrigger")
    }
    let repo = repository(response: defaultResponse, expected: [:])
    await #expect(throws: ValidationError.self) {
      try await repo.placeOrder(
        .init(
          asset: 0, side: .sell,
          orderType: .triggerMarket(.init(triggerPx: 49000, tpsl: "invalid")), size: 0.001,
          price: 48000))
    }
  }

  @Test func cancelEncodesNumericIDsAndCloidsAndMapsFailures() async throws {
    let success = #"{"status":"ok","response":{"type":"cancel","data":{"statuses":["success"]}}}"#
    let repo = repository(
      response: success,
      expected: [
        "type": .string("cancel"),
        "cancels": .array([.object(["a": .number(0), "o": .number(123)])]),
      ])
    #expect(try await repo.cancelOrder(orderId: "123", asset: 0).status == "success")
    let byCloid = repository(
      response: success,
      expected: [
        "type": .string("cancelByCloid"),
        "cancels": .array([.object(["asset": .number(0), "cloid": .string(cloid)])]),
      ])
    #expect(try await byCloid.cancelByCloid(cloid: cloid, asset: 0).status == "success")
    let failure = repository(
      response:
        #"{"status":"ok","response":{"type":"cancel","data":{"statuses":[{"error":"Already filled"}]}}}"#,
      expected: [
        "type": .string("cancel"),
        "cancels": .array([.object(["a": .number(0), "o": .number(123)])]),
      ])
    #expect(try await failure.cancelOrder(orderId: "123", asset: 0).error == "Already filled")
  }

  @Test func leverageAndMarginPreserveTheOtherSetting() async throws {
    for margin in [false, true] {
      let repo = repository(
        response: defaultResponse,
        expected: [
          "type": .string("updateLeverage"), "asset": .number(0), "isCross": .bool(margin),
          "leverage": .number(margin ? 7 : 3),
        ],
        info: ["meta": metadata, "activeAssetData": #"{"leverage":{"type":"isolated","value":7}}"#])
      if margin {
        #expect(try await repo.setMarginMode(asset: 0, mode: .cross).status == "ok")
      } else {
        #expect(try await repo.setLeverage(asset: 0, leverage: 3).leverage == 3)
      }
    }
  }

  @Test func transfersUseUserSignedSchemasAndResolveSpotToken() async throws {
    let expected: [String: JSONValue] = [
      "type": .string("usdSend"), "destination": .string(address), "amount": .string("1.23"),
    ]
    #expect(
      try await repository(response: defaultResponse, expected: expected).usdSend(
        destination: address, amount: 1.23
      ).status == "ok")
    #expect(
      try await repository(response: defaultResponse, expected: expected).transfer(
        fromAddress: address, toAddress: address, amount: 1.23, asset: 0
      ).status == "ok")
    #expect(
      try await repository(response: defaultResponse, expected: expected).sendToAddress(
        address: address, amount: 1.23, asset: 0
      ).status == "ok")
    let repo = repository(
      response: defaultResponse,
      expected: [
        "type": .string("spotSend"), "destination": .string(address), "amount": .string("1.23"),
        "token": .string("USDC:0x1234"),
      ], info: ["spotMeta": #"{"tokens":[{"index":0,"name":"USDC","tokenId":"0x1234"}]}"#])
    #expect(try await repo.spotTransfer(toAddress: address, amount: 1.23, asset: 0).status == "ok")
  }

  @Test func unifiedTransfersUseSendAssetWithCorrectDestinationLedger() async throws {
    for spot in [false, true] {
      let expected: [String: JSONValue] = [
        "type": .string("sendAsset"), "destination": .string(address), "sourceDex": .string("spot"),
        "destinationDex": .string(spot ? "spot" : ""), "token": .string("USDC:0x1234"),
        "amount": .string("1.23"), "fromSubAccount": .string(""),
      ]
      let repo = repository(
        response: defaultResponse, expected: expected,
        info: [
          "userAbstraction": "\"unifiedAccount\"",
          "spotMeta": #"{"tokens":[{"index":0,"name":"USDC","tokenId":"0x1234"}]}"#,
        ])
      if spot {
        #expect(
          try await repo.spotTransfer(toAddress: address, amount: 1.23, asset: 0).status == "ok")
      } else {
        #expect(try await repo.usdSend(destination: address, amount: 1.23).status == "ok")
      }
    }
  }

  @Test func vaultUsesMicroUsdcAndCorrectDirection() async throws {
    for deposit in [false, true] {
      let repo = repository(
        response: defaultResponse,
        expected: [
          "type": .string("vaultTransfer"), "vaultAddress": .string(address),
          "isDeposit": .bool(deposit), "usd": .number(1_230_000),
        ])
      #expect(
        try await repo.vaultTransfer(
          vaultTransfer: .init(
            fromVault: !deposit, toVault: deposit, usdcAmount: 1.23, vaultAddress: address)
        ).status == "ok")
    }
  }

  @Test func builderAndReferralUseOfficialActions() async throws {
    let builder = repository(
      response: defaultResponse,
      expected: [
        "type": .string("approveBuilderFee"), "builder": .string(address),
        "maxFeeRate": .string("0.01%"),
      ])
    #expect(
      try await builder.updateBuilder(builderAddress: address, maxFeeRate: "0.01%").status == "ok")
    let referral = repository(
      response: defaultResponse,
      expected: ["type": .string("setReferrer"), "code": .string("EXAMPLE")])
    #expect(try await referral.setReferrer(referrer: "EXAMPLE").status == "ok")
  }

  @Test func cancelAllCancelsOnlyReturnedOrdersAndPreservesPartialFailures() async throws {
    let expected: [String: JSONValue] = [
      "type": .string("cancel"),
      "cancels": .array([
        .object(["a": .number(0), "o": .number(123)]),
        .object(["a": .number(1), "o": .number(124)]),
      ]),
    ]
    let repo = repository(
      response:
        #"{"status":"ok","response":{"type":"cancel","data":{"statuses":["success",{"error":"Already filled"}]}}}"#,
      expected: expected,
      info: [
        "meta": metadata,
        "openOrders":
          #"[{"coin":"BTC","limitPx":"50000","oid":123,"side":"B","sz":"0.001","timestamp":1700000000000},{"coin":"ETH","limitPx":"3000","oid":124,"side":"A","sz":"1","timestamp":1700000000000}]"#,
      ])
    let result = try await repo.cancelAll()
    #expect(result.cancelledOrders == ["123"])
    #expect(result.failedCancels.first?.orderId == "124")
    #expect(
      try await repository(response: defaultResponse, expected: [:], info: ["openOrders": "[]"])
        .cancelAll().cancelledOrders.isEmpty)
  }

  @Test func modifyPreservesOrderSideReduceOnlyAndTimeInForce() async throws {
    for byCloid in [false, true] {
      let existing =
        #"{"status":"order","order":{"status":"open","statusTimestamp":1700000000000,"order":{"coin":"BTC","side":"A","limitPx":"50000","sz":"0.001","oid":123,"timestamp":1700000000000,"triggerCondition":"N/A","isTrigger":false,"triggerPx":"0","isPositionTpsl":false,"reduceOnly":true,"orderType":"Limit","origSz":"0.001","tif":"Alo","cloid":null}}}"#
      let wire: JSONValue = .object([
        "a": .number(0), "b": .bool(false), "p": .string("51000"), "s": .string("0.001"),
        "r": .bool(true), "t": .object(["limit": .object(["tif": .string("Alo")])]),
      ])
      let repo = repository(
        response:
          #"{"status":"ok","response":{"type":"order","data":{"statuses":[{"resting":{"oid":125}}]}}}"#,
        expected: [
          "type": .string("batchModify"),
          "modifies": .array([
            .object(["oid": byCloid ? .string(cloid) : .number(123), "order": wire])
          ]),
        ],
        info: [
          "meta": metadata, "orderStatus": existing,
          "frontendOpenOrders": "[{\"cloid\":\"\(cloid)\",\"oid\":123}]",
        ],
        orderStatuses: byCloid
          ? [
            existing.replacingOccurrences(
              of: "\"status\":\"open\"", with: "\"status\":\"canceled\""), existing,
          ] : [])
      let result =
        byCloid
        ? try await repo.modifyByCloid(cloid: cloid, asset: 0, size: nil, price: 51000)
        : try await repo.modifyOrder(orderId: "123", asset: 0, size: nil, price: 51000)
      #expect(result.orderId == "125")
    }
  }

  @Test func rawMultisigActionUsesOfficialDiscriminator() {
    #expect(
      HyperliquidExchangeAction(type: .convertToMultiSig).body()["type"]
        == .string("convertToMultiSigUser"))
  }

  @Test func scheduleAndMultisigEncodeExplicitParameters() async throws {
    let time = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + 60).rounded(.down))
    let schedule = repository(
      response: defaultResponse,
      expected: [
        "type": .string("scheduleCancel"), "time": .number(time.timeIntervalSince1970 * 1000),
      ])
    #expect(try await schedule.scheduleCancel(time: time).scheduledTime == time)
    let encoder = JSONEncoder()
    let signers = String(
      decoding: try encoder.encode([
        "authorizedUsers": JSONValue.array([.string(address)]), "threshold": .number(1),
      ]), as: UTF8.self)
    // Compare decoded signer JSON; object key order is irrelevant inside the signed string.
    ExchangeWireProtocol.handler = { request in
      var data = request.httpBody ?? Data()
      if let stream = request.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 4096)
        while stream.hasBytesAvailable {
          let n = stream.read(&buffer, maxLength: buffer.count)
          guard n >= 0 else { throw APIError.invalidResponse }
          if n == 0 { break }
          data.append(contentsOf: buffer.prefix(n))
        }
      }
      let body = try JSONDecoder().decode([String: JSONValue].self, from: data)
      guard case .object(let action) = body["action"], case .string(let encoded) = action["signers"]
      else { throw APIError.invalidResponse }
      #expect(action["type"] == .string("convertToMultiSigUser"))
      #expect(
        try JSONDecoder().decode(JSONValue.self, from: Data(encoded.utf8))
          == JSONDecoder().decode(JSONValue.self, from: Data(signers.utf8)))
      #expect(action["nonce"] == body["nonce"])
      return Data(self.defaultResponse.utf8)
    }
    #expect(
      try await schedule.convertToMultiSigUser(authorizedUsers: [address], threshold: 1).status
        == "ok")
  }

  @Test func exchangeRejectionsAndMalformedResponsesAreErrors() async throws {
    let order = OrderRequest(
      asset: 0, side: .buy, orderType: .limit, size: 0.001, price: 50000, cloid: cloid)
    let expected: [String: JSONValue] = [
      "type": .string("order"), "orders": .array([orderWire()]), "grouping": .string("na"),
    ]
    for response in [
      #"{"status":"err","response":"Invalid signature"}"#,
      #"{"status":"ok","response":{"type":"order","data":{"statuses":[{"error":"Insufficient margin"}]}}}"#,
      #"{"status":"ok","response":{"type":"order","data":{"statuses":[]}}}"#,
      #"{"status":"ok","response":{"type":"cancel","data":{"statuses":[{"resting":{"oid":123}}]}}}"#,
    ] {
      await #expect(throws: APIError.self) {
        try await repository(response: response, expected: expected).placeOrder(order)
      }
    }
  }

  @Test func malformedInputsNeverReachExchange() async throws {
    let repo = repository(response: defaultResponse, expected: [:])
    await #expect(throws: ValidationError.self) {
      try await repo.cancelOrder(orderId: "9007199254740993", asset: 0)
    }
    await #expect(throws: ValidationError.self) {
      try await repo.cancelByCloid(cloid: "0x123", asset: 0)
    }
    await #expect(throws: ValidationError.self) {
      try await repo.usdSend(destination: address, amount: .nan)
    }
    await #expect(throws: ValidationError.self) {
      try await repo.usdSend(destination: "invalid", amount: 1)
    }
    await #expect(throws: ValidationError.self) {
      try await repo.updateBuilder(builderAddress: address)
    }
    await #expect(throws: ValidationError.self) { try await repo.convertToMultiSigUser() }
    await #expect(throws: ValidationError.self) {
      try await repo.convertToMultiSigUser(authorizedUsers: [address, address], threshold: 1)
    }
    await #expect(throws: ValidationError.self) { try await repo.scheduleCancel(time: Date()) }
    await #expect(throws: ValidationError.self) {
      try await repo.vaultTransfer(
        vaultTransfer: .init(fromVault: true, toVault: true, usdcAmount: 1, vaultAddress: address))
    }
  }

  @Test func messagePackSupportsAddressesCloidsAndLargeBatches() throws {
    let long = String(repeating: "a", count: 42)
    let encoded = try CanonicalMessagePack.encode(
      .init([("value", .string(long)), ("orders", .array(Array(repeating: .null, count: 16)))]))
    let expected = Data(
      [0x82, 0xa5] + Array("value".utf8) + [0xd9, 42] + Array(long.utf8) + [0xa6]
        + Array("orders".utf8) + [0xdc, 0, 16] + Array(repeating: 0xc0, count: 16))
    #expect(encoded == expected)
    #expect(throws: ValidationError.self) {
      try CanonicalMessagePack.encode(.init([("overflow", .number(Double(UInt64.max)))]))
    }
  }

  @Test func nativeWalletDelegatesBothSigningSchemesWithoutGenericMessageSigning() async throws {
    let key = "0x0123456789012345678901234567890123456789012345678901234567890123"
    let wallet = try await WalletService(keyManager: KeyManager(privateKey: key))
    let signer = try Signer(privateKey: key)
    #expect(wallet.address == signer.address)
    let action = CanonicalMessagePack.Object([
      ("type", .string("cancel")),
      ("cancels", .array([.object(.init([("a", .number(0)), ("o", .number(123))]))])),
    ])
    let expected = try await signer.signL1(action: action, nonce: 1, isMainnet: false)
    let actual = try await wallet.signL1(action: action, nonce: 1, isMainnet: false)
    #expect(actual.r == expected.r && actual.s == expected.s && actual.v == expected.v)
    let fields: [HyperliquidEIP712Field] = [
      .init(name: "hyperliquidChain", type: "string"), .init(name: "destination", type: "string"),
      .init(name: "amount", type: "string"), .init(name: "time", type: "uint64"),
    ]
    let message: [String: JSONValue] = [
      "destination": .string(address), "amount": .string("1"), "time": .number(1),
    ]
    let userExpected = try await signer.signUserSigned(
      primaryType: "HyperliquidTransaction:UsdSend", fields: fields, action: message,
      isMainnet: false)
    let userActual = try await wallet.signUserSigned(
      primaryType: "HyperliquidTransaction:UsdSend", fields: fields, action: message,
      isMainnet: false)
    #expect(
      userActual.r == userExpected.r && userActual.s == userExpected.s
        && userActual.v == userExpected.v)
  }

  private struct FixtureWallet: WalletServiceProtocol {
    let address: String
    func sign(message: String) async throws -> SignatureTypes { throw SigningError.keyNotFound }
    func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws
      -> SignatureTypes
    {
      #expect(!isMainnet)
      _ = try Signer.actionHash(action: action, nonce: nonce)
      return .init(r: "0x1", s: "0x2", v: 27, signatureType: .eoa)
    }
    func signUserSigned(
      primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue],
      isMainnet: Bool
    ) async throws -> SignatureTypes {
      #expect(!isMainnet)
      #expect(primaryType.hasPrefix("HyperliquidTransaction:"))
      #expect(fields.first?.name == "hyperliquidChain")
      return .init(r: "0x1", s: "0x2", v: 27, signatureType: .eoa)
    }
  }
}

private final class ExchangeWireProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> Data)?
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let data = try Self.handler!(request)
      client?.urlProtocol(
        self,
        didReceive: HTTPURLResponse(
          url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!,
        cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}

private final class OrderStatusSequence: @unchecked Sendable {
  private let lock = NSLock()
  private var responses: [String]
  init(_ responses: [String]) { self.responses = responses }
  func next() -> String? {
    lock.lock()
    defer { lock.unlock() }
    return responses.isEmpty ? nil : responses.removeFirst()
  }
}
