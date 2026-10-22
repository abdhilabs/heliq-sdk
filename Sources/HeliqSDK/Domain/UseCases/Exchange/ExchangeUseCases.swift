//
//  ExchangeUseCases.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a reference type for place order use case.
public final class PlaceOrderUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(_ order: OrderRequest) async throws -> OrderResponse {
    try await exchangeRepository.placeOrder(order)
  }
}

/// Represents a reference type for bulk orders use case.
public final class BulkOrdersUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(_ orders: [OrderRequest]) async throws -> BulkOrderResponse {
    try await exchangeRepository.bulkOrders(orders)
  }
}

/// Represents a reference type for cancel order use case.
public final class CancelOrderUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(orderId: String, asset: Int) async throws -> CancelResponse {
    try await exchangeRepository.cancelOrder(orderId: orderId, asset: asset)
  }
}

/// Represents a reference type for cancel by cloid use case.
public final class CancelByCloidUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(cloid: String, asset: Int) async throws -> CancelResponse {
    try await exchangeRepository.cancelByCloid(cloid: cloid, asset: asset)
  }
}

/// Represents a reference type for cancel all use case.
public final class CancelAllUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(asset: Int? = nil) async throws -> CancelAllResponse {
    try await exchangeRepository.cancelAll()
  }
}

/// Represents a reference type for modify order use case.
public final class ModifyOrderUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(orderId: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse {
    try await exchangeRepository.modifyOrder(orderId: orderId, asset: asset, size: size, price: price)
  }
}

/// Represents a reference type for modify by cloid use case.
public final class ModifyByCloidUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(cloid: String, asset: Int, size: Double?, price: Double?) async throws -> OrderResponse {
    try await exchangeRepository.modifyByCloid(cloid: cloid, asset: asset, size: size, price: price)
  }
}

/// Represents a reference type for set leverage use case.
public final class SetLeverageUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(asset: Int, leverage: Int) async throws -> SetLeverageResponse {
    try await exchangeRepository.setLeverage(asset: asset, leverage: leverage)
  }
}

/// Represents a reference type for set margin mode use case.
public final class SetMarginModeUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(asset: Int, mode: MarginMode) async throws -> SetMarginModeResponse {
    try await exchangeRepository.setMarginMode(asset: asset, mode: mode)
  }
}

/// Represents a reference type for transfer use case.
public final class TransferUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(fromAddress: String, toAddress: String, amount: Double, asset: Int) async throws -> TransferResponse {
    try await exchangeRepository.transfer(fromAddress: fromAddress, toAddress: toAddress, amount: amount, asset: asset)
  }
}

/// Represents a reference type for send to address use case.
public final class SendToAddressUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(address: String, amount: Double, asset: Int) async throws -> SendToAddressResponse {
    try await exchangeRepository.sendToAddress(address: address, amount: amount, asset: asset)
  }
}

/// Represents a reference type for spot transfer use case.
public final class SpotTransferUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(toAddress: String, amount: Double, asset: Int) async throws -> SpotTransferResponse {
    try await exchangeRepository.spotTransfer(toAddress: toAddress, amount: amount, asset: asset)
  }
}

/// Represents a reference type for vault transfer use case.
public final class VaultTransferUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(_ vaultTransfer: VaultTransfer) async throws -> VaultTransferResponse {
    try await exchangeRepository.vaultTransfer(vaultTransfer: vaultTransfer)
  }
}

/// Represents a reference type for update builder use case.
public final class UpdateBuilderUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(builderAddress: String) async throws -> UpdateBuilderResponse {
    try await exchangeRepository.updateBuilder(builderAddress: builderAddress)
  }
}

/// Represents a reference type for schedule cancel use case.
public final class ScheduleCancelUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(time: Date) async throws -> ScheduleCancelResponse {
    try await exchangeRepository.scheduleCancel(time: time)
  }
}

/// Represents a reference type for set referrer use case.
public final class SetReferrerUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(referrer: String) async throws -> SetReferrerResponse {
    try await exchangeRepository.setReferrer(referrer: referrer)
  }
}

/// Represents a reference type for convert to multi sig use case.
public final class ConvertToMultiSigUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute() async throws -> ConvertToMultiSigResponse {
    try await exchangeRepository.convertToMultiSigUser()
  }
}

/// Represents a reference type for usd send use case.
public final class UsdSendUseCase: @unchecked Sendable {
  private let exchangeRepository: any ExchangeRepository
  
  /// Creates an instance with the supplied values.
  public init(exchangeRepository: any ExchangeRepository) {
    self.exchangeRepository = exchangeRepository
  }
  
  /// Executes the use case.
  public func execute(destination: String, amount: Double) async throws -> UsdSendResponse {
    try await exchangeRepository.usdSend(destination: destination, amount: amount)
  }
}
