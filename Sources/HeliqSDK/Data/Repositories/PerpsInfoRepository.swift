//
//  PerpsInfoRepository.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation

extension InfoRepositoryImpl {
  /// Validates a typed read request and decodes its response through the existing info transport.
  public func perps<Response: Sendable>(_ query: PerpsQuery<Response>) async throws -> Response {
    try validatePerpsParameters(query.request.parameters)
    let data: Data = try await apiClient.requestData(
      HyperliquidRawRequest(path: "/info", body: query.request.body()))
    do { return try query.decode(data) } catch let error as any HeliqError { throw error } catch {
      throw APIError.decodingFailed(underlying: error)
    }
  }

  /// Reads leverage and trading capacity for the address and exact metadata coin name.
  public func getActiveAssetData(address: String, coin: String) async throws -> PerpsActiveAssetData
  {
    try await perps(.activeAsset(address: address, coin: coin))
  }

  /// Reads mode-aware balances without estimating missing availability or double counting shared
  /// collateral.
  public func getBalances(address: String) async throws -> AccountBalances {
    try await getBalances(address: address, dexes: [""])
  }

  /// Reads mode-aware balances without estimating missing availability or double counting shared
  /// collateral.
  public func getBalances(address: String, dexes: [String]) async throws -> AccountBalances {
    guard !dexes.isEmpty, Set(dexes).count == dexes.count else {
      throw ValidationError.malformedData(reason: "Select at least one unique Perps DEX")
    }
    let mode = try await perps(.abstraction(address: address))
    async let spot = perps(.spotState(address: address))
    let names = dexes
    let summaries = try await withThrowingTaskGroup(of: (Int, PerpsDexBalance).self) { group in
      for (index, dex) in names.enumerated() {
        group.addTask {
          async let meta = self.perps(.meta(dex: dex))
          let account = try await self.perps(.account(address: address, dex: dex))
          return (
            index,
            PerpsDexBalance(
              dex: dex,
              collateralToken: try await meta.collateralToken,
              accountValue: mode.hasSeparateBalances ? account.marginSummary.accountValue : nil,
              marginUsed: mode.hasSeparateBalances ? account.marginSummary.totalMarginUsed : nil,
              withdrawable: mode.hasSeparateBalances ? account.withdrawable : nil,
              positions: account.assetPositions)
          )
        }
      }
      var result: [(Int, PerpsDexBalance)] = []
      for try await item in group { result.append(item) }
      return result.sorted { $0.0 < $1.0 }.map(\.1)
    }
    let state = try await spot
    let available = Dictionary(
      state.tokenToAvailableAfterMaintenance?.map {
        ($0.key, $0.value)
      } ?? [], uniquingKeysWith: { _, _ in Decimal.nan })
    guard !available.values.contains(where: { $0.isNaN }) else { throw APIError.invalidResponse }
    return AccountBalances(
      address: address, abstraction: mode,
      spot: state.balances.map { balance in
        TokenBalance(
          coin: balance.coin, token: balance.token, total: balance.total,
          held: balance.hold, availableAfterMaintenance: available[balance.token], withdrawable: nil
        )
      }, perps: summaries)
  }
}

/// Rejects malformed addresses, identifiers, pagination, and endpoint-specific query parameters.
func validatePerpsParameters(_ parameters: [String: JSONValue]) throws {
  if parameters["limit"] != nil {
    throw ValidationError.malformedData(
      reason: "This endpoint uses timestamp pagination, not a limit parameter")
  }
  if case .number(let token)? = parameters["token"],
    token < 0 || token.rounded() != token || token > Double(UInt32.max)
  {
    throw ValidationError.malformedData(reason: "Invalid token index")
  }
  if case .object(let nested)? = parameters["req"] { try validatePerpsParameters(nested) }
  if case .number(let figures)? = parameters["nSigFigs"], ![2, 3, 4, 5].contains(figures) {
    throw ValidationError.malformedData(reason: "Invalid nSigFigs")
  }
  if case .number(let mantissa)? = parameters["mantissa"],
    parameters["nSigFigs"] != .number(5) || ![1, 2, 5].contains(mantissa)
  {
    throw ValidationError.malformedData(reason: "Invalid mantissa")
  }
  if case .string(let id)? = parameters["oid"] { try perpsCloid(id) }
  for key in ["vaultAddress", "user", "destination", "agentAddress", "builder", "subAccountUser"] {
    if case .string(let value)? = parameters[key] { try perpsAddress(value) }
  }
  for key in ["startTime", "endTime", "oid"] {
    if case .integer(let integer)? = parameters[key], integer < 0 {
      throw ValidationError.malformedData(reason: "Invalid \(key)")
    }
    if case .number(let number)? = parameters[key] {
      guard number.isFinite, number >= 0, number.rounded() == number,
        number < 9_007_199_254_740_992
      else { throw ValidationError.malformedData(reason: "Invalid \(key)") }
    }
  }
  if case .number(let start)? = parameters["startTime"],
    case .number(let end)? = parameters["endTime"], end < start
  {
    throw ValidationError.malformedData(reason: "End time precedes start time")
  }
  if case .string(let coin)? = parameters["coin"], coin.isEmpty {
    throw ValidationError.missingRequiredField(field: "coin")
  }
}

/// Requires a 20-byte hexadecimal address with the protocol’s `0x` prefix.
func perpsAddress(_ value: String) throws {
  guard value.hasPrefix("0x"), value.count == 42,
    value.dropFirst(2).utf8.allSatisfy({
      (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
    })
  else {
    throw ValidationError.invalidFieldFormat(
      field: "address", expected: "20-byte hexadecimal address")
  }
}
