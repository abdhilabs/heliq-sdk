//
//  Signer.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import CryptoSwift
import Web3Core
import web3swift

/// Represents hyperliquid eip712 field data.
public struct HyperliquidEIP712Field: Sendable, Codable, Equatable {
  /// The name.
  public let name: String
  /// The type.
  public let type: String

  /// Creates a hyperliquid eip712 field.
  public init(name: String, type: String) {
    self.name = name
    self.type = type
  }
}

/// Native signer for Hyperliquid L1 actions. User-signed administrative actions
/// remain explicit until each official EIP-712 schema has a golden fixture.
public final class Signer: @unchecked Sendable {
  private let privateKeyData: Data
  private let keystore: PlainKeystore
  private let account: EthereumAddress

  /// Creates a signer.
  public init(privateKey: String) throws {
    let cleanedKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
    guard let keyData = Data(hexString: cleanedKey), keyData.count == 32,
          let keystore = PlainKeystore(privateKey: keyData),
          let account = keystore.addresses?.first else {
      throw SigningError.invalidPrivateKey
    }
    self.privateKeyData = keyData
    self.keystore = keystore
    self.account = account
  }

  /// Legacy arbitrary-message signing is intentionally unsupported because it
  /// is not a Hyperliquid protocol signing scheme.
  public func sign(message: String) async throws -> SignatureTypes {
    throw SigningError.signingFailed(reason: "Use signL1(action:nonce:isMainnet:) for Hyperliquid L1 actions")
  }

  /// Computes action hash.
  public static func actionHash(
    action: CanonicalMessagePack.Object,
    nonce: Int64,
    vaultAddress: String? = nil,
    expiresAfter: Int64? = nil
  ) throws -> Data {
    guard nonce >= 0 else { throw SigningError.signingFailed(reason: "Nonce must be non-negative") }
    var hashInput = try CanonicalMessagePack.encode(action)
    append(UInt64(nonce), to: &hashInput)
    if let vaultAddress {
      guard let bytes = Data(hexString: vaultAddress), bytes.count == 20 else {
        throw SigningError.signingFailed(reason: "Invalid vault address")
      }
      hashInput.append(1)
      hashInput.append(bytes)
    } else {
      hashInput.append(0)
    }
    if let expiresAfter {
      guard expiresAfter >= 0 else { throw SigningError.signingFailed(reason: "expiresAfter must be non-negative") }
      hashInput.append(0)
      append(UInt64(expiresAfter), to: &hashInput)
    }
    return hashInput.sha3(.keccak256)
  }

  /// Signs an official user-signed Hyperliquid action (transfers, withdrawals,
  /// agent approvals, and other schemas supplied by the caller).
  public func signUserSigned(
    primaryType: String,
    fields: [HyperliquidEIP712Field],
    action: [String: JSONValue],
    isMainnet: Bool
  ) async throws -> SignatureTypes {
    let startedAt = Date()
    do {
      guard !primaryType.isEmpty, !fields.isEmpty else {
      throw SigningError.signingFailed(reason: "EIP-712 primary type and fields are required")
    }
    var message = action
    message["signatureChainId"] = .string("0x66eee")
    message["hyperliquidChain"] = .string(isMainnet ? "Mainnet" : "Testnet")
    let typeFields = fields.map { ["name": $0.name, "type": $0.type] }
    let domainFields: [[String: String]] = [
      ["name": "name", "type": "string"], ["name": "version", "type": "string"],
      ["name": "chainId", "type": "uint256"], ["name": "verifyingContract", "type": "address"]
    ]
    let payload: [String: Any] = [
      "types": [primaryType: typeFields, "EIP712Domain": domainFields],
      "primaryType": primaryType,
      "domain": ["name": "HyperliquidSignTransaction", "version": "1", "chainId": 421_614, "verifyingContract": "0x0000000000000000000000000000000000000000"],
      "message": try jsonObject(message)
    ]
    let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
    let typedData = try EIP712Parser.parse(String(decoding: data, as: UTF8.self))
    let signed = try signature(typedData)
    let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1_000)
    Logger.shared.info("signing operation=user-signed outcome=success elapsed_ms=\(elapsedMs)", category: .signing)
    return signed
    } catch {
      let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1_000)
      Logger.shared.error("signing operation=user-signed outcome=failure elapsed_ms=\(elapsedMs)", category: .signing)
      throw error
    }
  }

  /// Signs an official Hyperliquid L1 action using canonical MessagePack,
  /// the Exchange EIP-712 domain, and the protocol phantom Agent envelope.
  public func signL1(
    action: CanonicalMessagePack.Object,
    nonce: Int64,
    vaultAddress: String? = nil,
    expiresAfter: Int64? = nil,
    isMainnet: Bool
  ) async throws -> SignatureTypes {
    let startedAt = Date()
    do {
      let hash = try Self.actionHash(action: action, nonce: nonce, vaultAddress: vaultAddress, expiresAfter: expiresAfter)
    let connectionID = hash.hexString
    let typedData = try EIP712Parser.parse("""
    {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"version","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],"Agent":[{"name":"source","type":"string"},{"name":"connectionId","type":"bytes32"}]},"primaryType":"Agent","domain":{"name":"Exchange","version":"1","chainId":1337,"verifyingContract":"0x0000000000000000000000000000000000000000"},"message":{"source":"\(isMainnet ? "a" : "b")","connectionId":"0x\(connectionID)"}}
    """)
    let signed = try signature(typedData)
    let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1_000)
    Logger.shared.info("signing operation=l1 outcome=success elapsed_ms=\(elapsedMs)", category: .signing)
    return signed
    } catch {
      let elapsedMs = Int(Date().timeIntervalSince(startedAt) * 1_000)
      Logger.shared.error("signing operation=l1 outcome=failure elapsed_ms=\(elapsedMs)", category: .signing)
      throw error
    }
  }

  /// The address.
  public var address: String { account.address.lowercased() }

  private func signature(_ typedData: EIP712TypedData) throws -> SignatureTypes {
    let rawSignature = try Web3Signer.signEIP712(typedData, keystore: keystore, account: account)
    guard rawSignature.count == 65 else { throw SigningError.signingFailed(reason: "Invalid compact signature") }
    return SignatureTypes(
      r: "0x" + rawSignature.prefix(32).hexString.drop(while: { $0 == "0" }),
      s: "0x" + rawSignature.dropFirst(32).prefix(32).hexString.drop(while: { $0 == "0" }),
      v: Int(rawSignature[64]),
      signatureType: .eoa
    )
  }

  private func jsonObject(_ value: [String: JSONValue]) throws -> [String: Any] {
    let data = try JSONEncoder().encode(value)
    guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw SigningError.signingFailed(reason: "Unable to encode EIP-712 message")
    }
    return object
  }

  private static func append(_ value: UInt64, to data: inout Data) {
    var bigEndian = value.bigEndian
    withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
  }
}
