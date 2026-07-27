//
//  GetUserStateUseCase.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a reference type for get user state use case.
public final class GetUserStateUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(address: String) async throws -> UserState {
    try await infoRepository.getUserState(address: address)
  }
}
