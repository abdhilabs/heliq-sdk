//
//  DIContainer.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Stores the SDK services configured for one Hyperliquid environment.
public final class DIContainer: Sendable {
  /// Repository for Hyperliquid information queries.
  public let infoRepository: any InfoRepository
  /// Repository for Hyperliquid exchange actions.
  public let exchangeRepository: any ExchangeRepository
  /// HTTP client shared by the configured repositories.
  public let apiClient: APIClient
  /// Low-level API surface backed by `apiClient`.
  public let rawAPI: HyperliquidAPI
  /// Environment used by the configured services.
  public let environment: HeliqEnvironment
  
  /// Creates a container from explicitly supplied service dependencies.
  public init(
    infoRepository: any InfoRepository,
    exchangeRepository: any ExchangeRepository,
    apiClient: APIClient,
    environment: HeliqEnvironment
  ) {
    self.infoRepository = infoRepository
    self.exchangeRepository = exchangeRepository
    self.apiClient = apiClient
    self.rawAPI = HyperliquidAPI(apiClient: apiClient)
    self.environment = environment
  }
  
  /// Creates the SDK's default services for an environment.
  public static func create(
    environment: HeliqEnvironment,
    wallet: (any WalletServiceProtocol)? = nil
  ) -> DIContainer {
    let apiClient = APIClient(environment: environment)
    let infoRepository = InfoRepositoryImpl(apiClient: apiClient)
    let exchangeRepository = ExchangeRepositoryImpl(
      apiClient: apiClient,
      wallet: wallet
    )
    
    return DIContainer(
      infoRepository: infoRepository,
      exchangeRepository: exchangeRepository,
      apiClient: apiClient,
      environment: environment
    )
  }
}
