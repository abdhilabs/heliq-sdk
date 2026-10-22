//
//  PerpsExchangeRepository.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

struct PreparedPerpsAction: Sendable {
  let object: CanonicalMessagePack.Object
  let primary: String?
  let fields: [HyperliquidEIP712Field]
  let nonceInL1: Bool
  let timeKey: String
  /// Stores a canonical action and optional user-signing schema for shared submission handling.
  init(
    _ object: CanonicalMessagePack.Object, primary: String? = nil,
    fields: [(String, String)] = [], timeKey: String = "nonce", nonceInL1: Bool = false
  ) {
    self.nonceInL1 = nonceInL1
    self.object = object
    self.primary = primary
    self.fields = fields.map { .init(name: $0.0, type: $0.1) }
    self.timeKey = timeKey
  }
}

extension ExchangeRepositoryImpl {
  /// Validates, signs, and submits one typed exchange action without automatic retries.
  public func executePerps(_ action: PerpsAction, context: PerpsExecutionContext) async throws
    -> PerpsActionResult
  {
    let wallet = try requireWallet()
    if let address = context.vaultAddress { try perpsAddress(address) }
    if let expiry = context.expiresAfter { _ = try perpsMilliseconds(expiry) }
    let prepared = try await preparePerps(action, context: context)
    let nonce: Int64
    if case .invalidateNonce(let value) = action {
      _ = try perpsInteger(value)
      nonce = value
    } else {
      nonce = await Self.nonces.next()
    }
    let l1Object = perpsL1Object(prepared, nonce: nonce)
    var body = CanonicalMessagePack.json(l1Object)
    let signature: SignatureTypes
    if let primary = prepared.primary {
      guard context.vaultAddress == nil, context.expiresAfter == nil else {
        throw ValidationError.malformedData(
          reason: "User-signed actions do not accept vaultAddress or expiry")
      }
      body = userPerpsBody(prepared, nonce: nonce)
      signature = try await wallet.signUserSigned(
        primaryType: primary,
        fields: userPerpsFields(prepared), action: body,
        isMainnet: apiClient.environment == .mainnet)
    } else {
      signature = try await wallet.signL1Payload(
        .object(l1Object), nonce: nonce,
        vaultAddress: context.vaultAddress,
        expiresAfter: try context.expiresAfter.map(perpsMilliseconds),
        isMainnet: apiClient.environment == .mainnet)
    }
    return try decodePerpsResult(
      try await post(action: body, nonce: nonce, signature: signature, context: context),
      action: action)
  }

  /// Adds the selected network, signing chain, and exact nonce to a user-signed action.
  func userPerpsBody(_ prepared: PreparedPerpsAction, nonce: Int64) -> [String: JSONValue] {
    var body = CanonicalMessagePack.json(prepared.object)
    body[prepared.timeKey] = .protocolInteger(nonce)
    body["signatureChainId"] = .string("0x66eee")
    body["hyperliquidChain"] = .string(apiClient.environment == .mainnet ? "Mainnet" : "Testnet")
    return body
  }
  /// Builds the ordered EIP-712 field schema for a user-signed action.
  func userPerpsFields(_ prepared: PreparedPerpsAction) -> [HyperliquidEIP712Field] {
    [.init(name: "hyperliquidChain", type: "string")] + prepared.fields + [
      .init(name: prepared.timeKey, type: "uint64")
    ]
  }

  /// Resolves metadata and validates action parameters before constructing the ordered signing
  /// payload.
  func preparePerps(
    _ action: PerpsAction, context: PerpsExecutionContext, actingUser: String? = nil
  ) async throws -> PreparedPerpsAction {
    typealias V = CanonicalMessagePack.Value
    typealias O = CanonicalMessagePack.Object
    let info = InfoRepositoryImpl(apiClient: apiClient)
    /// Builds an L1 action with the action type first in canonical field order.
    func l1(_ type: String, _ fields: [(String, V)] = []) -> PreparedPerpsAction {
      .init(O([("type", .string(type))] + fields))
    }
    /// Builds a user-signed action with its ordered EIP-712 schema and timestamp field.
    func user(
      _ type: String, _ primary: String, _ fields: [(String, V)], _ schema: [(String, String)],
      time: String = "nonce"
    ) -> PreparedPerpsAction {
      .init(
        O([("type", .string(type))] + fields), primary: "HyperliquidTransaction:" + primary,
        fields: schema, timeKey: time)
    }
    switch action {
    case .orders(let orders, let grouping, let builder):
      guard !orders.isEmpty else { throw ValidationError.missingRequiredField(field: "orders") }
      var wires: [V] = []
      for order in orders { wires.append(.object(try await perpsOrderWire(order))) }
      var fields: [(String, V)] = [
        ("orders", .array(wires)), ("grouping", .string(grouping.rawValue)),
      ]
      if let builder {
        try perpsAddress(builder.address)
        guard (0...100).contains(builder.fee) else { throw APIError.invalidResponse }
        fields.append(
          (
            "builder",
            .object(
              O([
                ("b", .string(builder.address.lowercased())),
                ("f", try perpsInteger(Int64(builder.fee), allowZero: true)),
              ]))
          ))
      }
      return l1("order", fields)
    case .cancel(let requests, let fast):
      guard !requests.isEmpty else { throw ValidationError.missingRequiredField(field: "cancels") }
      let usesCloid: Bool
      if case .cloid = requests[0].identifier { usesCloid = true } else { usesCloid = false }
      var cancels: [V] = []
      for request in requests {
        let resolved = try await resolvePerpsMarket(request.market)
        let identifier = try perpsIdentifier(request.identifier)
        if usesCloid {
          guard case .string = identifier else {
            throw ValidationError.malformedData(
              reason: "Do not mix OIDs and client IDs in one cancellation batch")
          }
        } else {
          if case .string = identifier {
            throw ValidationError.malformedData(
              reason: "Do not mix OIDs and client IDs in one cancellation batch")
          }
        }
        cancels.append(
          .object(
            O([
              (usesCloid ? "asset" : "a", .number(Double(resolved.id))),
              (usesCloid ? "cloid" : "o", identifier),
            ])))
      }
      var fields: [(String, V)] = [("cancels", .array(cancels))]
      if fast { fields.append(("f", .bool(true))) }
      return l1(usesCloid ? "cancelByCloid" : "cancel", fields)
    case .modify(let requests, let alwaysPlace):
      guard !requests.isEmpty else { throw ValidationError.missingRequiredField(field: "modifies") }
      var items: [V] = []
      for request in requests {
        let fields: [(String, V)] = [
          ("oid", try perpsIdentifier(request.identifier)),
          ("order", .object(try await perpsOrderWire(request.order))),
        ]
        try validatePerpsModification(request.order, alwaysPlace: alwaysPlace)
        items.append(.object(O(fields)))
      }
      var fields: [(String, V)] = [("modifies", .array(items))]
      if alwaysPlace { fields.append(("a", .bool(true))) }
      return l1("batchModify", fields)
    case .modifyOrder(let request, let alwaysPlace):
      try validatePerpsModification(request.order, alwaysPlace: alwaysPlace)
      var fields: [(String, V)] = [
        ("oid", try perpsIdentifier(request.identifier)),
        ("order", .object(try await perpsOrderWire(request.order))),
      ]
      if alwaysPlace { fields.append(("a", .bool(true))) }
      return l1("modify", fields)
    case .scheduleCancel(let time):
      return l1(
        "scheduleCancel", try time.map { [("time", try perpsInteger(perpsMilliseconds($0)))] } ?? []
      )
    case .leverage(let market, let value, let cross):
      let resolved = try await resolvePerpsMarket(market)
      guard value >= 1, value <= resolved.asset.maxLeverage,
        !cross
          || (resolved.asset.onlyIsolated != true && resolved.asset.marginMode != "strictIsolated"
            && resolved.asset.marginMode != "noCross")
      else { throw ValidationError.malformedData(reason: "Unsupported leverage or margin mode") }
      return l1(
        "updateLeverage",
        [
          ("asset", .number(Double(resolved.id))), ("isCross", .bool(cross)),
          ("leverage", .number(Double(value))),
        ])
    case .isolatedMargin(let market, let amount):
      let resolved = try await resolvePerpsMarket(market)
      guard amount >= 0 || resolved.asset.marginMode != "strictIsolated" else {
        throw ValidationError.malformedData(
          reason: "Strict isolated markets do not permit margin withdrawal")
      }
      return l1(
        "updateIsolatedMargin",
        [
          ("asset", .number(Double(resolved.id))), ("isBuy", .bool(true)),
          ("ntli", try perpsInteger(perpsMicroUnits(amount, signed: true), signed: true)),
        ])
    case .isolatedLeverage(let market, let leverage):
      let resolved = try await resolvePerpsMarket(market)
      guard leverage <= Decimal(resolved.asset.maxLeverage) else { throw APIError.invalidResponse }
      return l1(
        "topUpIsolatedOnlyMargin",
        [
          ("asset", .number(Double(resolved.id))),
          ("leverage", .string(try positivePerpsDecimal(leverage))),
        ])
    case .marketClose(let market, let size, let slippage):
      let resolved = try await resolvePerpsMarket(market)
      let address = try context.vaultAddress ?? actingUser ?? requireWallet().address
      let state = try await info.perps(.account(address: address, dex: resolved.dex))
      guard
        let position = state.assetPositions.first(where: { $0.position.coin == resolved.asset.name }
        )?.position, position.szi != 0
      else {
        throw ValidationError.malformedData(reason: "No open position to close")
      }
      let amount = size ?? abs(position.szi)
      guard amount <= abs(position.szi) else {
        throw ValidationError.malformedData(reason: "Close size exceeds position")
      }
      return try await preparePerps(
        .orders([
          .init(
            market: market, side: position.szi > 0 ? .sell : .buy,
            size: amount, kind: .market(slippage: slippage), reduceOnly: true)
        ]), context: context)
    case .twap(let market, let side, let size, let minutes, let reduce, let random):
      let resolved = try await resolvePerpsMarket(market)
      guard (5...1440).contains(minutes) else {
        throw ValidationError.malformedData(reason: "TWAP duration must be 5...1440 minutes")
      }
      try validatePerpsPrecision(size, decimals: resolved.asset.szDecimals)
      return l1(
        "twapOrder",
        [
          (
            "twap",
            .object(
              O([
                ("a", .number(Double(resolved.id))), ("b", .bool(side == .buy)),
                ("s", .string(try positivePerpsDecimal(size))), ("r", .bool(reduce)),
                ("m", .number(Double(minutes))), ("t", .bool(random)),
              ]))
          )
        ])
    case .cancelTwap(let market, let id):
      return l1(
        "twapCancel",
        [
          ("a", .number(Double(try await resolvePerpsMarket(market).id))),
          ("t", try perpsInteger(id)),
        ])
    case .trailingStop(let market, let side, let size, let reduce, let retracement, let activation):
      let resolved = try await resolvePerpsMarket(market)
      try validatePerpsPrecision(size, decimals: resolved.asset.szDecimals)
      let retrace: V
      switch retracement {
      case .percent(let value):
        guard value < 100 else { throw APIError.invalidResponse }
        retrace = .object(O([("pct", .string(try positivePerpsDecimal(value) + "%"))]))
      case .price(let value):
        try validatePerpsPrice(value, decimals: resolved.asset.szDecimals)
        retrace = .object(O([("px", .string(try positivePerpsDecimal(value)))]))
      }
      if let activation { try validatePerpsPrice(activation, decimals: resolved.asset.szDecimals) }
      return l1(
        "trailingStop",
        [
          ("asset", .number(Double(resolved.id))), ("isBuy", .bool(side == .buy)),
          ("sz", .string(try positivePerpsDecimal(size))),
          ("reduceOnly", .bool(reduce)), ("retracement", retrace),
          ("activationPx", try activation.map { .string(try positivePerpsDecimal($0)) } ?? .null),
        ])
    case .usdClassTransfer(let amount, let toPerp):
      let mode = try await info.perps(.abstraction(address: actingUser ?? requireWallet().address))
      guard mode.supportsClassTransfer else {
        throw ValidationError.malformedData(
          reason: mode.hasSharedCollateral
            ? "Spot and Perps already share collateral; class transfer is unsupported"
            : "Class transfer requires an explicit standard account mode; current mode is \(mode.rawValue)"
        )
      }
      _ = try perpsMicroUnits(amount)
      return user(
        "usdClassTransfer", "UsdClassTransfer",
        [("amount", .string(try positivePerpsDecimal(amount))), ("toPerp", .bool(toPerp))],
        [("amount", "string"), ("toPerp", "bool")])
    case .sendAsset(let destination, let source, let ledger, let token, let amount, let sub):
      try perpsAddress(destination)
      if !sub.isEmpty { try perpsAddress(sub) }
      try await validatePerpsTransfer(token: token, amount: amount, ledgers: [source, ledger])
      return user(
        "sendAsset", "SendAsset",
        [
          ("destination", .string(destination.lowercased())), ("sourceDex", .string(source.wire)),
          ("destinationDex", .string(ledger.wire)),
          ("token", .string(token)), ("amount", .string(try positivePerpsDecimal(amount))),
          ("fromSubAccount", .string(sub.lowercased())),
        ],
        [
          ("destination", "string"), ("sourceDex", "string"), ("destinationDex", "string"),
          ("token", "string"), ("amount", "string"), ("fromSubAccount", "string"),
        ])
    case .agentSendAsset(let account, let source, let ledger, let token, let amount, let sub):
      try perpsAddress(account)
      if !sub.isEmpty { try perpsAddress(sub) }
      try await validatePerpsTransfer(token: token, amount: amount, ledgers: [source, ledger])
      return .init(
        O([
          ("type", .string("agentSendAsset")), ("destination", .string(account.lowercased())),
          ("sourceDex", .string(source.wire)), ("destinationDex", .string(ledger.wire)),
          ("token", .string(token)),
          ("amount", .string(try positivePerpsDecimal(amount))),
          ("fromSubAccount", .string(sub.lowercased())),
          ("nonce", .number(0)),
        ]), nonceInL1: true)
    case .approveAgent(let address, let name):
      try perpsAddress(address)
      return user(
        "approveAgent", "ApproveAgent",
        [("agentAddress", .string(address.lowercased())), ("agentName", .string(name ?? ""))],
        [("agentAddress", "address"), ("agentName", "string")])
    case .userAbstraction(let address, let mode):
      try perpsAddress(address)
      return user(
        "userSetAbstraction", "UserSetAbstraction",
        [("user", .string(address.lowercased())), ("abstraction", .string(mode.rawValue))],
        [("user", "address"), ("abstraction", "string")])
    case .agentAbstraction(let mode):
      return l1("agentSetAbstraction", [("abstraction", .string(mode.rawValue))])
    case .legacyUserDexAbstraction(let address, let enabled):
      try perpsAddress(address)
      return user(
        "userDexAbstraction", "UserDexAbstraction",
        [("user", .string(address.lowercased())), ("enabled", .bool(enabled))],
        [("user", "address"), ("enabled", "bool")])
    case .legacyAgentDexAbstraction: return l1("agentEnableDexAbstraction")
    case .createSubAccount(let name):
      guard !name.isEmpty else { throw ValidationError.missingRequiredField(field: "name") }
      return l1("createSubAccount", [("name", .string(name))])
    case .subAccountTransfer(let address, let deposit, let amount):
      try perpsAddress(address)
      return l1(
        "subAccountTransfer",
        [
          ("subAccountUser", .string(address.lowercased())), ("isDeposit", .bool(deposit)),
          ("usd", try perpsInteger(perpsMicroUnits(amount))),
        ])
    case .subAccountSpotTransfer(let address, let deposit, let token, let amount):
      try perpsAddress(address)
      try await validatePerpsTransfer(token: token, amount: amount, ledgers: [])
      return l1(
        "subAccountSpotTransfer",
        [
          ("subAccountUser", .string(address.lowercased())), ("isDeposit", .bool(deposit)),
          ("token", .string(token)), ("amount", .string(try positivePerpsDecimal(amount))),
        ])
    case .reserveRequestWeight(let weight, let destination):
      var fields: [(String, V)] = [("weight", try perpsInteger(Int64(weight)))]
      if let destination {
        try perpsAddress(destination)
        fields.append(("destination", .string(destination.lowercased())))
      }
      return l1("reserveRequestWeight", fields)
    case .invalidateNonce: return l1("noop")
    case .withdraw(let destination, let amount):
      try perpsAddress(destination)
      return user(
        "withdraw3", "Withdraw",
        [
          ("destination", .string(destination.lowercased())),
          ("amount", .string(try positivePerpsDecimal(amount))),
        ], [("destination", "string"), ("amount", "string")], time: "time")
    case .approveBuilder(let address, let percent):
      try perpsAddress(address)
      guard !percent.isNaN, percent >= 0, percent <= 1 else { throw APIError.invalidResponse }
      return user(
        "approveBuilderFee", "ApproveBuilderFee",
        [
          ("maxFeeRate", .string(try perpsDecimalString(percent) + "%")),
          ("builder", .string(address.lowercased())),
        ], [("maxFeeRate", "string"), ("builder", "address")])
    case .vaultTransfer(let address, let deposit, let amount):
      try perpsAddress(address)
      return l1(
        "vaultTransfer",
        [
          ("vaultAddress", .string(address.lowercased())), ("isDeposit", .bool(deposit)),
          ("usd", try perpsInteger(perpsMicroUnits(amount))),
        ])
    case .setReferrer(let code):
      guard !code.isEmpty else { throw APIError.invalidResponse }
      return l1("setReferrer", [("code", .string(code))])
    case .convertMultisig(let users, let threshold):
      let users = users.map { $0.lowercased() }.sorted()
      for address in users { try perpsAddress(address) }
      guard !users.isEmpty, users.count <= 10, Set(users).count == users.count,
        (1...users.count).contains(threshold)
      else { throw APIError.invalidResponse }
      let value: [String: JSONValue] = [
        "authorizedUsers": .array(users.map(JSONValue.string)),
        "threshold": .number(Double(threshold)),
      ]
      let encoder = JSONEncoder()
      encoder.outputFormatting = .sortedKeys
      let signers = String(decoding: try encoder.encode(value), as: UTF8.self)
      return user(
        "convertToMultiSigUser", "ConvertToMultiSigUser", [("signers", .string(signers))],
        [("signers", "string")])
    case .restoreNormalAccount:
      return user(
        "convertToMultiSigUser", "ConvertToMultiSigUser", [("signers", .string("null"))],
        [("signers", "string")])
    case .deploy(let deploy): return .init(try deploy.wire())
    case .liquidatorTransfer(let dex, let amount, let deposit):
      let units = try perpsMicroUnits(amount)
      guard !dex.isEmpty, units % 1_000_000_000 == 0 else {
        throw ValidationError.malformedData(
          reason: "Liquidator transfer must be a multiple of 1000 collateral tokens")
      }
      return user(
        "hip3LiquidatorTransfer", "Hip3LiquidatorTransfer",
        [("dex", .string(dex)), ("ntl", try perpsInteger(units)), ("isDeposit", .bool(deposit))],
        [("dex", "string"), ("ntl", "uint64"), ("isDeposit", "bool")])
    }
  }
}

/// Includes action-specific nonce fields in the canonical L1 payload when required.
func perpsL1Object(_ prepared: PreparedPerpsAction, nonce: Int64) -> CanonicalMessagePack.Object {
  guard prepared.nonceInL1 else { return prepared.object }
  return .init(
    prepared.object.fields.map { $0.0 == "nonce" ? ("nonce", perpsIntegerValue(nonce)) : $0 })
}

/// Preserves signed integer precision when constructing canonical action fields.
private func perpsIntegerValue(_ value: Int64) -> CanonicalMessagePack.Value {
  value >= 9_007_199_254_740_992 ? .signed(value) : .number(Double(value))
}
