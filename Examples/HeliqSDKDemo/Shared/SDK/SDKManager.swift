//
//  SDKManager.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import Combine
import Foundation
import HeliqSDK
import SwiftUI

final class SDKManager: ObservableObject, @unchecked Sendable {
  static let shared = SDKManager()
  
  @Published private(set) var isInitialized: Bool = false
  @Published private(set) var currentEnvironment: HeliqEnvironment = .mainnet
  @Published private(set) var initializationError: String?
  @Published private(set) var walletAddress: String?
  
  private var wallet: (any WalletServiceProtocol)?
  
  private init() {}
  
  @Published private(set) var client: HeliqClient?
  var sdk: HeliqClient {
    guard let client else {
      preconditionFailure("Initialize the demo client before accessing SDK services.")
    }
    return client
  }
  
  @MainActor
  func initialize(with environment: HeliqEnvironment) async throws {
    initializationError = nil
    currentEnvironment = environment
    
    let signingWallet: any WalletServiceProtocol
    if environment == .testnet {
      let privateKey = try TestnetWalletStore.privateKey(
        fresh: ProcessInfo.processInfo.arguments.contains("-fresh-testnet-wallet")
      )
      signingWallet = try await WalletService(keyManager: KeyManager(privateKey: privateKey))
    } else {
      signingWallet = MockWalletService()
    }
    wallet = signingWallet
    walletAddress = signingWallet.address
    
    client = try HeliqClient.Builder()
      .environment(environment)
      .wallet(signingWallet)
      .build()
    isInitialized = true
  }
  
  @MainActor
  func disconnect() {
    isInitialized = false
    client = nil
    wallet = nil
    walletAddress = nil
    initializationError = nil
  }
}

struct SDKManagerKey: EnvironmentKey {
  static let defaultValue: SDKManager = SDKManager.shared
}

extension EnvironmentValues {
  var sdkManager: SDKManager {
    get { self[SDKManagerKey.self] }
    set { self[SDKManagerKey.self] = newValue }
  }
}
