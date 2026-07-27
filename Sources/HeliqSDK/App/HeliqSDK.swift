//
//  HeliqSDK.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class HeliqSDK: @unchecked Sendable {
  public static let shared = HeliqSDK()
  
  private var _container: DIContainer?
  
  public var container: DIContainer {
    guard let container = _container else {
      fatalError("HeliqSDK not initialized. Call HeliqSDK.shared.initialize { builder in ... } in AppDelegate")
    }
    return container
  }
  
  private init() {}
  
  public static func builder() -> Builder {
    Builder()
  }
  
  public func initialize(configure: (Builder) -> Void) {
    let builder = Builder()
    configure(builder)
    _container = builder.build()
  }
  
  public var info: any InfoRepository {
    container.infoRepository
  }
  
  public var exchange: any ExchangeRepository {
    container.exchangeRepository
  }
  
  /// Full-surface raw transport for official Info and Exchange APIs.
  public var raw: HyperliquidAPI {
    container.rawAPI
  }

  public var environment: HeliqEnvironment {
    container.environment
  }
}

public final class Builder {
  private var _environment: HeliqEnvironment?
  private var _wallet: (any WalletServiceProtocol)?
  private var _logging: LogLevel = .disabled
  
  public init() {}
  
  public func environment(_ environment: HeliqEnvironment) -> Builder {
    _environment = environment
    return self
  }
  
  public func logging(_ level: LogLevel) -> Builder {
    _logging = level
    return self
  }

  public func wallet(_ wallet: any WalletServiceProtocol) -> Builder {
    _wallet = wallet
    return self
  }
  
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

public protocol WalletServiceProtocol: Sendable {
  var address: String { get }
  func sign(message: String) async throws -> SignatureTypes
}
