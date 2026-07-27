//
//  InfoUseCases.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a reference type for get spot user state use case.
public final class GetSpotUserStateUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(address: String) async throws -> SpotUserState {
    try await infoRepository.getSpotUserState(address: address)
  }
}

/// Represents a reference type for get all mids use case.
public final class GetAllMidsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute() async throws -> AllMids {
    try await infoRepository.getAllMids()
  }
}

/// Represents a reference type for get asset ctxs use case.
public final class GetAssetCtxsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(coin: String? = nil) async throws -> [AssetContext] {
    try await infoRepository.getAssetCtxs()
  }
}

/// Represents a reference type for get spot asset ctxs use case.
public final class GetSpotAssetCtxsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(coin: String? = nil) async throws -> [SpotAssetContext] {
    try await infoRepository.getSpotAssetCtxs()
  }
}

/// Represents a reference type for get candle snapshot use case.
public final class GetCandleSnapshotUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(coin: String, interval: String, startTime: Date, endTime: Date) async throws -> [Candle] {
    try await infoRepository.getCandleSnapshot(coin: coin, interval: interval, startTime: startTime, endTime: endTime)
  }
}

/// Represents a reference type for get l2 book use case.
public final class GetL2BookUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(coin: String) async throws -> L2Book {
    try await infoRepository.getL2Book(coin: coin)
  }
}

/// Represents a reference type for query order by oid use case.
public final class QueryOrderByOidUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(orderId: String) async throws -> [Order] {
    try await infoRepository.queryOrderByOid(orderId: orderId)
  }
}

/// Represents a reference type for query order by cloid use case.
public final class QueryOrderByCloidUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(cloid: String) async throws -> [Order] {
    try await infoRepository.queryOrderByCloid(cloid: cloid)
  }
}

/// Represents a reference type for query fills use case.
public final class QueryFillsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(address: String, startTime: Date? = nil, endTime: Date? = nil) async throws -> [Fill] {
    try await infoRepository.queryFills(address: address)
  }
}

/// Represents a reference type for query user fundings use case.
public final class QueryUserFundingsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(address: String, startTime: Date? = nil, endTime: Date? = nil) async throws -> [UserFunding] {
    try await infoRepository.queryUserFundings(address: address)
  }
}

/// Represents a reference type for get meta use case.
public final class GetMetaUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute() async throws -> Meta {
    try await infoRepository.getMeta()
  }
}

/// Represents a reference type for get spot meta use case.
public final class GetSpotMetaUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute() async throws -> Meta {
    try await infoRepository.getSpotMeta()
  }
}

/// Represents a reference type for get time use case.
public final class GetTimeUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute() async throws -> Date {
    try await infoRepository.getTime()
  }
}

/// Represents a reference type for fetch builder fee use case.
public final class FetchBuilderFeeUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  /// Creates an instance with the supplied values.
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  /// Executes the use case.
  public func execute(builderAddress: String) async throws -> BuilderFee {
    try await infoRepository.fetchBuilderFee(builderAddress: builderAddress)
  }
}
