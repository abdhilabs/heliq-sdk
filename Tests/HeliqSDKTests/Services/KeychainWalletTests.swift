//
//  KeychainWalletTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 23/10/26.
//

import Foundation
import LocalAuthentication
import Security
import Testing

@testable import HeliqSDK

struct KeychainWalletTests {
  // Public, unfunded fixture key, also used by the independent signing vectors.
  private let fixtureKey =
    "0x0123456789012345678901234567890123456789012345678901234567890123"
  private let secondKey = String(repeating: "0", count: 63) + "1"

  @Test func storedWalletLifecycleAndSigning() async throws {
    let backend = TestKeychain()
    let store = backend.store()
    try store.store(privateKey: fixtureKey, for: "wallet")
    #expect(throws: KeychainWalletError.duplicateKey) {
      try store.store(privateKey: secondKey, for: "wallet")
    }
    // A fresh manager must load from storage, not from the insertion call's signer.
    let wallet = try await WalletService(
      keyManager: KeyManager(keychainKey: "wallet", store: store))
    #expect(wallet.address == "0x14791697260e4c9a71f18484c9f997b308e59325")
    try await assertSignatures(wallet)
    let exported = try await store.exportPrivateKey(for: "wallet", authenticationReason: "Back up")
    #expect(exported == fixtureKey)
    let importedStore = TestKeychain().store()
    try importedStore.store(privateKey: exported, for: "recovered")
    let recovered = try await WalletService(
      keyManager: KeyManager(keychainKey: "recovered", store: importedStore))
    #expect(recovered.address == wallet.address)
    try await assertSignatures(recovered)
    try store.deleteKey(for: "wallet")
    await expectMissing {
      _ = try await wallet.signL1(action: action, nonce: 0, isMainnet: true)
    }
    await expectMissing {
      _ = try await store.exportPrivateKey(for: "wallet", authenticationReason: "Back up")
    }
    await expectMissing {
      _ = try await WalletService(keyManager: KeyManager(keychainKey: "wallet", store: store))
    }
    let missing = #expect(throws: SigningError.self) { try store.deleteKey(for: "wallet") }
    #expect(missing?.errorCode == "SIGNING_KEY_NOT_FOUND")

    // An existing service's cached public address must never identify a different signing key.
    try store.store(privateKey: secondKey, for: "wallet")
    let changed = await #expect(throws: SigningError.self) {
      _ = try await wallet.signL1(action: action, nonce: 0, isMainnet: true)
    }
    #expect(changed?.errorCode == "SIGNING_FAILED")
    let replacement = try await WalletService(
      keyManager: KeyManager(keychainKey: "wallet", store: store))
    #expect(replacement.address == "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf")
  }

  @Test(arguments: [
    (errSecUserCanceled, KeychainWalletError.authenticationCancelled),
    (errSecAuthFailed, .authenticationFailed),
    (errSecInteractionNotAllowed, .interactionNotAllowed),
    (errSecNotAvailable, .unavailable),
    (errSecMissingEntitlement, .unexpectedStatus(errSecMissingEntitlement)),
  ])
  func authenticationFailuresReachPublicWallet(
    status: OSStatus, expected: KeychainWalletError) async throws {
    let backend = TestKeychain()
    let store = backend.store()
    try store.store(privateKey: fixtureKey, for: "wallet")
    let wallet = try await WalletService(
      keyManager: KeyManager(keychainKey: "wallet", store: store))
    backend.setReadStatus(status)
    // Existing services must reauthenticate instead of using a cached decrypted signer.
    let signError = await #expect(throws: KeychainWalletError.self) {
      _ = try await wallet.signL1(action: action, nonce: 0, isMainnet: false)
    }
    #expect(signError == expected)
    let loadError = await #expect(throws: KeychainWalletError.self) {
      _ = try await WalletService(keyManager: KeyManager(keychainKey: "wallet", store: store))
    }
    #expect(loadError == expected)
    let exportError = await #expect(throws: KeychainWalletError.self) {
      _ = try await store.exportPrivateKey(for: "wallet", authenticationReason: "Back up")
    }
    #expect(exportError == expected)
  }

  @Test(arguments: [
    (LAError.Code.userCancel, KeychainWalletError.authenticationCancelled),
    (.appCancel, .authenticationCancelled),
    (.systemCancel, .authenticationCancelled),
    (.authenticationFailed, .authenticationFailed),
    (.passcodeNotSet, .unavailable),
    (.notInteractive, .interactionNotAllowed),
  ])
  func exportRequiresFreshAuthentication(
    code: LAError.Code, expected: KeychainWalletError) async throws {
    let backend = TestKeychain()
    let store = backend.store()
    try store.store(privateKey: fixtureKey, for: "wallet")
    _ = try await store.exportPrivateKey(for: "wallet", authenticationReason: "Back up")
    backend.setAuthenticationError(code)
    let error = await #expect(throws: KeychainWalletError.self) {
      _ = try await store.exportPrivateKey(for: "wallet", authenticationReason: "Back up again")
    }
    #expect(error == expected)
  }

  @Test(arguments: ["invalid", String(repeating: "0", count: 64)])
  func invalidKeyDoesNotCreateWallet(privateKey: String) async throws {
    let store = TestKeychain().store()
    #expect(throws: SigningError.self) { try store.store(privateKey: privateKey, for: "wallet") }
    await expectMissing {
      _ = try await WalletService(keyManager: KeyManager(keychainKey: "wallet", store: store))
    }
  }

  @Test func inMemoryWalletStillSigns() async throws {
    let wallet = try await WalletService(keyManager: KeyManager(privateKey: fixtureKey))
    try await assertSignatures(wallet)
  }

  // Opt-in: requires a signed Apple host with Keychain access, a passcode, foreground
  // interaction, and a human to approve the real system prompts. Never weaken policy for CI.
  @Test(.enabled(if: ProcessInfo.processInfo.environment["HELIQ_TEST_KEYCHAIN"] == "1"))
  func realAppleKeychainLifecycle() async throws {
    let context = LAContext()
    context.localizedReason = "Validate HeliqSDK with an unfunded test wallet"
    let store = KeychainWalletStore(service: "com.heliq.sdk.tests.\(UUID().uuidString)",
      authenticationContext: context)
    try store.store(privateKey: fixtureKey, for: "wallet")
    defer { try? store.deleteKey(for: "wallet") }
    #expect(throws: KeychainWalletError.duplicateKey) {
      try store.store(privateKey: secondKey, for: "wallet")
    }
    let wallet = try await WalletService(
      keyManager: KeyManager(keychainKey: "wallet", store: store))
    #expect(wallet.address == "0x14791697260e4c9a71f18484c9f997b308e59325")
    try await assertSignatures(wallet)
    let exported = try await store.exportPrivateKey(for: "wallet",
      authenticationReason: "Validate explicit backup of an unfunded test wallet")
    #expect(exported == fixtureKey)
    try store.deleteKey(for: "wallet")
    await expectMissing {
      _ = try await wallet.signL1(action: action, nonce: 0, isMainnet: true)
    }
  }

  private var action: CanonicalMessagePack.Object {
    .init([("type", .string("dummy")), ("num", .number(100_000_000_000))])
  }

  private func assertSignatures(_ wallet: any WalletServiceProtocol) async throws {
    let l1 = try await wallet.signL1(action: action, nonce: 0, isMainnet: true)
    #expect(l1.r == "0x53749d5b30552aeb2fca34b530185976545bb22d0b3ce6f62e31be961a59298")
    #expect(l1.s == "0x755c40ba9bf05223521753995abb2f73ab3229be8ec921f350cb447e384d8ed8")
    #expect(l1.v == 27)
    let contextual = try await wallet.signL1Payload(.object(action), nonce: 0,
      vaultAddress: nil, expiresAfter: nil, isMainnet: false)
    #expect(contextual.r == "0x542af61ef1f429707e3c76c5293c80d01f74ef853e34b76efffcb57e574f9510")
    #expect(contextual.s == "0x17b8b32f086e8cdede991f1e2c529f5dd5297cbe8128500e00cbaf766204a613")
    #expect(contextual.v == 28)
    let userSigned = try await wallet.signUserSigned(
      primaryType: "HyperliquidTransaction:UsdSend",
      fields: [
        .init(name: "hyperliquidChain", type: "string"),
        .init(name: "destination", type: "string"),
        .init(name: "amount", type: "string"),
        .init(name: "time", type: "uint64"),
      ], action: [
        "destination": .string("0x5e9ee1089755c3435139848e47e6635505d5a13a"),
        "amount": .string("1"),
        "time": .number(1_687_816_341_423),
      ], isMainnet: false)
    #expect(userSigned.r == "0x637b37dd731507cdd24f46532ca8ba6eec616952c56218baeff04144e4a77073")
    #expect(userSigned.s == "0x11a6a24900e6e314136d2592e2f8d502cd89b7c15b198e1bee043c9589f9fad7")
    #expect(userSigned.v == 27)
  }

  private func expectMissing(_ operation: () async throws -> Void) async {
    let error = await #expect(throws: SigningError.self) { try await operation() }
    #expect(error?.errorCode == "SIGNING_KEY_NOT_FOUND")
  }
}

// Models platform responses, not Apple authentication or encryption.
private final class TestKeychain: @unchecked Sendable {
  private let lock = NSLock()
  private var items: [String: Data] = [:]
  private var readStatus = errSecSuccess
  private var authenticationError: LAError.Code?

  func store() -> KeychainWalletStore {
    KeychainWalletStore(service: "test", client: KeychainClient(
      add: { [self] query in
        lock.lock()
        defer { lock.unlock() }
        let query = query as NSDictionary
        let key = query[kSecAttrAccount] as! String
        guard items[key] == nil else { return errSecDuplicateItem }
        items[key] = query[kSecValueData] as? Data
        return errSecSuccess
      }, copy: { [self] query, result in
        lock.lock()
        defer { lock.unlock() }
        guard readStatus == errSecSuccess else { return readStatus }
        let key = (query as NSDictionary)[kSecAttrAccount] as! String
        guard let data = items[key] else { return errSecItemNotFound }
        result.pointee = data as CFData
        return errSecSuccess
      }, delete: { [self] query in
        lock.lock()
        defer { lock.unlock() }
        let key = (query as NSDictionary)[kSecAttrAccount] as! String
        return items.removeValue(forKey: key) == nil ? errSecItemNotFound : errSecSuccess
      }, authenticate: { [self] _, _ in try authenticate() }))
  }

  func setReadStatus(_ status: OSStatus) {
    lock.lock()
    defer { lock.unlock() }
    readStatus = status
  }

  func setAuthenticationError(_ code: LAError.Code) {
    lock.lock()
    defer { lock.unlock() }
    authenticationError = code
  }

  private func authenticate() throws -> Bool {
    lock.lock()
    defer { lock.unlock() }
    if let authenticationError {
      throw LAError(authenticationError)
    }
    return true
  }
}
