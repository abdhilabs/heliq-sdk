//
//  ExchangeRepositoryImpl.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents any codable data.
public struct AnyCodable: Encodable {
  /// The value.
  public let value: Any
  
  /// Creates a any codable.
  public init(_ value: Any) {
    self.value = value
  }
  
  /// Performs the encode operation.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    if let string = value as? String {
      try container.encode(string)
    } else if let int = value as? Int {
      try container.encode(int)
    } else if let double = value as? Double {
      try container.encode(double)
    } else if let bool = value as? Bool {
      try container.encode(bool)
    } else {
      try container.encodeNil()
    }
  }
}

/// Defines exchange endpoint values.
public enum ExchangeEndpoint: Sendable {
  /// The `placeOrder` option.
  case placeOrder
  /// The `bulkOrders` option.
  case bulkOrders
  /// The `cancel` option.
  case cancel
  /// The `cancelByCloid` option.
  case cancelByCloid
  /// The `cancelAll` option.
  case cancelAll
  /// The `modifyOrder` option.
  case modifyOrder
  /// The `modifyByCloid` option.
  case modifyByCloid
  /// The `setLeverage` option.
  case setLeverage
  /// The `setMarginMode` option.
  case setMarginMode
  /// The `transfer` option.
  case transfer
  /// The `sendToAddress` option.
  case sendToAddress
  /// The `spotTransfer` option.
  case spotTransfer
  /// The `vaultTransfer` option.
  case vaultTransfer
  /// The `updateBuilder` option.
  case updateBuilder
  /// The `scheduleCancel` option.
  case scheduleCancel
  /// The `setReferrer` option.
  case setReferrer
  /// The `convertToMultiSig` option.
  case convertToMultiSig
  /// The `usdSend` option.
  case usdSend
  
  var path: String { "/exchange" }
  
  var typeString: String {
    switch self {
    case .placeOrder: return "order"
    case .bulkOrders: return "bulkOrders"
    case .cancel: return "cancel"
    case .cancelByCloid: return "cancelByCloid"
    case .cancelAll: return "cancelAll"
    case .modifyOrder: return "modify"
    case .modifyByCloid: return "modifyByCloid"
    case .setLeverage: return "setLeverage"
    case .setMarginMode: return "setMarginMode"
    case .transfer: return "transfer"
    case .sendToAddress: return "sendToAddress"
    case .spotTransfer: return "spotTransfer"
    case .vaultTransfer: return "vaultTransfer"
    case .updateBuilder: return "updateBuilder"
    case .scheduleCancel: return "scheduleCancel"
    case .setReferrer: return "setReferrer"
    case .convertToMultiSig: return "convertToMultiSig"
    case .usdSend: return "usdSend"
    }
  }
}

/// Represents exchange apirequest data.
public struct ExchangeAPIRequest: APIRouterProtocol, Sendable {
  /// The endpoint.
  public let endpoint: ExchangeEndpoint
  private let _body: Data?
  
  /// The path.
  public var path: String { endpoint.path }
  /// The method.
  public var method: HTTPMethod { .post }
  /// The body.
  public var body: Data? { _body }
  
  /// Creates a exchange apirequest.
  public init(endpoint: ExchangeEndpoint, body: Data?) {
    self.endpoint = endpoint
    self._body = body
  }
}

/// Provides exchange repository impl functionality.
public final class ExchangeRepositoryImpl: ExchangeRepository, @unchecked Sendable {
  private typealias Object = CanonicalMessagePack.Object
  private typealias Value = CanonicalMessagePack.Value
  let apiClient: APIClient
  private let transactionBuilder: TransactionBuilder
  private let wallet: (any WalletServiceProtocol)?
  static let nonces = ExchangeNonce()

  /// Creates an exchange repository backed by the client, transaction builder, and optional wallet.
  /// Signed submissions fail explicitly when no wallet is configured.
  public init(
    apiClient: APIClient, transactionBuilder: TransactionBuilder = TransactionBuilder(),
    wallet: (any WalletServiceProtocol)? = nil
  ) {
    self.apiClient = apiClient
    self.transactionBuilder = transactionBuilder
    self.wallet = wallet
  }

  /// Returns the configured signing wallet or throws when no wallet is connected.
  func requireWallet() throws -> any WalletServiceProtocol {
    guard let wallet else { throw ValidationError.missingRequiredField(field: "wallet") }
    try validateHex(wallet.address, bytes: 20, field: "wallet.address")
    return wallet
  }

  private func submit(_ action: Object) async throws -> JSONValue {
    let wallet = try requireWallet()
    let nonce = await Self.nonces.next()
    let signature = try await wallet.signL1(
      action: action, nonce: nonce, isMainnet: apiClient.environment == .mainnet)
    return try await post(
      action: CanonicalMessagePack.json(action), nonce: nonce, signature: signature)
  }

  /// Signs and submits a user action with the supplied EIP-712 fields.
  private func submitUser(
    type: String, primary: String, parameters: [String: JSONValue], fields: [(String, String)],
    timeKey: String = "time"
  ) async throws -> JSONValue {
    let wallet = try requireWallet()
    let nonce = await Self.nonces.next()
    var action = parameters
    action["type"] = .string(type)
    action[timeKey] = .protocolInteger(nonce)
    action["signatureChainId"] = .string("0x66eee")
    action["hyperliquidChain"] = .string(apiClient.environment == .mainnet ? "Mainnet" : "Testnet")
    let schema = [("hyperliquidChain", "string")] + fields + [(timeKey, "uint64")]
    let signature = try await wallet.signUserSigned(
      primaryType: "HyperliquidTransaction:" + primary,
      fields: schema.map { .init(name: $0.0, type: $0.1) }, action: action,
      isMainnet: apiClient.environment == .mainnet)
    return try await post(action: action, nonce: nonce, signature: signature)
  }

  /// Posts a signed action with its nonce and execution context without retrying the mutation.
  func post(action: [String: JSONValue], nonce: Int64, signature: SignatureTypes, context: PerpsExecutionContext = .init())
    async throws -> JSONValue
  {
    guard [27, 28].contains(signature.v) else {
      throw SigningError.signingFailed(reason: "Invalid Ethereum recovery ID")
    }
    for value in [signature.r, signature.s] {
      let hex = value.hasPrefix("0x") ? String(value.dropFirst(2)) : ""
      guard !hex.isEmpty, hex.count <= 64, hex.utf8.allSatisfy(isHex) else {
        throw SigningError.signingFailed(reason: "Invalid signature component")
      }
    }
    var body: [String: JSONValue] = [
        "action": .object(action), "nonce": .protocolInteger(nonce),
        "signature": .object([
          "r": .string(signature.r), "s": .string(signature.s), "v": .number(Double(signature.v)),
        ]),
      ]
    if let address = context.vaultAddress { body["vaultAddress"] = .string(address) }
    if let expires = context.expiresAfter { body["expiresAfter"] = .number(Double(try perpsMilliseconds(expires))) }
    let request = try HyperliquidRawRequest(path: "/exchange", body: body)
    let result: JSONValue = try await apiClient.request(request)
    guard result["status"].string == "ok" else {
      throw APIError.hyperliquidError(
        code: 0, message: result["response"].string ?? "Exchange rejected the action")
    }
    guard case .object = result["response"] else { throw APIError.invalidResponse }
    return result["response"]
  }

  private func statuses(_ response: JSONValue, count: Int, type: String = "order") throws
    -> [JSONValue]
  {
    guard response["type"].string == type, case .array(let statuses) = response["data"]["statuses"],
      statuses.count == count
    else { throw APIError.invalidResponse }
    return statuses
  }

  private func orderResponse(_ value: JSONValue) throws -> OrderResponse {
    if let error = value["error"].string {
      throw APIError.hyperliquidError(code: 0, message: error)
    }
    if let oid = value["resting"]["oid"].number {
      return .init(orderId: try orderIDString(oid), status: "resting")
    }
    if let oid = value["filled"]["oid"].number,
      let size = value["filled"]["totalSz"].string.flatMap(Double.init),
      let price = value["filled"]["avgPx"].string.flatMap(Double.init), size.isFinite,
      price.isFinite
    {
      return .init(
        orderId: try orderIDString(oid), status: "filled", filledSize: size, filledPx: price)
    }
    if ["waitingForFill", "waitingForTrigger"].contains(value.string ?? "") {
      return .init(orderId: nil, status: value.string!)
    }
    throw APIError.invalidResponse
  }

  /// Submits one signed order and throws if the exchange rejects that order.
  public func placeOrder(_ order: OrderRequest) async throws -> OrderResponse {
    let response = try await bulkOrders([order]).responses[0]
    if let error = response.error { throw APIError.hyperliquidError(code: 0, message: error) }
    return response
  }

  /// Submits a nonempty signed batch, preserving each order's rejection or execution status.
  public func bulkOrders(_ orders: [OrderRequest]) async throws -> BulkOrderResponse {
    _ = try requireWallet()
    guard !orders.isEmpty else { throw ValidationError.missingRequiredField(field: "orders") }
    var wires: [Value] = []
    for order in orders { wires.append(.object(try await orderWire(order))) }
    let response = try await submit(
      Object([("type", .string("order")), ("orders", .array(wires)), ("grouping", .string("na"))]))
    // Preserve per-order failures so callers can account for partial execution.
    return .init(
      responses: try statuses(response, count: orders.count).map { value in
        if let error = value["error"].string {
          return .init(orderId: nil, status: "error", error: error)
        }
        return try orderResponse(value)
      })
  }

  private func orderWire(_ order: OrderRequest) async throws -> Object {
    _ = try transactionBuilder.buildOrderTransaction(order: order)
    if let cloid = order.cloid { try validateHex(cloid, bytes: 16, field: "cloid") }
    var price = order.price
    let orderType: Value
    switch order.orderType {
    case .limit:
      orderType = .object(Object([("limit", .object(Object([("tif", .string("Gtc"))])))]))
    case .market:
      if price == nil { price = try await marketPrice(asset: order.asset, buy: order.side == .buy) }
      orderType = .object(Object([("limit", .object(Object([("tif", .string("Ioc"))])))]))
    case .triggerMarket(let trigger), .triggerLimit(let trigger):
      let market: Bool
      if case .triggerMarket = order.orderType { market = true } else { market = false }
      guard ["tp", "sl"].contains(trigger.tpsl) else {
        throw ValidationError.invalidEnumValue(type: "tpsl", value: trigger.tpsl)
      }
      if market, price == nil {
        price = try await marketPrice(
          asset: order.asset, buy: order.side == .buy, reference: trigger.triggerPx)
      }
      orderType = .object(
        Object([
          (
            "trigger",
            .object(
              Object([
                ("isMarket", .bool(market)), ("triggerPx", .string(try decimal(trigger.triggerPx))),
                ("tpsl", .string(trigger.tpsl)),
              ]))
          )
        ]))
    }
    guard let price else { throw ValidationError.missingRequiredField(field: "price") }
    var fields: [(String, Value)] = [
      ("a", .number(Double(order.asset))), ("b", .bool(order.side == .buy)),
      ("p", .string(try decimal(price))), ("s", .string(try decimal(order.size))),
      ("r", .bool(order.reduceOnly)), ("t", orderType),
    ]
    if let cloid = order.cloid { fields.append(("c", .string(cloid))) }
    return Object(fields)
  }

  private func marketPrice(asset: Int, buy: Bool, reference: Double? = nil) async throws -> Double {
    let meta = try await metadata(asset: asset)
    let price: Double
    if let reference {
      price = reference
    } else {
      let mids = try await HyperliquidAPI(apiClient: apiClient).info(.init(type: .allMids))
      guard let mid = mids[meta.name].string.flatMap(Double.init), mid.isFinite, mid > 0 else {
        throw APIError.invalidResponse
      }
      price = mid
    }
    // Match the official SDK's default 5% market slippage and price precision.
    let adjusted = price * (buy ? 1.05 : 0.95)
    guard adjusted.isFinite, adjusted > 0 else { throw APIError.invalidResponse }
    let significant = Double(
      String(format: "%.5g", locale: Locale(identifier: "en_US_POSIX"), adjusted))!
    let scale = pow(10.0, Double(max(0, (asset >= 10_000 ? 8 : 6) - meta.szDecimals)))
    return (significant * scale).rounded() / scale
  }

  private func metadata(asset: Int) async throws -> MetaAsset {
    try validateAsset(asset)
    let info = InfoRepositoryImpl(apiClient: apiClient)
    let meta = asset >= 10_000 ? try await info.getSpotMeta() : try await info.getMeta()
    guard let result = meta.universe.first(where: { $0.asset == asset }) else {
      throw ValidationError.outOfRange(field: "asset", min: 0, max: nil)
    }
    return result
  }

  /// Cancels one exchange order ID on the specified asset and preserves any server rejection.
  public func cancelOrder(orderId: String, asset: Int) async throws -> CancelResponse {
    try validateAsset(asset)
    let response = try await submit(
      Object([
        ("type", .string("cancel")),
        (
          "cancels",
          .array([
            .object(Object([("a", .number(Double(asset))), ("o", .number(try orderID(orderId)))]))
          ])
        ),
      ]))
    return try cancelResponse(statuses(response, count: 1, type: "cancel")[0])
  }

  /// Cancels one asset's order by its 16-byte hexadecimal client order ID.
  public func cancelByCloid(cloid: String, asset: Int) async throws -> CancelResponse {
    try validateAsset(asset)
    try validateHex(cloid, bytes: 16, field: "cloid")
    let response = try await submit(
      Object([
        ("type", .string("cancelByCloid")),
        (
          "cancels",
          .array([.object(Object([("asset", .number(Double(asset))), ("cloid", .string(cloid))]))])
        ),
      ]))
    return try cancelResponse(statuses(response, count: 1, type: "cancel")[0])
  }

  private func cancelResponse(_ value: JSONValue) throws -> CancelResponse {
    if let error = value["error"].string { return .init(status: "error", error: error) }
    guard value.string == "success" else { throw APIError.invalidResponse }
    return .init(status: "success")
  }

  /// Queries the wallet's open orders and cancels them, separating successes from per-order failures.
  public func cancelAll() async throws -> CancelAllResponse {
    let wallet = try requireWallet()
    let orders = try await HyperliquidAPI(apiClient: apiClient).openOrders(user: wallet.address)
    guard !orders.isEmpty else { return .init(cancelledOrders: [], failedCancels: []) }
    let info = InfoRepositoryImpl(apiClient: apiClient)
    let perps = try await info.getMeta()
    let spot =
      orders.contains(where: { $0.coin.hasPrefix("@") || $0.coin.contains("/") })
      ? try await info.getSpotMeta().universe : []
    let assets = perps.universe + spot
    let cancels: [Value] = try orders.map { order in
      guard let asset = assets.first(where: { $0.name == order.coin })?.asset else {
        throw ValidationError.malformedData(reason: "Unknown open-order asset: " + order.coin)
      }
      return .object(
        Object([("a", .number(Double(asset))), ("o", .number(try orderID(String(order.orderID))))]))
    }
    let response = try await submit(
      Object([("type", .string("cancel")), ("cancels", .array(cancels))]))
    var cancelled: [String] = []
    var failed: [FailedCancel] = []
    for (order, value) in zip(orders, try statuses(response, count: orders.count, type: "cancel")) {
      let result = try cancelResponse(value)
      if let error = result.error {
        failed.append(.init(orderId: String(order.orderID), error: error))
      } else {
        cancelled.append(String(order.orderID))
      }
    }
    return .init(cancelledOrders: cancelled, failedCancels: failed)
  }

  /// Changes size or price by exchange ID while preserving the existing order's other settings.
  public func modifyOrder(orderId: String, asset: Int, size: Double?, price: Double?) async throws
    -> OrderResponse
  {
    try await modify(oid: .number(try orderID(orderId)), asset: asset, size: size, price: price)
  }

  /// Resolves the active client-ID order before changing size or price; nil fields remain unchanged.
  public func modifyByCloid(cloid: String, asset: Int, size: Double?, price: Double?) async throws
    -> OrderResponse
  {
    try validateHex(cloid, bytes: 16, field: "cloid")
    return try await modify(oid: .string(cloid), asset: asset, size: size, price: price)
  }

  private func modify(oid: Value, asset: Int, size: Double?, price: Double?) async throws
    -> OrderResponse
  {
    let wallet = try requireWallet()
    let api = HyperliquidAPI(apiClient: apiClient)
    var status: HyperliquidOrderStatus
    switch oid {
    case .number(let id): status = try await api.orderStatus(user: wallet.address, oid: Int64(id))
    case .string(let cloid):
      status = try await api.orderStatus(user: wallet.address, cloid: cloid)
      // Historical client-ID lookup can retain the old order after replacement.
      if status.status != "open" {
        let response = try await api.info(.frontendOpenOrders(user: wallet.address))
        guard case .array(let openOrders) = response else { throw APIError.invalidResponse }
        if let current = openOrders.first(where: {
          $0["cloid"].string?.lowercased() == cloid.lowercased()
        }),
          let id = current["oid"].number, id > 0, id < 9_007_199_254_740_992,
          id.rounded() == id
        {
          status = try await api.orderStatus(user: wallet.address, oid: Int64(id))
        }
      }
    default: throw APIError.invalidResponse
    }
    guard status.status == "open", let existing = status.order else {
      throw ValidationError.malformedData(reason: "Only an open order can be modified")
    }
    guard try await metadata(asset: asset).name == existing.coin else {
      throw ValidationError.malformedData(reason: "Order asset does not match")
    }
    guard ["A", "B"].contains(existing.side) else { throw APIError.invalidResponse }
    let type: OrderType
    switch existing.orderType {
    case "Limit":
      guard !existing.isTrigger, ["Alo", "Ioc", "Gtc"].contains(existing.timeInForce) else {
        throw APIError.invalidResponse
      }
      type = .limit
    case "Stop Market", "Take Profit Market", "Stop Limit", "Take Profit Limit":
      guard existing.isTrigger, let triggerPx = Double(existing.triggerPrice) else {
        throw APIError.invalidResponse
      }
      let trigger = TriggerParams(
        triggerPx: triggerPx, tpsl: existing.orderType.hasPrefix("Take Profit") ? "tp" : "sl")
      type =
        existing.orderType.hasSuffix("Market") ? .triggerMarket(trigger) : .triggerLimit(trigger)
    default:
      throw ValidationError.invalidEnumValue(type: "existing order type", value: existing.orderType)
    }
    let order = OrderRequest(
      asset: asset, side: existing.side == "B" ? .buy : .sell, orderType: type,
      size: size ?? Double(existing.size) ?? 0, price: price ?? Double(existing.limitPrice),
      reduceOnly: existing.reduceOnly, cloid: existing.cloid)
    var wire = try await orderWire(order)
    if !existing.isTrigger, ["Alo", "Ioc", "Gtc"].contains(existing.timeInForce) {
      wire = Object(
        wire.fields.map {
          $0.0 == "t"
            ? (
              "t",
              .object(
                Object([("limit", .object(Object([("tif", .string(existing.timeInForce))])))]))
            ) : $0
        })
    }
    let response = try await submit(
      Object([
        ("type", .string("batchModify")),
        ("modifies", .array([.object(Object([("oid", oid), ("order", .object(wire))]))])),
      ]))
    return try orderResponse(statuses(response, count: 1)[0])
  }

  private func leverageState(asset: Int) async throws -> JSONValue {
    let wallet = try requireWallet()
    guard asset < 10_000 else {
      throw ValidationError.malformedData(reason: "Leverage applies to perpetual assets")
    }
    let coin = try await metadata(asset: asset).name
    let result = try await HyperliquidAPI(apiClient: apiClient).info(
      .init(
        type: .custom("activeAssetData"),
        parameters: ["user": .string(wallet.address), "coin": .string(coin)]))
    guard result["leverage"]["value"].number != nil,
      ["cross", "isolated"].contains(result["leverage"]["type"].string ?? "")
    else { throw APIError.invalidResponse }
    return result["leverage"]
  }

  private func updateLeverage(asset: Int, leverage: Int, cross: Bool) async throws {
    try validateAsset(asset)
    guard leverage > 0 else {
      throw ValidationError.outOfRange(field: "leverage", min: 1, max: nil)
    }
    try expectDefault(
      await submit(
        Object([
          ("type", .string("updateLeverage")), ("asset", .number(Double(asset))),
          ("isCross", .bool(cross)), ("leverage", .number(Double(leverage))),
        ])))
  }

  /// Sets positive leverage while retaining the asset's current cross or isolated margin mode.
  public func setLeverage(asset: Int, leverage: Int) async throws -> SetLeverageResponse {
    let state = try await leverageState(asset: asset)
    try await updateLeverage(
      asset: asset, leverage: leverage, cross: state["type"].string == "cross")
    return .init(status: "ok", leverage: leverage)
  }

  /// Changes cross or isolated margin mode while retaining the asset's current leverage.
  public func setMarginMode(asset: Int, mode: MarginMode) async throws -> SetMarginModeResponse {
    let state = try await leverageState(asset: asset)
    guard let value = state["value"].number, value >= 1, value <= Double(Int32.max),
      value.rounded() == value
    else { throw APIError.invalidResponse }
    try await updateLeverage(asset: asset, leverage: Int(value), cross: mode == .cross)
    return .init(status: "ok")
  }

  /// Transfers from the signing wallet only; asset zero denotes Perps USDC, others Spot token indices.
  public func transfer(fromAddress: String, toAddress: String, amount: Double, asset: Int)
    async throws -> TransferResponse
  {
    let wallet = try requireWallet()
    try validateHex(fromAddress, bytes: 20, field: "fromAddress")
    guard fromAddress.lowercased() == wallet.address.lowercased() else {
      throw ValidationError.malformedData(reason: "fromAddress must match the signing wallet")
    }
    let response = try await sendToAddress(address: toAddress, amount: amount, asset: asset)
    return .init(status: response.status, hash: response.hash)
  }

  /// Asset is a spot token index for transfers; 0 sends perpetual USDC.
  public func sendToAddress(address: String, amount: Double, asset: Int) async throws
    -> SendToAddressResponse
  {
    if asset == 0 {
      return .init(status: try await usdSend(destination: address, amount: amount).status)
    }
    return .init(
      status: try await spotTransfer(toAddress: address, amount: amount, asset: asset).status)
  }

  /// Asset is the token index in spotMeta.tokens, not an order-market index.
  public func spotTransfer(toAddress: String, amount: Double, asset: Int) async throws
    -> SpotTransferResponse
  {
    try validateAsset(asset)
    try validateHex(toAddress, bytes: 20, field: "destination")
    _ = try requireWallet()
    let token = try await tokenIdentifier(asset: asset)
    let response: JSONValue
    if try await usesUnifiedCollateral() {
      response = try await sendAsset(
        destination: toAddress, amount: amount, token: token, destinationDex: "spot")
    } else {
      response = try await submitUser(
        type: "spotSend", primary: "SpotSend",
        parameters: [
          "destination": .string(toAddress.lowercased()), "amount": .string(try decimal(amount)),
          "token": .string(token),
        ], fields: [("destination", "string"), ("token", "string"), ("amount", "string")])
    }
    try expectDefault(response)
    return .init(status: "ok")
  }

  /// Sends USDC using `usdSend` for standard accounts or `sendAsset` for shared-collateral accounts.
  public func usdSend(destination: String, amount: Double) async throws -> UsdSendResponse {
    try validateHex(destination, bytes: 20, field: "destination")
    _ = try decimal(amount)
    let response: JSONValue
    if try await usesUnifiedCollateral() {
      response = try await sendAsset(
        destination: destination, amount: amount, token: tokenIdentifier(asset: 0),
        destinationDex: "")
    } else {
      response = try await submitUser(
        type: "usdSend", primary: "UsdSend",
        parameters: [
          "destination": .string(destination.lowercased()), "amount": .string(try decimal(amount)),
        ], fields: [("destination", "string"), ("amount", "string")])
    }
    try expectDefault(response)
    return .init(status: "ok")
  }

  private func usesUnifiedCollateral() async throws -> Bool {
    let wallet = try requireWallet()
    let mode = try await HyperliquidAPI(apiClient: apiClient).info(
      .init(type: .custom("userAbstraction"), parameters: ["user": .string(wallet.address)]))
    guard let abstraction = mode.string else { throw APIError.invalidResponse }
    return ["unifiedAccount", "portfolioMargin"].contains(abstraction)
  }

  private func tokenIdentifier(asset: Int) async throws -> String {
    let meta = try await HyperliquidAPI(apiClient: apiClient).info(.init(type: .spotMeta))
    guard case .array(let tokens) = meta["tokens"],
      let token = tokens.first(where: { $0["index"].number == Double(asset) }),
      let name = token["name"].string, let id = token["tokenId"].string
    else { throw ValidationError.malformedData(reason: "Unknown spot token index") }
    return name + ":" + id
  }

  private func sendAsset(destination: String, amount: Double, token: String, destinationDex: String)
    async throws -> JSONValue
  {
    try await submitUser(
      type: "sendAsset", primary: "SendAsset",
      parameters: [
        "destination": .string(destination.lowercased()), "sourceDex": .string("spot"),
        "destinationDex": .string(destinationDex), "token": .string(token),
        "amount": .string(try decimal(amount)), "fromSubAccount": .string(""),
      ],
      fields: [
        ("destination", "string"), ("sourceDex", "string"), ("destinationDex", "string"),
        ("token", "string"), ("amount", "string"), ("fromSubAccount", "string"),
      ], timeKey: "nonce")
  }

  /// Moves USDC into or out of one vault, requiring exactly one direction and six-decimal precision.
  public func vaultTransfer(vaultTransfer: VaultTransfer) async throws -> VaultTransferResponse {
    guard vaultTransfer.fromVault != vaultTransfer.toVault else {
      throw ValidationError.malformedData(reason: "Select exactly one vault transfer direction")
    }
    guard let address = vaultTransfer.vaultAddress else {
      throw ValidationError.missingRequiredField(field: "vaultAddress")
    }
    try validateHex(address, bytes: 20, field: "vaultAddress")
    _ = try decimal(vaultTransfer.usdcAmount)
    let usd = vaultTransfer.usdcAmount * 1_000_000
    guard usd < 9_007_199_254_740_992, abs(usd.rounded() - usd) < 0.001 else {
      throw ValidationError.malformedData(reason: "USDC amount must fit six decimal places")
    }
    try expectDefault(
      await submit(
        Object([
          ("type", .string("vaultTransfer")), ("vaultAddress", .string(address.lowercased())),
          ("isDeposit", .bool(vaultTransfer.toVault)), ("usd", .number(usd.rounded())),
        ])))
    return .init(status: "ok")
  }

  /// Rejects approval without a fee limit; use `updateBuilder(builderAddress:maxFeeRate:)` instead.
  public func updateBuilder(builderAddress: String) async throws -> UpdateBuilderResponse {
    throw ValidationError.missingRequiredField(
      field: "maxFeeRate; use updateBuilder(builderAddress:maxFeeRate:)")
  }

  /// Approves a builder with an explicit percentage string from `0%` through `1%`.
  public func updateBuilder(builderAddress: String, maxFeeRate: String) async throws
    -> UpdateBuilderResponse
  {
    try validateHex(builderAddress, bytes: 20, field: "builder")
    guard maxFeeRate.hasSuffix("%"), let rate = Double(maxFeeRate.dropLast()), rate.isFinite,
      rate >= 0, rate <= 1
    else {
      throw ValidationError.invalidFieldFormat(
        field: "maxFeeRate", expected: "percentage from 0% through 1%")
    }
    let response = try await submitUser(
      type: "approveBuilderFee", primary: "ApproveBuilderFee",
      parameters: [
        "builder": .string(builderAddress.lowercased()), "maxFeeRate": .string(maxFeeRate),
      ], fields: [("maxFeeRate", "string"), ("builder", "address")], timeKey: "nonce")
    try expectDefault(response)
    return .init(status: "ok")
  }

  /// Schedules exchange-side cancellation at least five seconds ahead, subject to server eligibility.
  public func scheduleCancel(time: Date) async throws -> ScheduleCancelResponse {
    let milliseconds = time.timeIntervalSince1970 * 1_000
    guard milliseconds.isFinite, milliseconds >= (Date().timeIntervalSince1970 + 5) * 1_000,
      milliseconds < 9_007_199_254_740_992
    else {
      throw ValidationError.invalidFieldFormat(
        field: "time", expected: "at least five seconds in the future")
    }
    try expectDefault(
      await submit(
        Object([
          ("type", .string("scheduleCancel")), ("time", .number(milliseconds.rounded(.down))),
        ])))
    return .init(
      status: "ok", scheduledTime: Date(timeIntervalSince1970: milliseconds.rounded(.down) / 1_000))
  }

  /// Referrer is a referral code, not a wallet address.
  public func setReferrer(referrer: String) async throws -> SetReferrerResponse {
    guard !referrer.isEmpty else {
      throw ValidationError.missingRequiredField(field: "referral code")
    }
    try expectDefault(
      await submit(Object([("type", .string("setReferrer")), ("code", .string(referrer))])))
    return .init(status: "ok")
  }

  /// Rejects conversion without explicit signer addresses and a signature threshold.
  public func convertToMultiSigUser() async throws -> ConvertToMultiSigResponse {
    throw ValidationError.missingRequiredField(
      field: "authorizedUsers and threshold; use convertToMultiSigUser(authorizedUsers:threshold:)")
  }

  /// Converts the account using unique signer addresses and a threshold within the signer count.
  public func convertToMultiSigUser(authorizedUsers: [String], threshold: Int) async throws
    -> ConvertToMultiSigResponse
  {
    let users = authorizedUsers.map { $0.lowercased() }.sorted()
    for user in users { try validateHex(user, bytes: 20, field: "authorizedUsers") }
    guard !users.isEmpty, Set(users).count == users.count, threshold >= 1, threshold <= users.count
    else {
      throw ValidationError.malformedData(
        reason: "Multisig requires unique signers and a threshold from 1 through the signer count")
    }
    let signers = try JSONEncoder().encode([
      "authorizedUsers": JSONValue.array(users.map { .string($0) }),
      "threshold": .number(Double(threshold)),
    ])
    let response = try await submitUser(
      type: "convertToMultiSigUser", primary: "ConvertToMultiSigUser",
      parameters: ["signers": .string(String(decoding: signers, as: UTF8.self))],
      fields: [("signers", "string")], timeKey: "nonce")
    try expectDefault(response)
    return .init(status: "ok")
  }

  private func expectDefault(_ response: JSONValue) throws {
    guard response["type"].string == "default" else { throw APIError.invalidResponse }
  }

  private func decimal(_ value: Double) throws -> String {
    guard value.isFinite, value > 0 else {
      throw ValidationError.outOfRange(
        field: "amount/size/price", min: Double.leastNonzeroMagnitude, max: nil)
    }
    var string = String(format: "%.8f", locale: Locale(identifier: "en_US_POSIX"), value)
    guard let rounded = Double(string), abs(rounded - value) < 1e-12 else {
      throw ValidationError.malformedData(reason: "Value exceeds eight decimal places")
    }
    while string.last == "0" { string.removeLast() }
    if string.last == "." { string.removeLast() }
    guard rounded > 0 else { throw ValidationError.malformedData(reason: "Value rounds to zero") }
    return string
  }

  private func validateAsset(_ asset: Int) throws {
    guard asset >= 0, asset <= Int(UInt32.max) else {
      throw ValidationError.outOfRange(field: "asset", min: 0, max: Double(UInt32.max))
    }
  }

  private func isHex(_ byte: UInt8) -> Bool {
    (48...57).contains(byte) || (65...70).contains(byte) || (97...102).contains(byte)
  }

  private func validateHex(_ value: String, bytes: Int, field: String) throws {
    guard value.hasPrefix("0x"), value.utf8.count == bytes * 2 + 2,
      value.dropFirst(2).utf8.allSatisfy(isHex)
    else {
      throw ValidationError.invalidFieldFormat(
        field: field, expected: "0x followed by \(bytes * 2) hexadecimal characters")
    }
  }

  private func orderID(_ value: String) throws -> Double {
    guard !value.isEmpty, value.utf8.allSatisfy({ (48...57).contains($0) }), let id = UInt64(value),
      id > 0, id < 9_007_199_254_740_992
    else {
      throw ValidationError.invalidFieldFormat(
        field: "orderId", expected: "positive integer below 2^53")
    }
    return Double(id)
  }

  private func orderIDString(_ value: Double) throws -> String {
    guard value > 0, value < 9_007_199_254_740_992, value.rounded() == value else {
      throw APIError.invalidResponse
    }
    return String(UInt64(value))
  }
}

actor ExchangeNonce {
  private var last: Int64 = 0
  func next() -> Int64 {
    last = max(last + 1, Int64(Date().timeIntervalSince1970 * 1_000))
    return last
  }
}

private extension JSONValue {
  subscript(_ key: String) -> JSONValue {
    guard case .object(let object) = self else { return .null }
    return object[key] ?? .null
  }
  var string: String? { if case .string(let value) = self { return value }; return nil }
  var number: Double? { if case .number(let value) = self { return value }; return nil }
}
