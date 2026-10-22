//
//  TestnetWalletStore.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import HeliqSDK
import Security

enum TestnetWalletStore {
  private static let service = "com.heliq.SDKDemo.testnet-wallet"

  static func privateKey(fresh: Bool = false) throws -> String {
    if fresh { return try generatedKey() }
    #if targetEnvironment(simulator)
    // Unsigned simulator builds lack Keychain entitlements; test keys stay app-private.
    return try simulatorKey()
    #else
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: "default",
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw SigningError.signingFailed(reason: "Testnet keychain read failed: \(status)")
    }
    let directory = try FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true
    )
    let importURL = directory.appendingPathComponent("testnet-wallet-import.key")
    let incoming = FileManager.default.fileExists(atPath: importURL.path)
      ? try String(contentsOf: importURL, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines) : nil
    if status == errSecSuccess {
      guard let data = item as? Data, let key = String(data: data, encoding: .utf8) else {
        throw SigningError.invalidPrivateKey
      }
      _ = try Signer(privateKey: key)
      guard incoming == nil || incoming == key else {
        throw SigningError.signingFailed(reason: "Refusing to replace the saved testnet wallet")
      }
      if incoming != nil { try FileManager.default.removeItem(at: importURL) }
      return key
    }
    let key = try incoming ?? generatedKey()
    _ = try Signer(privateKey: key)
    let attributes: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: "default",
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      kSecValueData as String: Data(key.utf8)
    ]
    let saved = SecItemAdd(attributes as CFDictionary, nil)
    guard saved == errSecSuccess else {
      throw SigningError.signingFailed(reason: "Testnet keychain save failed: \(saved)")
    }
    if incoming != nil { try FileManager.default.removeItem(at: importURL) }
    return key
    #endif
  }

  #if targetEnvironment(simulator)
  private static func simulatorKey() throws -> String {
    let directory = try FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask,
      appropriateFor: nil, create: true
    )
    let savedURL = directory.appendingPathComponent("testnet-wallet.key")
    let importURL = directory.appendingPathComponent("testnet-wallet-import.key")
    let exists = FileManager.default.fileExists(atPath: savedURL.path)
    let incoming = FileManager.default.fileExists(atPath: importURL.path)
      ? try String(contentsOf: importURL, encoding: .utf8)
        .trimmingCharacters(in: .whitespacesAndNewlines) : nil
    let key = exists ? try String(contentsOf: savedURL, encoding: .utf8)
      : try incoming ?? generatedKey()
    _ = try Signer(privateKey: key)
    guard incoming == nil || incoming == key else {
      throw SigningError.signingFailed(reason: "Refusing to replace the saved testnet wallet")
    }
    if !exists {
      guard FileManager.default.createFile(
        atPath: savedURL.path, contents: Data(key.utf8),
        attributes: [.posixPermissions: 0o600]
      ) else { throw SigningError.signingFailed(reason: "Could not save the testnet wallet") }
    }
    try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: savedURL.path)
    if incoming != nil { try FileManager.default.removeItem(at: importURL) }
    return key
  }
  #endif

  private static func generatedKey() throws -> String {
    var bytes = [UInt8](repeating: 0, count: 32)
    guard SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) == errSecSuccess else {
      throw SigningError.keyNotFound
    }
    return bytes.map { String(format: "%02x", $0) }.joined()
  }
}
