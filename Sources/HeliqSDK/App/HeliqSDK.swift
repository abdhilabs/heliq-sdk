//
//  HeliqSDK.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Entry point for configuring and accessing Heliq SDK services.
public final class HeliqSDK: @unchecked Sendable {
  /// Shared SDK instance.
  public static let shared = HeliqSDK()
  
  private var _container: DIContainer?
  
  /// Configured dependency container. Access before initialization terminates the process.
  public var container: DIContainer {
    guard let container = _container else {
      fatalError("HeliqSDK not initialized. Call HeliqSDK.shared.initialize { builder in ... } in AppDelegate")
    }
    return container
  }
  
  private init() {}
  
  /// Creates a builder for configuring SDK services.
  public static func builder() -> Builder {
    Builder()
  }
  
  /// Configures and initializes the shared SDK instance.
  public func initialize(configure: (Builder) -> Void) {
    let builder = Builder()
    configure(builder)
    _container = builder.build()
  }
  
  /// Information-query repository from the configured container.
  public var info: any InfoRepository {
    container.infoRepository
  }
  
  /// Exchange-action repository from the configured container.
  public var exchange: any ExchangeRepository {
    container.exchangeRepository
  }
  
  /// Full-surface raw transport for official Info and Exchange APIs.
  public var raw: HyperliquidAPI {
    container.rawAPI
  }

  /// Environment used by the configured SDK services.
  public var environment: HeliqEnvironment {
    container.environment
  }
}

/// Fluent builder for configuring an SDK dependency container.
public final class Builder {
  private var _environment: HeliqEnvironment?
  private var _wallet: (any WalletServiceProtocol)?
  private var _logging: LogLevel = .disabled
  
  /// Creates an empty SDK builder.
  public init() {}
  
  /// Sets the Hyperliquid environment.
  public func environment(_ environment: HeliqEnvironment) -> Builder {
    _environment = environment
    return self
  }
  
  /// Sets the SDK logging level.
  public func logging(_ level: LogLevel) -> Builder {
    _logging = level
    return self
  }

  /// Sets the wallet service required to build the SDK.
  public func wallet(_ wallet: any WalletServiceProtocol) -> Builder {
    _wallet = wallet
    return self
  }
  
  /// Configures logging and builds the dependency container.
  public func build() -> DIContainer {
    let environment = _environment ?? .mainnet
    
    guard _wallet != nil else {
      fatalError("Wallet must be set. Use builder.wallet(myWallet)")
    }
    
    Logger.shared.configure(_logging)
    let container = DIContainer.create(environment: environment)
    return container
  }
}

/// Defines the wallet operations required by the SDK.
public protocol WalletServiceProtocol: Sendable {
  /// Wallet address used to identify the signing account.
  var address: String { get }
  /// Signs a message and returns its signature representation.
  func sign(message: String) async throws -> SignatureTypes
}
