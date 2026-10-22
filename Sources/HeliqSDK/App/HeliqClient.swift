//
//  HeliqClient.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// An independently configured client for Heliq services.
public final class HeliqClient: Sendable {
  private let container: DIContainer

  private init(container: DIContainer) {
    self.container = container
  }

  /// Information-query operations for this client.
  public var info: any InfoRepository {
    container.infoRepository
  }

  /// Signed exchange operations for this client.
  ///
  /// Every exchange action throws `ValidationError.missingRequiredField(field: "wallet")`
  /// when this client was built without a wallet.
  public var exchange: any ExchangeRepository {
    container.exchangeRepository
  }

  /// Low-level raw transport for official Info and Exchange APIs.
  public var raw: HyperliquidAPI {
    container.rawAPI
  }

  /// Environment used by this client.
  public var environment: HeliqEnvironment {
    container.environment
  }

  /// Fluent configuration for an independent client.
  public final class Builder {
    private var environment: HeliqEnvironment = .mainnet
    private var wallet: (any WalletServiceProtocol)?
    private var logging: LogLevel = .disabled

    /// Creates an empty client builder.
    public init() {}

    /// Sets the Hyperliquid environment.
    @discardableResult
    public func environment(_ environment: HeliqEnvironment) -> Self {
      self.environment = environment
      return self
    }

    /// Sets the wallet used by signed exchange operations.
    @discardableResult
    public func wallet(_ wallet: any WalletServiceProtocol) -> Self {
      self.wallet = wallet
      return self
    }

    /// Sets the diagnostic logging level.
    @discardableResult
    public func logging(_ logging: LogLevel) -> Self {
      self.logging = logging
      return self
    }

    /// Builds an independent client.
    public func build() throws -> HeliqClient {
      Logger.shared.configure(logging)
      let container = DIContainer.create(environment: environment, wallet: wallet)
      return HeliqClient(container: container)
    }
  }
}
