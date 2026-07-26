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

/// Native signer for Hyperliquid L1 actions. User-signed administrative actions
/// remain explicit until each official EIP-712 schema has a golden fixture.
public final class Signer: @unchecked Sendable {
  private let privateKeyData: Data
  private let keystore: PlainKeystore
  private let account: EthereumAddress

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

  /// Signs an official Hyperliquid L1 action using canonical MessagePack,
  /// the Exchange EIP-712 domain, and the protocol phantom Agent envelope.
  public func signL1(
    action: CanonicalMessagePack.Object,
    nonce: Int64,
    vaultAddress: String? = nil,
    expiresAfter: Int64? = nil,
    isMainnet: Bool
  ) async throws -> SignatureTypes {
    let hash = try Self.actionHash(action: action, nonce: nonce, vaultAddress: vaultAddress, expiresAfter: expiresAfter)
    let connectionID = hash.hexString
    let typedData = try EIP712Parser.parse("""
    {"types":{"EIP712Domain":[{"name":"name","type":"string"},{"name":"version","type":"string"},{"name":"chainId","type":"uint256"},{"name":"verifyingContract","type":"address"}],"Agent":[{"name":"source","type":"string"},{"name":"connectionId","type":"bytes32"}]},"primaryType":"Agent","domain":{"name":"Exchange","version":"1","chainId":1337,"verifyingContract":"0x0000000000000000000000000000000000000000"},"message":{"source":"\(isMainnet ? "a" : "b")","connectionId":"0x\(connectionID)"}}
    """)
    let rawSignature = try Web3Signer.signEIP712(typedData, keystore: keystore, account: account)
    guard rawSignature.count == 65 else { throw SigningError.signingFailed(reason: "Invalid compact signature") }
    return SignatureTypes(
      r: "0x" + rawSignature.prefix(32).hexString.drop(while: { $0 == "0" }),
      s: "0x" + rawSignature.dropFirst(32).prefix(32).hexString.drop(while: { $0 == "0" }),
      v: Int(rawSignature[64]),
      signatureType: .eoa
    )
  }

  public var address: String { account.address.lowercased() }

  private static func append(_ value: UInt64, to data: inout Data) {
    var bigEndian = value.bigEndian
    withUnsafeBytes(of: &bigEndian) { data.append(contentsOf: $0) }
  }
}
