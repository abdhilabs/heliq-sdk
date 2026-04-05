//
//  SDKManager.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import HeliqSDK
import SwiftUI

@Observable
final class SDKManager: @unchecked Sendable {
  static let shared = SDKManager()
  
  private(set) var isInitialized: Bool = false
  private(set) var currentEnvironment: HeliqEnvironment = .mainnet
  private(set) var initializationError: String?
  private(set) var walletAddress: String?
  
  private var mockWallet: MockWalletService?
  
  private init() {}
  
  var sdk: HeliqSDK {
    HeliqSDK.shared
  }
  
  @MainActor
  func initialize(with environment: HeliqEnvironment) async throws {
    initializationError = nil
    currentEnvironment = environment
    
    let wallet = MockWalletService()
    mockWallet = wallet
    walletAddress = wallet.address
    
    HeliqSDK.shared.initialize { builder in
      builder.environment(environment)
      builder.wallet(wallet)
    }
    self.isInitialized = true
  }
  
  @MainActor
  func disconnect() {
    isInitialized = false
    mockWallet = nil
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
