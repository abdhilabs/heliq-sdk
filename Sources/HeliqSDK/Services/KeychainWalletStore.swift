//
//  KeychainWalletStore.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 23/10/26.
//

import Foundation
import LocalAuthentication
import Security

/// Failures accessing a local wallet. No case contains key material.
public enum KeychainWalletError: Error, Sendable, Equatable {
  /// An item already exists; storage never updates or replaces it.
  case duplicateKey
  /// The user or system cancelled authentication.
  case authenticationCancelled
  /// Authentication failed, including unavailable authentication credentials.
  case authenticationFailed
  /// Interaction is unavailable, for example while locked or in the background.
  case interactionNotAllowed
  /// The Keychain service or required device protection is unavailable.
  case unavailable
  /// An unclassified Security framework status, without secret data.
  case unexpectedStatus(Int32)
}

/// Device-only, passcode-required storage for a secp256k1 wallet private key.
/// Reads require system user presence. Explicit export requires fresh authentication.
public final class KeychainWalletStore: @unchecked Sendable {
  private let service: String
  private let authenticationContext: LAContext?
  private let client: KeychainClient

  /// Creates a store in the app's default Keychain access group.
  /// Supply a context to control localized prompts, interaction, and authentication reuse.
  /// Do not mutate or invalidate a supplied context during an operation.
  public init(service: String = "com.heliq.sdk.local-wallet",
    authenticationContext: LAContext? = nil) {
    self.service = service
    self.authenticationContext = authenticationContext
    self.client = .system
  }

  init(service: String, authenticationContext: LAContext? = nil, client: KeychainClient) {
    self.service = service
    self.authenticationContext = authenticationContext
    self.client = client
  }

  /// Validates and adds a key atomically. An existing item is never overwritten.
  /// This does not authenticate the user; reading the stored key does.
  public func store(privateKey: String, for key: String) throws {
    var data = try Signer.decodePrivateKey(privateKey)
    defer { data.resetBytes(in: 0..<data.count) }
    _ = try Signer(privateKeyData: data)
    var accessError: Unmanaged<CFError>?
    guard let access = SecAccessControlCreateWithFlags(nil,
      kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .userPresence, &accessError)
    else {
      _ = accessError?.takeRetainedValue()
      throw KeychainWalletError.unavailable
    }
    var query = query(for: key)
    query[kSecAttrAccessControl as String] = access
    query[kSecValueData as String] = data
    try Self.check(client.add(query as CFDictionary))
  }

  /// Deletes exactly this item. Missing items throw `SigningError.keyNotFound`.
  /// Keychain deletion does not require user presence; apps must authorize destructive actions.
  public func deleteKey(for key: String) throws {
    try Self.check(client.delete(query(for: key) as CFDictionary))
  }

  /// Exports a 0x-prefixed account private key after fresh device-owner authentication.
  /// Never reuses the store's signing context. The caller owns the returned secret's lifetime
  /// and must not log or transmit it to a backend or telemetry.
  public func exportPrivateKey(for key: String,
    authenticationReason: String) async throws -> String {
    guard !authenticationReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw KeychainWalletError.authenticationFailed
    }
    let context = LAContext()
    context.localizedReason = authenticationReason
    context.touchIDAuthenticationAllowableReuseDuration = 0
    defer { context.invalidate() }
    try Task.checkCancellation()
    do {
      guard try await client.authenticate(context, authenticationReason) else {
        throw KeychainWalletError.authenticationFailed
      }
    } catch let error as LAError {
      if [.userCancel, .appCancel, .systemCancel].contains(error.code) {
        throw KeychainWalletError.authenticationCancelled
      }
      if error.code == .notInteractive {
        throw KeychainWalletError.interactionNotAllowed
      }
      if [.passcodeNotSet, .biometryNotAvailable, .biometryNotEnrolled, .invalidContext]
        .contains(error.code) {
        throw KeychainWalletError.unavailable
      }
      throw KeychainWalletError.authenticationFailed
    }
    try Task.checkCancellation()
    var data = try loadPrivateKey(for: key, context: context)
    defer { data.resetBytes(in: 0..<data.count) }
    _ = try Signer(privateKeyData: data)
    return "0x" + data.hexString
  }

  func loadSigner(for key: String) throws -> Signer {
    // Never keep an SDK-owned authentication session between reads.
    let context = authenticationContext ?? LAContext()
    if authenticationContext == nil {
      context.localizedReason = "Access your local wallet"
    }
    var data = try loadPrivateKey(for: key, context: context)
    defer { data.resetBytes(in: 0..<data.count) }
    return try Signer(privateKeyData: data)
  }

  private func loadPrivateKey(for key: String, context: LAContext) throws -> Data {
    var query = query(for: key)
    query[kSecReturnData as String] = true
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecUseAuthenticationContext as String] = context
    var result: CFTypeRef?
    try Self.check(client.copy(query as CFDictionary, &result))
    guard let data = result as? Data else { throw SigningError.invalidPrivateKey }
    return data
  }

  private func query(for key: String) -> [String: Any] {
    [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: key,
      kSecAttrSynchronizable as String: false,
      // Use the data-protection Keychain on macOS too, never the legacy file Keychain.
      kSecUseDataProtectionKeychain as String: true,
    ]
  }

  private static func check(_ status: OSStatus) throws {
    switch status {
    case errSecSuccess: return
    case errSecItemNotFound: throw SigningError.keyNotFound
    case errSecDuplicateItem: throw KeychainWalletError.duplicateKey
    case errSecUserCanceled: throw KeychainWalletError.authenticationCancelled
    case errSecAuthFailed: throw KeychainWalletError.authenticationFailed
    case errSecInteractionNotAllowed: throw KeychainWalletError.interactionNotAllowed
    case errSecNotAvailable: throw KeychainWalletError.unavailable
    default: throw KeychainWalletError.unexpectedStatus(status)
    }
  }
}

// Only platform calls are replaceable in tests; policy and error mapping run unchanged.
struct KeychainClient: Sendable {
  let add: @Sendable (CFDictionary) -> OSStatus
  let copy: @Sendable (CFDictionary, UnsafeMutablePointer<CFTypeRef?>) -> OSStatus
  let delete: @Sendable (CFDictionary) -> OSStatus
  let authenticate: @Sendable (LAContext, String) async throws -> Bool

  static let system = KeychainClient(
    add: { SecItemAdd($0, nil) },
    copy: { SecItemCopyMatching($0, $1) },
    delete: { SecItemDelete($0) },
    authenticate: { try await $0.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: $1) })
}
