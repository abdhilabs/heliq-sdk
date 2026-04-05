//
//  GetUserStateUseCase.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class GetUserStateUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(address: String) async throws -> UserState {
    try await infoRepository.getUserState(address: address)
  }
}
