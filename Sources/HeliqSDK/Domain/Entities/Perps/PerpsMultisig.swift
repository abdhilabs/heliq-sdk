//
//  PerpsMultisig.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

public struct PerpsMultisigSignature: Sendable {
  public let signer: String
  public let signature: SignatureTypes
  /// Associates a signer address with its signature over the prepared multisig payload.
  public init(signer: String, signature: SignatureTypes) {
    self.signer = signer
    self.signature = signature
  }
}
/// Resolved once so market prices and position size cannot change between signatures.
public struct PerpsMultisigPayload: Sendable {
  public let user: String
  public let leader: String
  public let action: PerpsAction
  public let nonce: Int64
  public let context: PerpsExecutionContext
  let prepared: PreparedPerpsAction
  let environment: HeliqEnvironment
}
public struct PerpsMultisigRequest: Sendable {
  public let payload: PerpsMultisigPayload
  public let signatures: [PerpsMultisigSignature]
  /// Collects signatures for one immutable prepared payload without changing its nonce or context.
  public init(payload: PerpsMultisigPayload, signatures: [PerpsMultisigSignature]) {
    self.payload = payload
    self.signatures = signatures
  }
  var user: String { payload.user }
  var leader: String { payload.leader }
  var action: PerpsAction { payload.action }
  var nonce: Int64 { payload.nonce }
  var context: PerpsExecutionContext { payload.context }
}

extension ExchangeRepositoryImpl {
  /// Freezes the resolved action, network, nonce, and context so every signer signs identical
  /// bytes.
  public func preparePerpsMultisig(
    action: PerpsAction, user: String, leader: String,
    nonce: Int64, context: PerpsExecutionContext
  ) async throws -> PerpsMultisigPayload {
    try perpsAddress(user)
    try perpsAddress(leader)
    _ = try perpsInteger(nonce)
    if let address = context.vaultAddress { try perpsAddress(address) }
    if case .invalidateNonce(let target) = action, target != nonce {
      throw ValidationError.malformedData(reason: "Noop nonce must match the multisig envelope")
    }
    let prepared = try await preparePerps(action, context: context, actingUser: user)
    if prepared.primary != nil, context.vaultAddress != nil || context.expiresAfter != nil {
      throw ValidationError.malformedData(
        reason: "User-signed multisig actions reject vault and expiry")
    }
    return .init(
      user: user.lowercased(), leader: leader.lowercased(), action: action, nonce: nonce,
      context: context, prepared: prepared, environment: apiClient.environment)
  }

  /// Signs the prepared payload with the configured wallet without resolving the action again.
  public func signPerpsMultisig(_ payload: PerpsMultisigPayload) async throws
    -> PerpsMultisigSignature
  {
    guard payload.environment == apiClient.environment else {
      throw ValidationError.malformedData(reason: "Multisig network mismatch")
    }
    let user = payload.user
    let leader = payload.leader
    let nonce = payload.nonce
    let context = payload.context
    let prepared = payload.prepared
    let wallet = try requireWallet()
    let signature: SignatureTypes
    if let primary = prepared.primary {
      guard context.vaultAddress == nil, context.expiresAfter == nil else {
        throw ValidationError.malformedData(
          reason: "User-signed multisig actions reject vault and expiry")
      }
      var body = userPerpsBody(prepared, nonce: nonce)
      body["payloadMultiSigUser"] = .string(user.lowercased())
      body["outerSigner"] = .string(leader.lowercased())
      var fields = userPerpsFields(prepared)
      fields.insert(
        contentsOf: [
          .init(name: "payloadMultiSigUser", type: "address"),
          .init(name: "outerSigner", type: "address"),
        ], at: 1)
      signature = try await wallet.signUserSigned(
        primaryType: primary, fields: fields, action: body,
        isMainnet: apiClient.environment == .mainnet)
    } else {
      signature = try await wallet.signL1Payload(
        .array([
          .string(user.lowercased()), .string(leader.lowercased()),
          .object(perpsL1Object(prepared, nonce: nonce)),
        ]),
        nonce: nonce, vaultAddress: context.vaultAddress,
        expiresAfter: try context.expiresAfter.map(perpsMilliseconds),
        isMainnet: apiClient.environment == .mainnet)
    }
    return .init(signer: wallet.address.lowercased(), signature: signature)
  }

  /// Validates the collected signatures and submits the prepared multisig action once.
  public func executeMultisig(_ request: PerpsMultisigRequest) async throws -> PerpsActionResult {
    typealias O = CanonicalMessagePack.Object
    typealias V = CanonicalMessagePack.Value
    try perpsAddress(request.user)
    try perpsAddress(request.leader)
    _ = try perpsInteger(request.nonce)
    let wallet = try requireWallet()
    guard wallet.address.lowercased() == request.leader.lowercased(),
      !request.signatures.isEmpty, request.signatures.count <= 10,
      Set(request.signatures.map { $0.signer.lowercased() }).count == request.signatures.count
    else {
      throw ValidationError.malformedData(
        reason: "Multisig needs unique signatures and the configured leader wallet")
    }
    guard request.payload.environment == apiClient.environment else {
      throw ValidationError.malformedData(reason: "Multisig network mismatch")
    }
    let prepared = request.payload.prepared
    var inner = perpsL1Object(prepared, nonce: request.nonce)
    if prepared.primary != nil {
      guard request.context.vaultAddress == nil, request.context.expiresAfter == nil else {
        throw APIError.invalidResponse
      }
      // Preserve the official user-action field order inside the outer action hash.
      inner = O(
        [
          inner.fields[0], ("signatureChainId", .string("0x66eee")),
          ("hyperliquidChain", .string(apiClient.environment == .mainnet ? "Mainnet" : "Testnet")),
        ]
          + Array(inner.fields.dropFirst()) + [(prepared.timeKey, try perpsInteger(request.nonce))])
    }
    let signatures: [V] = try request.signatures.map {
      try perpsAddress($0.signer)
      for component in [$0.signature.r, $0.signature.s] {
        let hex = component.hasPrefix("0x") ? component.dropFirst(2) : ""[...]
        guard !hex.isEmpty, hex.utf8.count <= 64,
          hex.utf8.allSatisfy({
            (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
          }),
          hex.contains(where: { $0 != "0" })
        else {
          throw SigningError.signingFailed(reason: "Invalid multisig signature component")
        }
      }
      guard [27, 28].contains($0.signature.v) else {
        throw SigningError.signingFailed(reason: "Invalid multisig recovery ID")
      }
      return .object(
        O([
          ("r", .string($0.signature.r)), ("s", .string($0.signature.s)),
          ("v", .number(Double($0.signature.v))),
        ]))
    }
    let unsigned = O([
      ("signatureChainId", .string("0x66eee")), ("signatures", .array(signatures)),
      (
        "payload",
        .object(
          O([
            ("multiSigUser", .string(request.user.lowercased())),
            ("outerSigner", .string(request.leader.lowercased())), ("action", .object(inner)),
          ]))
      ),
    ])
    let expiry = try request.context.expiresAfter.map(perpsMilliseconds)
    let hash = try Signer.actionHash(
      action: unsigned, nonce: request.nonce,
      vaultAddress: request.context.vaultAddress, expiresAfter: expiry)
    let signature = try await wallet.signUserSigned(
      primaryType: "HyperliquidTransaction:SendMultiSig",
      fields: [
        .init(name: "hyperliquidChain", type: "string"),
        .init(name: "multiSigActionHash", type: "bytes32"), .init(name: "nonce", type: "uint64"),
      ],
      action: [
        "multiSigActionHash": .string("0x" + hash.map { String(format: "%02x", $0) }.joined()),
        "nonce": .protocolInteger(request.nonce),
      ], isMainnet: apiClient.environment == .mainnet)
    var body = CanonicalMessagePack.json(unsigned)
    body["type"] = .string("multiSig")
    let response = try await post(
      action: body, nonce: request.nonce, signature: signature, context: request.context)
    return try decodePerpsResult(response, action: request.action)
  }
}
