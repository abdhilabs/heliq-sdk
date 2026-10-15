//
//  PerpsTradingView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 15/10/26.
//

import Foundation
import HeliqSDK
import SwiftUI

struct AvailableBalancesView: View {
  let address: String
  @State private var balances: AccountBalances?
  @State private var error: String?
  @State private var loading = false

  var body: some View {
    List {
      Section {
        Button("Load Available Balances") { Task { await load() } }
          .accessibilityIdentifier("load_available_balances")
          .disabled(loading)
        if loading { ProgressView() }
      }
      if let balances {
        Section("Account") {
          Text(
            balances.hasSharedCollateral
              ? "Shared Spot / Perps collateral"
              : (balances.abstraction.hasSeparateBalances
                ? "Separate Spot and Perps balances" : "Unresolved account mode")
          )
          .accessibilityIdentifier("balance_mode")
          Text(balances.abstraction.rawValue)
        }
        Section("Spot tokens") {
          ForEach(balances.spot, id: \.token) { token in
            VStack(alignment: .leading, spacing: 4) {
              Text(token.coin).bold()
              Text("Total: \(token.total.description)")
              Text("Held: \(token.held.description)")
              Text("Unheld: \(token.unheld.description)")
              Text(
                "Available after maintenance: \(token.availableAfterMaintenance?.description ?? "Unavailable")"
              )
              Text("Withdrawable: \(token.withdrawable?.description ?? "Unavailable")")
            }
          }
        }
        ForEach(balances.perps, id: \.dex) { dex in
          Section(dex.dex.isEmpty ? "Validator Perps" : dex.dex) {
            if balances.hasSharedCollateral {
              Text("Collateral is included in Spot above.")
            } else {
              Text("Account value: \(dex.accountValue?.description ?? "Unavailable")")
              Text("Margin used: \(dex.marginUsed?.description ?? "Unavailable")")
              Text("Withdrawable: \(dex.withdrawable?.description ?? "Unavailable")")
            }
            Text("Positions: \(dex.positions.count)")
          }
        }
      }
      if let error {
        Section("Error") {
          Text(error).foregroundStyle(.red).accessibilityIdentifier("balance_error")
        }
      }
    }
    .navigationTitle("Available Balances")
    .task { await load() }
  }
  /// Refreshes the displayed balances and reports any SDK error without inventing missing amounts.
  @MainActor private func load() async {
    loading = true
    defer { loading = false }
    do {
      balances = try await SDKManager.shared.sdk.info.getBalances(address: address)
      error = nil
    } catch {
      self.error = (error as? any HeliqError)?.errorDescription ?? error.localizedDescription
    }
  }
}

struct PerpsTradingView: View {
  @State private var dexs = [""]
  @State private var dex = ""
  @State private var markets: [PerpsAsset] = []
  @State private var coin = ""
  @State private var balances: AccountBalances?
  @State private var capacity: PerpsActiveAssetData?
  @State private var side: OrderSide = .buy
  @State private var type = "Limit"
  @State private var tif: PerpsTimeInForce = .gtc
  @State private var size = ""
  @State private var price = ""
  @State private var trigger = ""
  @State private var minutes = "5"
  @State private var retracement = "1"
  @State private var reduceOnly = false
  @State private var leverage = "2"
  @State private var crossMargin = true
  @State private var margin = ""
  @State private var transferAmount = ""
  @State private var toPerp = true
  @State private var twapID = ""
  @State private var result: String?
  @State private var error: String?
  @State private var busy = false
  @FocusState private var inputFocused: Bool
  private let types = ["Limit", "Market", "Take profit", "Stop loss", "TWAP", "Trailing stop"]

  var body: some View {
    List {
      Section("Market") {
        Picker("DEX", selection: $dex) {
          ForEach(dexs, id: \.self) { Text($0.isEmpty ? "Validator Perps" : $0).tag($0) }
        }.disabled(busy)
        Picker("Coin", selection: $coin) {
          ForEach(markets, id: \.name) { Text($0.name).tag($0.name) }
        }.disabled(busy)
          .accessibilityIdentifier("perps_coin")
        Button("Refresh balances and capacity") { Task { await refresh() } }
        if let address = SDKManager.shared.walletAddress {
          NavigationLink("Available balances", destination: AvailableBalancesView(address: address))
        }
        if let capacity {
          Text("Available to buy: \(capacity.availableToBuy.description)")
          Text("Available to sell: \(capacity.availableToSell.description)")
          Text("Max buy size: \(capacity.maxBuySize.description)")
          Text("Max sell size: \(capacity.maxSellSize.description)")
        }
      }
      Section("Place order") {
        Picker("Side", selection: $side) {
          Text("Buy").tag(OrderSide.buy)
          Text("Sell").tag(OrderSide.sell)
        }.pickerStyle(.segmented)
        Picker("Order type", selection: $type) { ForEach(types, id: \.self) { Text($0).tag($0) } }
        TextField("Size", text: $size).focused($inputFocused).keyboardType(.decimalPad)
          .accessibilityIdentifier("perps_size")
        if type == "Limit" {
          TextField("Price", text: $price).focused($inputFocused).keyboardType(.decimalPad)
            .accessibilityIdentifier("perps_price")
          Picker("Time in force", selection: $tif) {
            Text("Gtc").tag(PerpsTimeInForce.gtc)
            Text("Ioc").tag(PerpsTimeInForce.ioc)
            Text("Alo").tag(PerpsTimeInForce.alo)
          }
        }
        if type == "Take profit" || type == "Stop loss" {
          TextField("Trigger price", text: $trigger).focused($inputFocused).keyboardType(
            .decimalPad)
        }
        if type == "TWAP" {
          TextField("Minutes", text: $minutes).focused($inputFocused).keyboardType(.numberPad)
        }
        if type == "Trailing stop" {
          TextField("Retracement (%)", text: $retracement).focused($inputFocused).keyboardType(
            .decimalPad)
        }
        Toggle("Reduce only", isOn: $reduceOnly)
        Button("Submit Perps Order") { Task { await place() } }.disabled(
          busy || coin.isEmpty || size.isEmpty
        )
        .accessibilityIdentifier("submit_perps_order")
      }
      Section("Open orders") {
        Button("Cancel selected market orders") { Task { await cancelOpenOrders() } }
          .disabled(busy || coin.isEmpty).accessibilityIdentifier("perps_cancel_open")
      }
      Section("Position") {
        TextField("Leverage", text: $leverage).focused($inputFocused).keyboardType(.numberPad)
        Picker("Margin mode", selection: $crossMargin) {
          Text("Cross").tag(true)
          Text("Isolated").tag(false)
        }.pickerStyle(.segmented)
        Button("Set leverage and margin mode") {
          run {
            guard let value = Int(leverage) else {
              throw ValidationError.malformedData(reason: "Enter integer leverage")
            }
            return .leverage(market: .coin(coin), value: value, cross: crossMargin)
          }
        }.disabled(busy || coin.isEmpty || leverage.isEmpty)

        TextField("Signed margin change (collateral units)", text: $margin).focused($inputFocused)
          .accessibilityIdentifier("perps_margin")
        Button("Adjust isolated margin") {
          run { .isolatedMargin(market: .coin(coin), amount: try amount(margin)) }
        }.disabled(busy || margin.isEmpty || coin.isEmpty)
        Button("Close position") { run { .marketClose(market: .coin(coin)) } }.disabled(
          busy || coin.isEmpty)
      }
      Section("TWAP cancellation") {
        TextField("TWAP ID", text: $twapID).focused($inputFocused).keyboardType(.numberPad)
        Button("Cancel TWAP") {
          run {
            guard let id = Int64(twapID) else {
              throw ValidationError.malformedData(reason: "Invalid TWAP ID")
            }
            return .cancelTwap(market: .coin(coin), id: id)
          }
        }.disabled(busy || twapID.isEmpty || coin.isEmpty)
      }
      Section("Spot ↔ Validator Perps USDC") {
        if balances?.hasSharedCollateral == true {
          Text("This account shares Spot and Perps collateral. No class transfer is needed.")
        }
        TextField("USDC amount", text: $transferAmount).focused($inputFocused).keyboardType(
          .decimalPad
        ).accessibilityIdentifier("perps_transfer_amount")
        Picker("Transfer direction", selection: $toPerp) {
          Text("Spot → Perps").tag(true)
          Text("Perps → Spot").tag(false)
        }.pickerStyle(.segmented).disabled(busy)
        Button("Transfer between Spot and Perps") {
          run { .usdClassTransfer(amount: try amount(transferAmount), toPerp: toPerp) }
        }
        .disabled(
          busy || balances == nil || balances?.abstraction.supportsClassTransfer != true
            || transferAmount.isEmpty
        )
        .accessibilityIdentifier("perps_class_transfer")
      }
      if let result { Section("Result") { Text(result).accessibilityIdentifier("perps_result") } }
      if let error {
        Section("Error") {
          Text(error).foregroundStyle(.red).accessibilityIdentifier("perps_error")
        }
      }
    }
    .navigationTitle("Perps Trading")
    .toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") { inputFocused = false }
      }
    }
    .task {
      do {
        dexs = [""] + (try await SDKManager.shared.sdk.info.perps(.dexs())).compactMap { $0?.name }
        await loadMarkets()
      } catch { show(error) }
    }
    .onChange(of: dex) { _, _ in Task { await loadMarkets() } }
    .onChange(of: coin) { _, _ in Task { await refresh() } }
  }
  /// Loads DEX metadata and selects a valid market for the trading controls.
  @MainActor private func loadMarkets() async {
    do {
      markets = try await SDKManager.shared.sdk.info.perps(.meta(dex: dex)).universe.filter {
        $0.isDelisted != true
      }
      coin = markets.first(where: { $0.name == "BTC" })?.name ?? markets.first?.name ?? ""
    } catch { show(error) }
  }
  /// Refreshes the selected market’s positions and coin-specific trading capacity.
  @MainActor private func refresh() async {
    guard let address = SDKManager.shared.walletAddress else { return }
    do {
      balances = try await SDKManager.shared.sdk.info.getBalances(
        address: address, dexes: dex.isEmpty ? [""] : ["", dex])
      if !coin.isEmpty {
        capacity = try await SDKManager.shared.sdk.info.getActiveAssetData(
          address: address, coin: coin)
      }
    } catch {
      self.error = (error as? any HeliqError)?.errorDescription ?? error.localizedDescription
    }
  }
  /// Parses a positive decimal amount entered in the demo, rejecting malformed input.
  private func amount(_ text: String) throws -> Decimal {
    guard text.range(of: #"^-?[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil,
      text.filter({ $0.isNumber }).drop(while: { $0 == "0" }).count <= 38,
      let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")), !value.isNaN
    else {
      throw ValidationError.malformedData(reason: "Enter a decimal amount")
    }
    return value
  }
  /// Builds the selected typed order from validated decimal inputs and submits it once.
  @MainActor private func place() async {
    await perform {
      let size = try amount(size)
      if type == "TWAP" {
        guard let duration = Int(minutes) else {
          throw ValidationError.malformedData(reason: "Enter minutes")
        }
        return .twap(
          market: .coin(coin), side: side, size: size, minutes: duration, reduceOnly: reduceOnly,
          randomize: false)
      }
      if type == "Trailing stop" {
        return .trailingStop(
          market: .coin(coin), side: side, size: size, reduceOnly: reduceOnly,
          retracement: .percent(try amount(retracement)), activationPrice: nil)
      }
      let kind: PerpsOrderKind
      switch type {
      case "Market": kind = .market()
      case "Take profit":
        kind = .trigger(price: try amount(trigger), kind: .takeProfit, market: true)
      case "Stop loss": kind = .trigger(price: try amount(trigger), kind: .stopLoss, market: true)
      default: kind = .limit(tif)
      }
      return .orders(
        [
          .init(
            market: .coin(coin), side: side, size: size,
            price: type == "Limit" ? try amount(price) : nil, kind: kind, reduceOnly: reduceOnly)
        ],
        grouping: type == "Take profit" || type == "Stop loss" ? .positionTpsl : .none)
    }
  }
  /// Starts a typed action from a UI event on the main actor.
  @MainActor private func run(_ action: @escaping @MainActor () throws -> PerpsAction) {
    Task { await perform(action) }
  }
  /// Submits the selected action, displays its result, and refreshes account state.
  @MainActor private func perform(_ action: () throws -> PerpsAction) async {
    busy = true
    result = nil
    error = nil
    defer { busy = false }
    do {
      let response = try await SDKManager.shared.sdk.exchange.executePerps(action())
      if case .orders(let statuses) = response {
        for status in statuses {
          if case .rejected(let message) = status {
            throw APIError.hyperliquidError(code: 0, message: message)
          }
        }
      }
      if case .cancellations(let statuses) = response {
        for status in statuses {
          if case .rejected(let message) = status {
            throw APIError.hyperliquidError(code: 0, message: message)
          }
        }
      }
      result = describe(response)
      error = nil
      await refresh()
    } catch { show(error) }
  }
  /// Loads and cancels the open orders belonging to the selected market.
  @MainActor private func cancelOpenOrders() async {
    guard let address = SDKManager.shared.walletAddress else { return }
    busy = true
    do {
      let orders = try await SDKManager.shared.sdk.info.perps(
        .openOrders(address: address, dex: dex)
      ).filter { $0.coin == coin }
      if orders.isEmpty {
        result = "No open orders"
        error = nil
        busy = false
        return
      }
      await perform {
        .cancel(orders.map { .init(market: .coin(coin), identifier: .orderID($0.oid)) })
      }
    } catch {
      show(error)
      busy = false
    }
  }
  /// Formats typed action statuses for display and remembers a returned TWAP identifier.
  @MainActor private func describe(_ response: PerpsActionResult) -> String {
    switch response {
    case .success: return "Action succeeded"
    case .orders(let statuses):
      return statuses.map {
        switch $0 {
        case .resting(let id): return "Order placed: resting | ID: \(id)"
        case .filled(let id, let size, let price):
          return "Order filled: \(size) @ \(price) | ID: \(id)"
        case .waitingForFill: return "Order accepted: waiting for fill"
        case .waitingForTrigger: return "Order accepted: waiting for trigger"
        case .rejected(let reason): return "Rejected: " + reason
        @unknown default: return "Unknown order status"
        }
      }.joined(separator: "\n")
    case .cancellations(let statuses): return "Cancelled: \(statuses.count) orders"
    case .twap(let id):
      twapID = String(id)
      return "TWAP running | ID: \(id)"
    case .trailingStop(let id): return "Trailing stop placed | ID: \(id)"
    @unknown default: return "Unsupported action response"
    }
  }
  /// Displays an SDK or input error in the trading result area.
  @MainActor private func show(_ error: Error) {
    result = nil
    self.error = (error as? any HeliqError)?.errorDescription ?? error.localizedDescription
  }
}
