import Foundation
import Testing

@testable import HeliqSDK

@Suite(.serialized)
struct InfoRepositoryWireTests {
  private let address = "0x1234567890123456789012345678901234567890"

  @Test func getTimeUsesExchangeBookTimestamp() async throws {
    let repo = repository(
      responses: ["l2Book": #"{"coin":"BTC","time":1724361546645,"levels":[[],[]]}"#],
      expected: ["l2Book": ["coin": .string("BTC")]]
    )
    let time = try await repo.getTime()
    #expect(time == Date(timeIntervalSince1970: 1_724_361_546.645))
  }

  @Test func getTimePropagatesInvalidSnapshot() async {
    let repo = repository(responses: ["l2Book": #"{"coin":"BTC","levels":[[],[]]}"#])
    await #expect(throws: DecodingError.self) {
      try await repo.getTime()
    }
  }

  private func repository(
    responses: [String: String],
    expected: [String: [String: JSONValue]] = [:],
    defaultAddress: String? = nil
  ) -> InfoRepositoryImpl {
    InfoWireProtocol.handler = { request in
      #expect(request.httpMethod == "POST")
      #expect(request.url?.path == "/info")
      var data = request.httpBody ?? Data()
      if let stream = request.httpBodyStream {
        stream.open()
        defer { stream.close() }
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
          let count = stream.read(&buffer, maxLength: buffer.count)
          if count < 0 { throw stream.streamError ?? NetworkError.invalidResponse }
          if count == 0 { break }
          data.append(contentsOf: buffer.prefix(count))
        }
      }
      let body = try JSONDecoder().decode([String: JSONValue].self, from: data)
      guard case .string(let type) = body["type"], let response = responses[type] else {
        throw ValidationError.malformedData(reason: "Unexpected test request")
      }
      for (key, value) in expected[type] ?? [:] { #expect(body[key] == value) }
      return Data(response.utf8)
    }
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [InfoWireProtocol.self]
    return InfoRepositoryImpl(
      apiClient: APIClient(environment: .testnet, session: URLSession(configuration: configuration)),
      defaultUserAddress: defaultAddress
    )
  }

  @Test func mapsMixedPositionsWithoutInventingAccountLeverageOrRealizedPnl() async throws {
    let repo = repository(responses: [
      "meta": #"{"universe":[{"name":"BTC"},{"name":"ETH"}]}"#,
      "clearinghouseState": #"{"marginSummary":{"accountValue":"123.45","totalMarginUsed":"10.5"},"assetPositions":[{"position":{"coin":"ETH","szi":"-2","entryPx":null,"unrealizedPnl":"-3.4","marginUsed":"5","leverage":{"type":"isolated","value":20}}},{"position":{"coin":"BTC","szi":"1","entryPx":"50000","unrealizedPnl":"10","marginUsed":"5.5","leverage":{"type":"cross","value":10}}}]}"#
    ], expected: ["clearinghouseState": ["user": .string(address)]])
    let state = try await repo.getUserState(address: address)
    #expect(state.accountAddress == address)
    #expect(state.marginTotal == 123.45)
    #expect(state.marginUsed == 10.5)
    #expect(state.marginMode == nil)
    #expect(state.leverage == nil)
    #expect(state.assetPositions[0].asset == 1)
    #expect(state.assetPositions[0].positionSize == -2)
    #expect(state.assetPositions[0].entryPrice == nil)
    #expect(state.assetPositions[0].realizedPnl == nil)
    #expect(state.assetPositions[0].marginMode == .isolated)
    #expect(state.assetPositions[0].leverage == 20)
    #expect(state.assetPositions[1].asset == 0)
  }

  @Test func mapsEmptyAccountWithoutMetadataRequest() async throws {
    let repo = repository(responses: [
      "clearinghouseState": #"{"marginSummary":{"accountValue":"0","totalMarginUsed":"0"},"assetPositions":[]}"#
    ])
    let state = try await repo.getUserState(address: address)
    #expect(state.assetPositions.isEmpty)
    #expect(state.marginMode == nil)
    #expect(state.leverage == nil)
  }

  @Test func mapsSpotTokensAndUsdcBalance() async throws {
    let repo = repository(responses: [
      "spotClearinghouseState": #"{"balances":[{"coin":"USDC","token":0,"total":"12.5","hold":"2"},{"coin":"HYPE","token":150,"total":"3","hold":"1"}]}"#
    ], expected: ["spotClearinghouseState": ["user": .string(address)]])
    let state = try await repo.getSpotUserState(address: address)
    #expect(state.totalUsdc == 12.5)
    #expect(state.spotPositions[1].asset == 150)
    #expect(state.spotPositions[1].totalSize == 3)
    #expect(state.spotPositions[1].hold == 1)
  }

  @Test func mapsFillsAndMillisecondTimes() async throws {
    let repo = repository(responses: ["userFills": fill], expected: ["userFills": ["user": .string(address)]])
    let fills = try await repo.queryFills(address: address)
    #expect(fills[0].id == "42")
    #expect(fills[0].orderId == "123")
    #expect(fills[0].side == .sell)
    #expect(fills[0].price == 3000.5)
    #expect(fills[0].symbol == "ETH")
    #expect(fills[0].timestamp == Date(timeIntervalSince1970: 1_724_361_546.645))
  }

  @Test(arguments: ["garbage", "NaN", "Infinity"])
  func rejectsInvalidDecimals(value: String) async {
    let repo = repository(responses: ["userFills": fill.replacingOccurrences(of: "3000.5", with: value)])
    await #expect(throws: ValidationError.self) { try await repo.queryFills(address: address) }
  }

  @Test func mapsSignedFundingAndAssetFromMetadata() async throws {
    let repo = repository(responses: [
      "meta": #"{"universe":[{"name":"BTC"},{"name":"ETH"}]}"#,
      "userFunding": #"[{"time":1724361546645,"delta":{"type":"funding","coin":"ETH","usdc":"-0.25","fundingRate":"0.0001"}}]"#
    ], expected: ["userFunding": ["user": .string(address), "startTime": .number(0)]])
    let funding = try await repo.queryUserFundings(address: address)
    #expect(funding[0].asset == 1)
    #expect(funding[0].payment == -0.25)
    #expect(funding[0].rate == 0.0001)
    #expect(funding[0].time == Date(timeIntervalSince1970: 1_724_361_546.645))
  }

  @Test func queriesExplicitAndDefaultAddressesAndUnknownOrders() async throws {
    let cloid = "0x1234567890abcdef1234567890abcdef"
    let repo = repository(responses: ["orderStatus": #"{"status":"unknownOid"}"#],
                          expected: ["orderStatus": ["user": .string(address)]], defaultAddress: address)
    #expect(try await repo.queryOrderByOid(orderId: "1").isEmpty)
    #expect(try await repo.queryOrderByCloid(cloid: cloid).isEmpty)
    #expect(try await repo.queryOrderByOid(orderId: "1", address: address).isEmpty)
    #expect(try await repo.queryOrderByCloid(cloid: cloid, address: address).isEmpty)
  }

  @Test func mapsKnownOrderAndOriginalSize() async throws {
    let repo = repository(responses: [
      "meta": #"{"universe":[{"name":"BTC"},{"name":"ETH"}]}"#,
      "orderStatus": #"{"status":"order","order":{"order":{"coin":"ETH","side":"A","limitPx":"2412.7","sz":"0.0","oid":1,"timestamp":1724361546645,"triggerCondition":"N/A","isTrigger":false,"triggerPx":"0.0","children":[],"isPositionTpsl":false,"reduceOnly":true,"orderType":"Market","origSz":"0.0076","tif":"FrontendMarket","cloid":null},"status":"filled","statusTimestamp":1724361546645}}"#
    ], expected: ["orderStatus": ["user": .string(address), "oid": .number(1)]])
    let orders = try await repo.queryOrderByOid(orderId: "1", address: address)
    #expect(orders.count == 1)
    #expect(orders[0].asset == 1)
    #expect(orders[0].side == .sell)
    #expect(orders[0].filled == 0.0076)
    #expect(orders[0].status == .filled)
  }

  @Test func rejectsInvalidInputsBeforeTransport() async {
    let repo = repository(responses: [:])
    await #expect(throws: ValidationError.self) { try await repo.getUserState(address: "0xDemoWallet") }
    await #expect(throws: ValidationError.self) { try await repo.getSpotUserState(address: "invalid") }
    await #expect(throws: ValidationError.self) { try await repo.queryFills(address: "invalid") }
    await #expect(throws: ValidationError.self) { try await repo.queryUserFundings(address: "invalid") }
    await #expect(throws: ValidationError.self) { try await repo.queryOrderByOid(orderId: "-1", address: address) }
    await #expect(throws: ValidationError.self) { try await repo.queryOrderByCloid(cloid: "0xabc", address: address) }
    await #expect(throws: ValidationError.self) { try await repo.queryOrderByOid(orderId: "1") }
  }

  @Test func mapsPerpetualMetadataWithoutInventingTokenPrecision() async throws {
    let repo = repository(responses: [
      "meta": #"{"universe":[{"name":"BTC","szDecimals":5,"maxLeverage":50},{"name":"ETH","szDecimals":4,"marginMode":"noCross"}]}"#
    ])
    let meta = try await repo.getMeta()
    #expect(meta.universe[0].asset == 0)
    #expect(meta.universe[0].name == "BTC")
    #expect(meta.universe[0].szDecimals == 5)
    #expect(meta.universe[0].weiDecimals == nil)
    #expect(meta.universe[0].isPerpetual)
    #expect(meta.universe[1].onlyIsolatedMargin)
    #expect(meta.spotAssetConfigs.isEmpty)
  }

  @Test func mapsSpotMarketIndexesAndBaseTokenReferences() async throws {
    let repo = repository(responses: ["spotMeta": spotMetadata])
    let meta = try await repo.getSpotMeta()
    #expect(meta.universe[0].asset == 10_003)
    #expect(meta.universe[0].szDecimals == 2)
    #expect(meta.universe[0].weiDecimals == 8)
    #expect(!meta.universe[0].isPerpetual)
    #expect(meta.spotAssetConfigs["10003"]?.tokenCfg?.name == "Example Token")
    #expect(meta.spotAssetConfigs["10003"]?.tokenCfg?.symbol == "TOKEN")
  }

  @Test func rejectsUnknownSpotTokenReferences() async {
    let repo = repository(responses: ["spotMeta": spotMetadata.replacingOccurrences(of: "[5,0]", with: "[99,0]")])
    await #expect(throws: ValidationError.self) { try await repo.getSpotMeta() }
  }

  @Test func builderFeeUsesBothAddressesAndTenthsOfBasisPoints() async throws {
    let builder = "0x0000000000000000000000000000000000000001"
    let repo = repository(
      responses: ["maxBuilderFee": "1"],
      expected: ["maxBuilderFee": ["user": .string(address), "builder": .string(builder)]],
      defaultAddress: address
    )
    #expect(try await repo.fetchBuilderFee(builderAddress: builder).feeBps == 0.1)
    #expect(try await repo.fetchBuilderFee(builderAddress: builder, address: address).feeBps == 0.1)
  }

  @Test func rejectsMissingUserInvalidBuilderAndNegativeApproval() async {
    let repo = repository(responses: ["maxBuilderFee": "-1"])
    await #expect(throws: ValidationError.self) { try await repo.fetchBuilderFee(builderAddress: address) }
    await #expect(throws: ValidationError.self) {
      try await repo.fetchBuilderFee(builderAddress: "invalid", address: address)
    }
    await #expect(throws: ValidationError.self) {
      try await repo.fetchBuilderFee(builderAddress: address, address: address)
    }
  }

  private var spotMetadata: String {
    #"{"tokens":[{"name":"TOKEN","index":5,"szDecimals":2,"weiDecimals":8,"fullName":"Example Token"},{"name":"USDC","index":0,"szDecimals":8,"weiDecimals":8}],"universe":[{"name":"@3","index":3,"tokens":[5,0]}]}"#
  }

  private var fill: String {
    #"[{"closedPnl":"1.2","coin":"ETH","crossed":true,"dir":"Close Long","hash":"0xabc","oid":123,"px":"3000.5","side":"A","startPosition":"1","sz":"0.5","time":1724361546645,"fee":"0.1","feeToken":"USDC","tid":42}]"#
  }
}

private final class InfoWireProtocol: URLProtocol, @unchecked Sendable {
  nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> Data)?
  override class func canInit(with request: URLRequest) -> Bool { true }
  override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
  override func startLoading() {
    do {
      let data = try Self.handler!(request)
      let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
      client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
      client?.urlProtocol(self, didLoad: data)
      client?.urlProtocolDidFinishLoading(self)
    } catch { client?.urlProtocol(self, didFailWithError: error) }
  }
  override func stopLoading() {}
}
