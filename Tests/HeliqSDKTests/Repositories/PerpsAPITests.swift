//
//  PerpsAPITests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import Testing

@testable import HeliqSDK

@Suite(.serialized)
struct PerpsAPITests {
  let address = "0x1234567890123456789012345678901234567890"
  let meta =
    #"{"universe":[{"name":"BTC","szDecimals":5,"maxLeverage":50}],"marginTables":[[50,{"description":"","marginTiers":[{"lowerBound":"0","maxLeverage":50}]}]],"collateralToken":0}"#
  let account =
    #"{"marginSummary":{"accountValue":"90.123456789123456789","totalMarginUsed":"15","totalNtlPos":"20","totalRawUsd":"100"},"withdrawable":"75","assetPositions":[],"crossMaintenanceMarginUsed":"1"}"#
  let spot =
    #"{"balances":[{"coin":"USDC","token":0,"total":"100.123456789123456789","hold":"20"}],"tokenToAvailableAfterMaintenance":[[0,"70.123456789123456789"]]}"#
  let context =
    #"{"dayNtlVlm":"12","funding":"-0.0001","markPx":"50000","midPx":null,"openInterest":"1","oraclePx":"50000","prevDayPx":"49000","impactPxs":null}"#

  func repositories(
    mode: String = "disabled", response: String = #"{"status":"ok","response":{"type":"default"}}"#,
    observe: @escaping @Sendable ([String: JSONValue]) throws -> Void = { _ in }
  ) -> (InfoRepositoryImpl, ExchangeRepositoryImpl) {
    let meta = meta
    let account = account
    let spot = spot
    PerpsWireProtocol.handler = { request in
      let body = try JSONDecoder().decode([String: JSONValue].self, from: request.perpsTestBody())
      if request.url?.path == "/info" {
        switch body["type"] {
        case .string("userAbstraction"): return Data("\"\(mode)\"".utf8)
        case .string("spotMeta"):
          return Data(
            #"{"tokens":[{"name":"USDC","index":0,"szDecimals":6,"tokenId":"0x00000000000000000000000000000001"}],"universe":[]}"#
              .utf8)
        case .string("meta"): return Data(meta.utf8)
        case .string("clearinghouseState"): return Data(account.utf8)
        case .string("spotClearinghouseState"): return Data(spot.utf8)
        case .string("perpDexs"):
          return Data(
            #"[null,{"name":"xyz","fullName":"XYZ","deployer":"0x1234567890123456789012345678901234567890"}]"#
              .utf8)
        case .string("allMids"): return Data(#"{"BTC":"50000"}"#.utf8)
        default: throw APIError.invalidResponse
        }
      }
      try observe(body)
      return Data(response.utf8)
    }
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [PerpsWireProtocol.self]
    let client = APIClient(environment: .testnet, session: URLSession(configuration: config))
    return (
      InfoRepositoryImpl(apiClient: client),
      ExchangeRepositoryImpl(apiClient: client, wallet: PerpsTestWallet(address: address))
    )
  }

  @Test(arguments: ["disabled", "unifiedAccount", "portfolioMargin", "futureMode"])
  func balancesKeepDistinctSemantics(mode: String) async throws {
    let (info, _) = repositories(mode: mode)
    let balances = try await info.getBalances(address: address)
    #expect(balances.spot[0].total == Decimal(string: "100.123456789123456789"))
    #expect(balances.spot[0].unheld == Decimal(string: "80.123456789123456789"))
    #expect(balances.spot[0].availableAfterMaintenance == Decimal(string: "70.123456789123456789"))
    #expect(balances.spot[0].withdrawable == nil)
    #expect(balances.perps.count == 1)
    #expect(balances.perps[0].withdrawable == (mode == "disabled" ? 75 : nil))
    #expect(
      balances.perps[0].accountValue
        == (mode == "disabled" ? Decimal(string: "90.123456789123456789") : nil))
    #expect(balances.abstraction.rawValue == mode)
  }

  @Test func missingAvailabilityRemainsMissingAndDecimalsRejectGarbage() throws {
    let value = try JSONDecoder().decode(PerpsSpotState.self, from: Data(#"{"balances":[]}"#.utf8))
    #expect(value.tokenToAvailableAfterMaintenance == nil)
    #expect(throws: (any Error).self) { try perpsDecimal("1oops") }
    #expect(throws: (any Error).self) { try perpsDecimal("NaN") }
    #expect(throws: (any Error).self) {
      try perpsDecimal("123456789012345678901234567890123456789")
    }
    let pair = try JSONDecoder().decode(
      PerpsTokenAvailability.self, from: Data(#"[0,"-2.5"]"#.utf8))
    #expect(pair.value == Decimal(string: "-2.5"))
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(PerpsTokenAvailability.self, from: Data(#"[0,"1","extra"]"#.utf8))
    }
  }

  @Test func rejectsSharedCollateralClassTransferAndPreservesExactStandardAmount() async throws {
    for mode in ["unifiedAccount", "portfolioMargin", "default"] {
      let (_, exchange) = repositories(mode: mode)
      await #expect(throws: ValidationError.self) {
        try await exchange.usdClassTransfer(amount: 1, toPerp: true)
      }
    }
    let (_, exchange) = repositories(observe: { body in
      guard case .object(let action) = body["action"] else { throw APIError.invalidResponse }
      #expect(action["type"] == .string("usdClassTransfer"))
      #expect(action["amount"] == .string("1.000001"))
      #expect(action["toPerp"] == .bool(true))
      #expect(action["nonce"] == body["nonce"])
    })
    _ = try await exchange.usdClassTransfer(amount: Decimal(string: "1.000001")!, toPerp: true)
  }

  @Test func typedOrdersCarryTifGroupingBuilderAndContextAndKeepPartialErrors() async throws {
    let response =
      #"{"status":"ok","response":{"type":"order","data":{"statuses":[{"resting":{"oid":42}},{"error":"insufficient margin"}]}}}"#
    let (_, exchange) = repositories(
      response: response,
      observe: { body in
        #expect(body["vaultAddress"] == .string("0x1234567890123456789012345678901234567890"))
        #expect(body["expiresAfter"] == .number(2_000_000_000_000))
        guard case .object(let action) = body["action"], case .array(let orders) = action["orders"],
          case .object(let first) = orders[0]
        else { throw APIError.invalidResponse }
        #expect(action["grouping"] == .string("normalTpsl"))
        #expect(first["p"] == .string("50000"))
        #expect(first["s"] == .string("0.001"))
        #expect(first["t"] == .object(["limit": .object(["tif": .string("Alo")])]))
      })
    let order = PerpsOrderRequest(
      market: .coin("BTC"), side: .buy, size: Decimal(string: "0.001")!, price: 50000,
      kind: .limit(.alo))
    let result = try await exchange.executePerps(
      .orders(
        [order, order], grouping: .normalTpsl,
        builder: .init(address: address, fee: 0)),
      context: .init(
        vaultAddress: address, expiresAfter: Date(timeIntervalSince1970: 2_000_000_000)))
    guard case .orders(let statuses) = result, case .resting(let id) = statuses[0],
      case .rejected(let message) = statuses[1]
    else {
      Issue.record("Wrong order statuses")
      return
    }
    #expect(id == 42)
    #expect(message == "insufficient margin")
  }

  @Test func signedMarginAndFastCancellationWireAreExact() async throws {
    let (_, exchange) = repositories(observe: { body in
      guard case .object(let action) = body["action"] else { throw APIError.invalidResponse }
      #expect(action["ntli"] == .number(-1_000_001))
    })
    _ = try await exchange.executePerps(
      .isolatedMargin(market: .coin("BTC"), amount: Decimal(string: "-1.000001")!))
    #expect(try CanonicalMessagePack.encode(.signed(-33)) == Data([0xd0, 0xdf]))
    #expect(
      try CanonicalMessagePack.encode(.signed(-1_000_001)) == Data([0xd2, 0xff, 0xf0, 0xbd, 0xbf]))
    let (_, cancel) = repositories(
      response: #"{"status":"ok","response":{"type":"cancel","data":{"statuses":["success"]}}}"#,
      observe: { body in
        guard case .object(let action) = body["action"] else { throw APIError.invalidResponse }
        #expect(action["f"] == nil)
      })
    _ = try await cancel.executePerps(
      .cancel([.init(market: .coin("BTC"), identifier: .orderID(42))]))
  }

  @Test func largeOrderIdentifiersRemainExactInJsonAndMessagePack() async throws {
    let id: Int64 = 9_007_199_254_740_993
    let (_, exchange) = repositories(
      response: #"{"status":"ok","response":{"type":"cancel","data":{"statuses":["success"]}}}"#,
      observe: { body in
        guard case .object(let action) = body["action"],
          case .array(let cancels) = action["cancels"],
          case .object(let cancel) = cancels[0]
        else { throw APIError.invalidResponse }
        #expect(cancel["o"] == .integer(id))
      })
    _ = try await exchange.executePerps(
      .cancel([.init(market: .coin("BTC"), identifier: .orderID(id))]))
    #expect(
      try CanonicalMessagePack.encode(.signed(id)) == Data([0xcf, 0, 0x20, 0, 0, 0, 0, 0, 1]))
    let encoded = try JSONEncoder().encode(JSONValue.integer(Int64.max))
    #expect(String(decoding: encoded, as: UTF8.self) == "9223372036854775807")
    #expect(try JSONDecoder().decode(JSONValue.self, from: encoded) == .integer(Int64.max))
  }

  @Test func typedRouterDeliversFullEnvelopesAndSeparatesCoins() async throws {
    let router = WebSocketMessageRouter()
    let received = PerpsRouterResults()
    let btc = PerpsSubscription<PerpsActiveAssetData>.activeAsset(user: address, coin: "BTC")
    let eth = PerpsSubscription<PerpsActiveAssetData>.activeAsset(user: address, coin: "ETH")
    try router.registerPerpsHandler(for: btc) { result in
      Task { await received.add("BTC", result: result.map { $0.coin }) }
    }
    try router.registerPerpsHandler(for: eth) { result in
      Task { await received.add("ETH", result: result.map { $0.coin }) }
    }
    let data = try perpsFixture("ws-activeAssetData")
    router.route(data)
    router.route(
      Data(String(decoding: data, as: UTF8.self).replacingOccurrences(of: "BTC", with: "ETH").utf8))
    for _ in 0..<100 {
      if await received.count == 2 { break }
      try await Task.sleep(for: .milliseconds(10))
    }
    #expect(await received.values == ["BTC": "BTC", "ETH": "ETH"])
    router.unregisterPerpsHandler(for: btc)
    router.route(data)
    try await Task.sleep(for: .milliseconds(30))
    #expect(await received.count == 2)
    #expect(throws: ValidationError.self) {
      try router.registerPerpsHandler(for: PerpsSubscription<PerpsMidsEvent>.mids()) { _ in }
      try router.registerPerpsHandler(for: PerpsSubscription<PerpsMidsEvent>.mids(dex: "xyz")) {
        _ in
      }
    }
  }

  @Test func parserAcceptsCompressedStringPayloadWithoutCrashing() throws {
    let data = try perpsFixture("ws-fastAssetCtxs")
    let parsed = try WebSocketMessageParser().parse(data)
    guard case .channelData(let channel, let payload) = parsed else {
      throw APIError.invalidResponse
    }
    #expect(channel == "fastAssetCtxs")
    #expect(try JSONDecoder().decode(String.self, from: payload).isEmpty == false)
  }

  @Test func multisigPayloadFreezesMarketPriceBeforeCollectingSignatures() async throws {
    let (_, exchange) = repositories()
    let payload = try await exchange.preparePerpsMultisig(
      action: .orders([
        .init(
          market: .coin("BTC"), side: .buy,
          size: Decimal(string: "0.001")!, kind: .market())
      ]),
      user: address, leader: address, nonce: 1_700_000_000_123, context: .init())
    PerpsWireProtocol.handler = { request in
      // A later price lookup would change the action signed by another user.
      guard request.url?.path == "/exchange" else { throw APIError.invalidResponse }
      let body = try JSONDecoder().decode([String: JSONValue].self, from: request.perpsTestBody())
      guard case .object(let action)? = body["action"],
        case .object(let envelope)? = action["payload"],
        case .object(let inner)? = envelope["action"], case .array(let orders)? = inner["orders"],
        case .object(let order) = orders[0]
      else { throw APIError.invalidResponse }
      #expect(order["p"] == .string("52500"))
      return Data(
        #"{"status":"ok","response":{"type":"order","data":{"statuses":[{"resting":{"oid":42}}]}}}"#
          .utf8)
    }
    let signature = try await exchange.signPerpsMultisig(payload)
    _ = try await exchange.executeMultisig(.init(payload: payload, signatures: [signature]))
  }

  @Test func fastContextsGrowTheBufferAndPreserveNumericPrices() throws {
    let payload = try JSONDecoder().decode(String.self, from: perpsFixture("fast-context-large"))
    let contexts = try FastAssetCtxDecoder.decode(payload)
    #expect(contexts.count == 500)
    #expect(contexts["xyz:ASSET499"]?.markPx == "100")
    #expect(contexts["xyz:ASSET499"]?.midPx == "100.1")
  }

  @Test func singleModifyDefaultAckDoesNotInventAnOrderID() async throws {
    let (_, exchange) = repositories(observe: { body in
      guard case .object(let action) = body["action"] else { throw APIError.invalidResponse }
      #expect(action["type"] == .string("modify"))
      #expect(action["a"] == nil)
    })
    let result = try await exchange.executePerps(
      .modifyOrder(
        .init(
          identifier: .orderID(42),
          order: .init(
            market: .coin("BTC"), side: .buy, size: Decimal(string: "0.001")!, price: 50000))))
    guard case .success = result else {
      Issue.record("Single modification must expose an acknowledgement")
      return
    }
  }

  @Test func activeCapacityAndMetadataTuplesRejectMalformedData() throws {
    let active =
      #"{"user":"0x1234567890123456789012345678901234567890","coin":"BTC","leverage":{"type":"cross","value":2},"maxTradeSzs":["1","2"],"availableToTrade":["3","4"]}"#
    let value = try JSONDecoder().decode(PerpsActiveAssetData.self, from: Data(active.utf8))
    #expect(value.availableToBuy == 3)
    #expect(value.availableToSell == 4)
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(
        PerpsActiveAssetData.self,
        from: Data(active.replacingOccurrences(of: "[\"3\",\"4\"]", with: "[]").utf8))
    }
    let tuple = try JSONDecoder().decode(
      PerpsMetaAndContexts.self, from: Data("[\(meta),[\(context)]]".utf8))
    #expect(tuple.meta.marginTables?[0].value.marginTiers[0].maxLeverage == 50)
    #expect(tuple.contexts[0].funding == Decimal(string: "-0.0001"))
    #expect(throws: (any Error).self) {
      try JSONDecoder().decode(PerpsMetaAndContexts.self, from: Data("[\(meta),[]]".utf8))
    }
  }

  @Test func deploymentTuplesAreSortedAndInvalidValuesFailBeforeSigning() throws {
    let action = try PerpsDeployAction.fundingMultipliers([.init("xyz:Z", 2), .init("xyz:A", 1)])
      .wire()
    #expect(
      CanonicalMessagePack.json(action)["setFundingMultipliers"]
        == .array([
          .array([.string("xyz:A"), .string("1")]), .array([.string("xyz:Z"), .string("2")]),
        ]))
    #expect(throws: ValidationError.self) {
      try PerpsDeployAction.fundingMultipliers([.init("xyz:A", 11)]).wire()
    }
    #expect(throws: ValidationError.self) {
      try PerpsDeployAction.fundingInterestRates([.init("xyz:A", 1)]).wire()
    }
    #expect(throws: ValidationError.self) {
      try PerpsDeployAction.insertMarginTable(
        dex: "xyz", description: "",
        tiers: [.init(lowerBound: 0, maxLeverage: 10), .init(lowerBound: 1, maxLeverage: 20)]
      ).wire()
    }
    #expect(throws: ValidationError.self) { try perpsMicroUnits(Decimal(string: "0.0000001")!) }
  }
}

private struct PerpsTestWallet: WalletServiceProtocol {
  let address: String
  func sign(message: String) async throws -> SignatureTypes { signature }
  func signL1(action: CanonicalMessagePack.Object, nonce: Int64, isMainnet: Bool) async throws
    -> SignatureTypes
  { signature }
  func signL1Payload(
    _ payload: CanonicalMessagePack.Value, nonce: Int64, vaultAddress: String?,
    expiresAfter: Int64?, isMainnet: Bool
  ) async throws -> SignatureTypes { signature }
  func signUserSigned(
    primaryType: String, fields: [HyperliquidEIP712Field], action: [String: JSONValue],
    isMainnet: Bool
  ) async throws -> SignatureTypes { signature }
  var signature: SignatureTypes { .init(r: "0x1", s: "0x2", v: 27, signatureType: .eoa) }
}
private final class PerpsWireProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> Data)?
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      guard let handler = Self.handler else { throw APIError.invalidResponse }
      let data = try handler(request)
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
extension URLRequest {
  fileprivate func perpsTestBody() throws -> Data {
    if let httpBody { return httpBody }
    guard let stream = httpBodyStream else { throw APIError.invalidResponse }
    stream.open()
    defer { stream.close() }
    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 4096)
    while stream.hasBytesAvailable {
      let count = stream.read(&buffer, maxLength: buffer.count)
      if count < 0 { throw stream.streamError ?? APIError.invalidResponse }
      if count == 0 { break }
      data.append(contentsOf: buffer.prefix(count))
    }
    return data
  }
}

private struct PerpsSigningVector: Decodable, Sendable {
  let name: String
  let kind: String
  let mainnet: Bool
  let msgpack: String?
  let hash: String?
  let r: String
  let s: String
  let v: Int
}

extension PerpsAPITests {
  @Test func everyTypedActionMatchesIndependentPythonSigningVectors() async throws {
    let vectors = try JSONDecoder().decode(
      [PerpsSigningVector].self, from: perpsFixture("signing-vectors"))
    let (_, exchange) = repositories()
    let signer = try Signer(privateKey: String(repeating: "1", count: 64))
    let nonce: Int64 = 1_700_000_000_123
    for vector in vectors {
      let context: PerpsExecutionContext =
        vector.name == "context"
        ? .init(
          vaultAddress: address,
          expiresAfter: Date(timeIntervalSince1970: Double(nonce + 60000) / 1000)) : .init()
      let action = try fixtureAction(vector.name)
      let prepared = try await exchange.preparePerps(action, context: context)
      let signature: SignatureTypes
      if vector.kind == "l1" {
        let object = perpsL1Object(prepared, nonce: nonce)
        let payload: CanonicalMessagePack.Value =
          vector.name == "multisig-l1"
          ? .array([.string(address), .string(signer.address), .object(object)]) : .object(object)
        #expect(
          try CanonicalMessagePack.encode(payload).base64EncodedString() == vector.msgpack,
          "Wire bytes: \(vector.name)")
        let hash = try Signer.actionHash(
          payload: payload, nonce: nonce, vaultAddress: context.vaultAddress,
          expiresAfter: context.expiresAfter.map(perpsMilliseconds))
        #expect(
          hash.map { String(format: "%02x", $0) }.joined() == vector.hash,
          "Action hash: \(vector.name)")
        signature = try await signer.signL1Payload(
          payload, nonce: nonce, vaultAddress: context.vaultAddress,
          expiresAfter: context.expiresAfter.map(perpsMilliseconds), isMainnet: vector.mainnet)
      } else {
        signature = try await signer.signUserSigned(
          primaryType: try #require(prepared.primary),
          fields: exchange.userPerpsFields(prepared),
          action: exchange.userPerpsBody(prepared, nonce: nonce), isMainnet: vector.mainnet)
      }
      #expect(signature.r == vector.r, "r: \(vector.name) mainnet=\(vector.mainnet)")
      #expect(signature.s == vector.s, "s: \(vector.name) mainnet=\(vector.mainnet)")
      #expect(signature.v == vector.v, "v: \(vector.name) mainnet=\(vector.mainnet)")
    }
  }

  private func fixtureAction(_ name: String) throws -> PerpsAction {
    let decimal = Decimal(string: "1.000001")!
    let size = Decimal(string: "0.001")!
    let token = "USDC:0x00000000000000000000000000000001"
    let order = PerpsOrderRequest(market: .coin("BTC"), side: .buy, size: size, price: 50000)
    switch name {
    case "order-Gtc", "context", "multisig-l1": return .orders([order])
    case "order-Ioc":
      return .orders([
        .init(market: .coin("BTC"), side: .buy, size: size, price: 50000, kind: .limit(.ioc))
      ])
    case "order-Alo":
      return .orders([
        .init(market: .coin("BTC"), side: .buy, size: size, price: 50000, kind: .limit(.alo))
      ])
    case "trigger-true", "trigger-false":
      return .orders([
        .init(
          market: .coin("BTC"), side: .buy, size: size, price: 50000,
          kind: .trigger(price: 49000, kind: .stopLoss, market: name == "trigger-true"))
      ])
    case "grouped":
      return .orders([order], grouping: .normalTpsl, builder: .init(address: address, fee: 0))
    case "modify":
      return .modifyOrder(.init(identifier: .orderID(42), order: order), alwaysPlace: true)
    case "batchModify": return .modify([.init(identifier: .orderID(42), order: order)])
    case "cancel", "cancel-fast":
      return .cancel(
        [.init(market: .coin("BTC"), identifier: .orderID(42))], fast: name == "cancel-fast")
    case "cancelByCloid":
      return .cancel([
        .init(market: .coin("BTC"), identifier: .cloid("0x" + String(repeating: "1", count: 32)))
      ])
    case "schedule-set": return .scheduleCancel(Date(timeIntervalSince1970: 1700000000.123))
    case "schedule-clear": return .scheduleCancel(nil)
    case "leverage": return .leverage(market: .coin("BTC"), value: 2, cross: true)
    case "margin-add": return .isolatedMargin(market: .coin("BTC"), amount: decimal)
    case "margin-remove": return .isolatedMargin(market: .coin("BTC"), amount: -decimal)
    case "isolated-leverage": return .isolatedLeverage(market: .coin("BTC"), leverage: 2)
    case "twap":
      return .twap(
        market: .coin("BTC"), side: .buy, size: size, minutes: 5, reduceOnly: false,
        randomize: false)
    case "twapCancel": return .cancelTwap(market: .coin("BTC"), id: 42)
    case "trailing-percent":
      return .trailingStop(
        market: .coin("BTC"), side: .buy, size: size, reduceOnly: false, retracement: .percent(1),
        activationPrice: nil)
    case "trailing-price":
      return .trailingStop(
        market: .coin("BTC"), side: .buy, size: size, reduceOnly: false, retracement: .price(100),
        activationPrice: 50000)
    case "agent-mode": return .agentAbstraction(.unifiedAccount)
    case "legacy-agent-mode": return .legacyAgentDexAbstraction
    case "subaccount-create": return .createSubAccount(name: "fixture")
    case "subaccount-transfer":
      return .subAccountTransfer(address: address, deposit: true, amount: decimal)
    case "subaccount-spot":
      return .subAccountSpotTransfer(address: address, deposit: true, token: token, amount: decimal)
    case "reserve": return .reserveRequestWeight(1, destination: address)
    case "noop": return .invalidateNonce(1_700_000_000_123)
    case "vault": return .vaultTransfer(address: address, deposit: true, amount: decimal)
    case "referrer": return .setReferrer(code: "FIXTURE")
    case "agent-send":
      return .agentSendAsset(
        account: address, source: .spot, destinationLedger: .perps(), token: token, amount: decimal)
    case "class-transfer": return .usdClassTransfer(amount: decimal, toPerp: true)
    case "send-asset":
      return .sendAsset(
        destination: address, source: .spot, destinationLedger: .perps(), token: token,
        amount: decimal)
    case "user-mode": return .userAbstraction(address: address, mode: .standard)
    case "legacy-user-mode": return .legacyUserDexAbstraction(address: address, enabled: true)
    case "withdraw": return .withdraw(destination: address, amount: decimal)
    case "convert": return .convertMultisig(authorizedUsers: [address], threshold: 1)
    case "liquidator-transfer": return .liquidatorTransfer(dex: "xyz", amount: 1000, deposit: true)
    case "restore": return .restoreNormalAccount
    case "agent-approval": return .approveAgent(address: address, name: "fixture")
    case "builder-approval": return .approveBuilder(address: address, maxFeePercent: 0)
    default: break
    }
    let deploy: PerpsDeployAction
    switch name {
    case "deploy-registerAsset2", "deploy-registerAsset":
      deploy = .registerAsset(
        dex: "xyz",
        asset: .init(coin: "xyz:ABC", sizeDecimals: 3, oraclePrice: 100, marginTableID: 50),
        schema: nil, maxGas: nil, legacy: name == "deploy-registerAsset")
    case "deploy-setOracle":
      deploy = .oracle(
        dex: "xyz", oraclePrices: [.init("xyz:Z", 101), .init("xyz:A", 100)],
        markPrices: [[.init("xyz:A", 100)]], externalPrices: [.init("xyz:A", 100)])
    case "deploy-setFundingMultipliers": deploy = .fundingMultipliers([.init("xyz:A", 1)])
    case "deploy-setFundingInterestRates":
      deploy = .fundingInterestRates([.init("xyz:A", Decimal(string: "-0.001")!)])
    case "deploy-setFundingClamps":
      deploy = .fundingClamps([.init("xyz:A", Decimal(string: "0.0003")!)])
    case "deploy-haltTrading": deploy = .halt(coin: "xyz:ABC", halted: true)
    case "deploy-insertMarginTable":
      deploy = .insertMarginTable(
        dex: "xyz", description: "",
        tiers: [
          .init(lowerBound: 0, maxLeverage: 50), .init(lowerBound: 1_000_000, maxLeverage: 10),
        ])
    case "deploy-setMarginTableIds": deploy = .marginTableIDs([.init("xyz:A", 50)])
    case "deploy-setFeeRecipient": deploy = .feeRecipient(dex: "xyz", address: address)
    case "deploy-setOpenInterestCaps":
      deploy = .openInterestCaps([.init("xyz:Z", nil), .init("xyz:A", 1_000_000)])
    case "deploy-setSubDeployers":
      deploy = .subDeployers(
        dex: "xyz", users: [.init(permission: .setOracle, address: address, allowed: true)])
    case "deploy-setMarginModes": deploy = .marginModes([.init("xyz:A", .strictIsolated)])
    case "deploy-setDeployerFees":
      deploy = .deployerFees([.init("xyz:A", .init(scale: 1, growthMode: true))])
    case "deploy-setPerpAnnotation":
      deploy = .annotation(
        coin: "xyz:ABC", category: "other", description: "fixture", displayName: nil, keywords: [])
    case "deploy-disableDex": deploy = .disableDex("xyz")
    default: throw ValidationError.malformedData(reason: "Unregistered signing vector " + name)
    }
    return .deploy(deploy)
  }
}

private actor PerpsRouterResults {
  var values: [String: String] = [:]
  var count = 0
  func add(_ source: String, result: Result<String, Error>) {
    count += 1
    switch result {
    case .success(let coin): values[source] = coin
    case .failure(let error): Issue.record("Typed routing: \(error)")
    }
  }
}
