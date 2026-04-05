//
//  DIContainer.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class DIContainer: Sendable {
  public let infoRepository: any InfoRepository
  public let exchangeRepository: any ExchangeRepository
  public let apiClient: APIClient
  public let environment: HeliqEnvironment
  
  public init(
    infoRepository: any InfoRepository,
    exchangeRepository: any ExchangeRepository,
    apiClient: APIClient,
    environment: HeliqEnvironment
  ) {
    self.infoRepository = infoRepository
    self.exchangeRepository = exchangeRepository
    self.apiClient = apiClient
    self.environment = environment
  }
  
  public static func create(environment: HeliqEnvironment) -> DIContainer {
    let apiClient = APIClient(environment: environment)
    let infoRepository = InfoRepositoryImpl(apiClient: apiClient)
    let exchangeRepository = ExchangeRepositoryImpl(apiClient: apiClient)
    
    return DIContainer(
      infoRepository: infoRepository,
      exchangeRepository: exchangeRepository,
      apiClient: apiClient,
      environment: environment
    )
  }
}
