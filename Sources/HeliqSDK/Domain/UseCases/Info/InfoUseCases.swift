//
//  InfoUseCases.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public final class GetSpotUserStateUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(address: String) async throws -> SpotUserState {
    try await infoRepository.getSpotUserState(address: address)
  }
}

public final class GetAllMidsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute() async throws -> AllMids {
    try await infoRepository.getAllMids()
  }
}

public final class GetAssetCtxsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(coin: String? = nil) async throws -> [AssetContext] {
    try await infoRepository.getAssetCtxs()
  }
}

public final class GetSpotAssetCtxsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(coin: String? = nil) async throws -> [SpotAssetContext] {
    try await infoRepository.getSpotAssetCtxs()
  }
}

public final class GetCandleSnapshotUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(coin: String, interval: String, startTime: Date, endTime: Date) async throws -> [Candle] {
    try await infoRepository.getCandleSnapshot(coin: coin, interval: interval, startTime: startTime, endTime: endTime)
  }
}

public final class GetL2BookUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(coin: String) async throws -> L2Book {
    try await infoRepository.getL2Book(coin: coin)
  }
}

public final class QueryOrderByOidUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(orderId: String) async throws -> [Order] {
    try await infoRepository.queryOrderByOid(orderId: orderId)
  }
}

public final class QueryOrderByCloidUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(cloid: String) async throws -> [Order] {
    try await infoRepository.queryOrderByCloid(cloid: cloid)
  }
}

public final class QueryFillsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(address: String, startTime: Date? = nil, endTime: Date? = nil) async throws -> [Fill] {
    try await infoRepository.queryFills(address: address)
  }
}

public final class QueryUserFundingsUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(address: String, startTime: Date? = nil, endTime: Date? = nil) async throws -> [UserFunding] {
    try await infoRepository.queryUserFundings(address: address)
  }
}

public final class GetMetaUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute() async throws -> Meta {
    try await infoRepository.getMeta()
  }
}

public final class GetSpotMetaUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute() async throws -> Meta {
    try await infoRepository.getSpotMeta()
  }
}

public final class GetTimeUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute() async throws -> Date {
    try await infoRepository.getTime()
  }
}

public final class FetchBuilderFeeUseCase: @unchecked Sendable {
  private let infoRepository: any InfoRepository
  
  public init(infoRepository: any InfoRepository) {
    self.infoRepository = infoRepository
  }
  
  public func execute(builderAddress: String) async throws -> BuilderFee {
    try await infoRepository.fetchBuilderFee(builderAddress: builderAddress)
  }
}
