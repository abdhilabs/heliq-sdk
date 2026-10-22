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
          .accessibilityIdentifier("load_available_balances").disabled(loading)
        if loading { ProgressView("Loading balances…") }
      }
      if let balances { BalanceSections(balances: balances) }
      if let error { Section { DemoFeedback(error: error, prefix: "balance") } }
    }.navigationTitle("Available Balances").task(id: address) { await load() }
      .refreshable { await load() }
  }
  /// Reads balances for this address and ignores canceled reads when leaving the screen.
  @MainActor private func load() async {
    guard !loading else { return }
    loading = true
    defer { loading = false }
    do {
      let value: AccountBalances
      if let scenario = DemoScenario.current {
        value = try scenario.balances()
      } else if let client = SDKManager.shared.client {
        value = try await client.info.getBalances(address: address)
      } else {
        return
      }
      try Task.checkCancellation()
      balances = value
      error = nil
    } catch is CancellationError {} catch { self.error = error.demoDescription }
  }
}

enum PerpsSheet: String, Identifiable {
  case market, leverage, margin, advanced, transfer, twap
  var id: String { rawValue }
  var title: String {
    switch self {
    case .market: return "Choose market"
    case .leverage: return "Leverage & margin mode"
    case .margin: return "Adjust isolated margin"
    case .advanced: return "Advanced orders"
    case .transfer: return "Transfer USDC"
    case .twap: return "Cancel TWAP"
    }
  }
}

struct PerpsTradingView: View {
  @ObservedObject private var sdkManager = SDKManager.shared
  var initialSheet: PerpsSheet? = nil
  @Environment(\.dismiss) private var dismiss
  @Environment(\.dynamicTypeSize) private var textSize
  @State private var dex = ""
  @State private var coin = ""
  @State private var marketData: PerpsMetaAndContexts?
  @State private var balances: AccountBalances?
  @State private var capacity: PerpsActiveAssetData?
  @State private var orders: [PerpsOrder] = []
  @State private var section = "Trade"
  @State private var sheet: PerpsSheet?
  @State private var side: OrderSide = .buy
  @State private var type = "Limit"
  @State private var advancedType = "Take profit"
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
  @State private var readError: String?
  @State private var busy = false
  @State private var loading = false
  @State private var selectedPosition: String?
  @State private var revision = 0
  @State private var readID = UUID()

  private var address: String? {
    DemoScenario.current != nil ? DemoScenario.address : sdkManager.walletAddress
  }
  private var requestKey: String {
    "\(String(describing: sdkManager.client.map(ObjectIdentifier.init)))|\(String(describing: sdkManager.currentEnvironment))|\(address ?? "")|\(dex)|\(coin)|\(revision)"
  }
  private var asset: PerpsAsset? { marketData?.meta.universe.first { $0.name == coin } }
  private var context: PerpsAssetContext? {
    guard let data = marketData,
      let index = data.meta.universe.firstIndex(where: { $0.name == coin }),
      data.contexts.indices.contains(index)
    else { return nil }
    return data.contexts[index]
  }
  private var positions: [PerpsPosition] {
    balances?.perps.first(where: { $0.dex == dex })?.positions.map(\.position).filter {
      $0.szi != 0
    } ?? []
  }
  private var canSign: Bool {
    DemoScenario.current != nil || sdkManager.currentEnvironment == .testnet
  }

  var body: some View {
    Group {
      if let initialSheet {
        NavigationStack {
          actionContent(initialSheet).toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button("Done") { dismiss() }.disabled(busy)
            }
          }
        }
      } else {
        workspace.sheet(item: $sheet, onDismiss: { selectedPosition = nil }) { item in
          NavigationStack {
            actionContent(item).toolbar {
              ToolbarItem(placement: .cancellationAction) {
                Button("Done") { sheet = nil }.disabled(busy)
              }
            }
          }
          .interactiveDismissDisabled(busy)
        }
      }
    }
    .interactiveDismissDisabled(busy)
    .onChange(of: coin) { _ in
      size = ""
      price = ""
      trigger = ""
      capacity = nil
      result = nil
      error = nil
    }
    .onChange(of: dex) { _ in
      size = ""
      price = ""
      trigger = ""
      balances = nil
      orders = []
      capacity = nil
      marketData = nil
    }
    .task(id: requestKey) { await refresh() }
  }

  private var workspace: some View {
    List {
      Section {
        DemoStatus()
        if DemoScenario.current != nil {
          Text("Synthetic UI sample · no exchange requests").font(.caption).foregroundStyle(
            .secondary)
        }
        Button {
          sheet = .market
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text(coin.isEmpty ? "Choose market" : coin).font(.title2.bold())
              Text(dex.isEmpty ? "Validator Perps" : dex).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.up.chevron.down").font(.caption)
          }.foregroundStyle(.primary)
        }.accessibilityIdentifier("perps_coin").disabled(busy)
        DemoAmountRow(title: "Mark price", value: context?.markPx)
        DemoAmountRow(title: "Funding rate", value: context?.funding)
        if loading {
          ProgressView("Refreshing market and account…").accessibilityIdentifier("perps_loading")
        }
        if let readError { DemoFeedback(error: readError, prefix: "perps_read") }
        if !canSign {
          Text("This environment uses a read-only mock wallet. Connect Testnet to submit actions.")
            .font(.caption).foregroundStyle(.secondary)
        }
      }
      Section {
        if textSize.isAccessibilitySize {
          workspacePicker.pickerStyle(.menu)
        } else {
          workspacePicker.pickerStyle(.segmented)
        }
      }
      if section == "Trade" {
        if !coin.isEmpty { Section { StreamingCandleChartView(coin: coin) } }
        ticket
      } else if section == "Positions" {
        positionSections
      } else {
        orderSections
      }
      Section("Account tools") {
        if let address {
          NavigationLink("Available balances") { AvailableBalancesView(address: address) }
        }
        Button("Transfer between Spot and Perps") { sheet = .transfer }.accessibilityIdentifier(
          "open_perps_transfer")
        Button("Cancel a TWAP") { sheet = .twap }
      }
    }
    .navigationTitle("Perpetual Trading").navigationBarTitleDisplayMode(.inline)
    .toolbar {
      Button {
        revision += 1
      } label: {
        Image(systemName: "arrow.clockwise")
      }.accessibilityLabel("Refresh market and account").disabled(busy || loading)
    }
    .refreshable { await refresh() }.demoForm()
  }

  private var workspacePicker: some View {
    Picker("Workspace", selection: $section) {
      Text("Trade").tag("Trade")
      Text("Positions").tag("Positions")
      Text("Open Orders").tag("Open Orders")
    }.accessibilityIdentifier("perps_workspace")
  }

  @ViewBuilder private var feedback: some View {
    DemoFeedback(result: result, error: error, prefix: "perps")
    if busy { ProgressView("Submitting…") }
  }

  @ViewBuilder private var ticket: some View {
    Section("Order ticket") {
      Picker("Side", selection: $side) {
        Text("Buy").tag(OrderSide.buy)
        Text("Sell").tag(OrderSide.sell)
      }.pickerStyle(.segmented)
      Picker("Order type", selection: $type) {
        Text("Limit").tag("Limit")
        Text("Market").tag("Market")
      }
      DemoDecimalField(title: "Size", text: $size, unit: coin, identifier: "perps_size")
      if type == "Limit" {
        DemoDecimalField(title: "Price", text: $price, unit: "USD", identifier: "perps_price")
        Picker("Time in force", selection: $tif) {
          Text("Good till canceled").tag(PerpsTimeInForce.gtc)
          Text("Immediate or cancel").tag(PerpsTimeInForce.ioc)
          Text("Post only").tag(PerpsTimeInForce.alo)
        }
      }
      Toggle("Reduce only", isOn: $reduceOnly)
      if let validation {
        Label(validation, systemImage: "info.circle").font(.caption).foregroundStyle(.secondary)
          .accessibilityIdentifier("perps_validation")
      }
      Button("Submit Perps Order") {
        Task {
          selectedPosition = nil
          await place()
        }
      }
      .buttonStyle(.borderedProminent).controlSize(.large).accessibilityIdentifier(
        "submit_perps_order"
      )
      .disabled(
        busy || loading || asset == nil || readError != nil || coin.isEmpty || validation != nil
          || !canSign)
      feedback
    }.disabled(busy)
    Section("Trading capacity · \(coin)") {
      DemoAmountRow(title: "Available to buy", value: capacity?.availableToBuy)
      DemoAmountRow(title: "Available to sell", value: capacity?.availableToSell)
      DemoAmountRow(title: "Max buy size", value: capacity?.maxBuySize, unit: coin)
      DemoAmountRow(title: "Max sell size", value: capacity?.maxSellSize, unit: coin)
      Text("Capacity is specific to this market, not a withdrawable balance.").font(.caption)
        .foregroundStyle(.secondary)
    }
    Section("Advanced") {
      Button("TP/SL, TWAP & trailing stop") {
        advancedType = "Take profit"
        selectedPosition = nil
        sheet = .advanced
      }
      Button("Leverage & margin mode") {
        selectedPosition = nil
        sheet = .leverage
      }
    }
  }

  private var validation: String? {
    if coin.isEmpty { return "Choose a market to continue." }
    if size.isEmpty { return "Enter the order size in \(coin)." }
    guard let value = try? amount(size), value > 0 else { return "Enter a positive decimal size." }
    if let asset {
      var input = value
      var rounded = Decimal()
      NSDecimalRound(&rounded, &input, asset.szDecimals, .plain)
      if rounded != value { return "Size allows up to \(asset.szDecimals) decimal places." }
    }
    if type == "Limit", (try? amount(price)).map({ $0 > 0 }) != true {
      return "Enter a positive limit price."
    }
    return nil
  }

  @ViewBuilder private var positionSections: some View {
    if positions.isEmpty {
      Section {
        DemoEmptyState(
          title: "No open positions", message: "Positions on the selected DEX will appear here.",
          symbol: "chart.xyaxis.line")
        feedback
      }
    }
    ForEach(positions, id: \.coin) { position in
      Section(position.coin) {
        DemoAmountRow(title: "Position size", value: position.szi)
        DemoAmountRow(title: "Entry price", value: position.entryPx)
        DemoAmountRow(title: "Unrealized PnL", value: position.unrealizedPnl)
        LabeledContent("Leverage", value: "\(position.leverage.value)× · \(position.leverage.type)")
        Button("Close \(position.coin) position") {
          run { .marketClose(market: .coin(position.coin)) }
        }
        .accessibilityIdentifier("close_position_\(position.coin)")
        Button("Protect \(position.coin) with TP/SL") {
          selectedPosition = position.coin
          trigger = ""
          advancedType = "Take profit"
          size = abs(position.szi).description
          side = position.szi > 0 ? .sell : .buy
          reduceOnly = true
          sheet = .advanced
        }.accessibilityIdentifier("protect_position_\(position.coin)")
        Button("Adjust \(position.coin) isolated margin") {
          selectedPosition = position.coin
          sheet = .margin
        }
        .disabled(position.leverage.type != "isolated").accessibilityIdentifier(
          "margin_position_\(position.coin)")
        if position.leverage.type != "isolated" {
          Text("Margin adjustment is available for isolated positions.").font(.caption)
            .foregroundStyle(.secondary)
        }
        Button("Change \(position.coin) leverage") {
          selectedPosition = position.coin
          leverage = String(position.leverage.value)
          crossMargin = position.leverage.type == "cross"
          sheet = .leverage
        }
      }.disabled(busy || !canSign)
    }
    if !positions.isEmpty { Section { feedback } }
  }

  @ViewBuilder private var orderSections: some View {
    if orders.isEmpty {
      Section {
        DemoEmptyState(
          title: "No open orders", message: "Resting orders on this DEX will appear here.")
        feedback
      }
    }
    ForEach(orders, id: \.oid) { order in
      Section(order.coin + (order.side == "B" ? " · Buy" : " · Sell")) {
        DemoAmountRow(title: "Size", value: order.sz)
        DemoAmountRow(title: "Limit price", value: order.limitPx)
        Text("Order \(String(order.oid))").font(.caption.monospaced()).textSelection(.enabled)
        Button("Cancel order \(String(order.oid))") {
          run { .cancel([.init(market: .coin(order.coin), identifier: .orderID(order.oid))]) }
        }
        .accessibilityIdentifier("cancel_order_\(order.oid)").disabled(busy || !canSign)
      }
    }
    if !orders.isEmpty {
      Section {
        Button("Cancel selected market orders") { Task { await cancelOpenOrders() } }
          .accessibilityIdentifier("perps_cancel_open").disabled(
            busy || !canSign || !orders.contains { $0.coin == coin })
        feedback
      }
    }
  }

  /// Builds a focused action form while retaining the entered values after errors.
  @ViewBuilder private func actionContent(_ item: PerpsSheet) -> some View {
    if item == .market {
      PerpsMarketPicker(dex: $dex, coin: $coin)
    } else {
      List {
        Section {
          DemoStatus()
          Text(item == .transfer ? "Spot ↔ Validator Perps USDC" : (selectedPosition ?? coin)).font(
            .headline)
        }
        Section {
          switch item {
          case .transfer:
            if balances?.hasSharedCollateral == true {
              Label(
                "Shared collateral: Spot and Perps already use the same funds.", systemImage: "link"
              )
            } else if balances?.abstraction.supportsClassTransfer != true {
              Text("Transfers require a resolved standard account. Refresh balances first.")
            }
            DemoDecimalField(
              title: "Amount", text: $transferAmount, unit: "USDC",
              identifier: "perps_transfer_amount")
            Picker("Transfer direction", selection: $toPerp) {
              Text("Spot → Perps").tag(true)
              Text("Perps → Spot").tag(false)
            }.pickerStyle(.segmented)
            Button("Transfer between Spot and Perps") {
              run { .usdClassTransfer(amount: try positiveAmount(transferAmount), toPerp: toPerp) }
            }
            .accessibilityIdentifier("perps_class_transfer")
            .disabled(
              balances?.abstraction.supportsClassTransfer != true
                || (try? amount(transferAmount)).map { $0 > 0 } != true)
          case .leverage:
            DemoDecimalField(
              title: "Leverage", text: $leverage, unit: "×", identifier: "perps_leverage")
            Picker("Margin mode", selection: $crossMargin) {
              Text("Cross").tag(true)
              Text("Isolated").tag(false)
            }.pickerStyle(.segmented)
            Button("Set leverage and margin mode") {
              run {
                guard let value = Int(leverage) else {
                  throw ValidationError.malformedData(reason: "Enter integer leverage")
                }
                return .leverage(
                  market: .coin(selectedPosition ?? coin), value: value, cross: crossMargin)
              }
            }
          case .margin:
            DemoDecimalField(
              title: "Margin change", text: $margin, unit: "collateral units",
              identifier: "perps_margin", signed: true)
            Text("Use a positive amount to add margin or a negative amount to remove it.").font(
              .caption
            ).foregroundStyle(.secondary)
            Button("Adjust isolated margin") {
              run {
                .isolatedMargin(market: .coin(selectedPosition ?? coin), amount: try amount(margin))
              }
            }
            .disabled(margin.isEmpty)
          case .advanced:
            Picker("Order type", selection: $advancedType) {
              ForEach(["Take profit", "Stop loss", "TWAP", "Trailing stop"], id: \.self) {
                Text($0).tag($0)
              }
            }.accessibilityIdentifier("advanced_order_type")
            Picker("Side", selection: $side) {
              Text("Buy").tag(OrderSide.buy)
              Text("Sell").tag(OrderSide.sell)
            }.pickerStyle(.segmented)
            DemoDecimalField(
              title: "Size", text: $size, unit: selectedPosition ?? coin,
              identifier: "advanced_size")
            if advancedType == "Take profit" || advancedType == "Stop loss" {
              DemoDecimalField(
                title: "Trigger price", text: $trigger, unit: "USD", identifier: "perps_trigger")
            }
            if advancedType == "TWAP" {
              DemoDecimalField(
                title: "Duration", text: $minutes, unit: "minutes", identifier: "perps_minutes")
            }
            if advancedType == "Trailing stop" {
              DemoDecimalField(
                title: "Retracement", text: $retracement, unit: "%", identifier: "perps_retracement"
              )
            }
            Toggle("Reduce only", isOn: $reduceOnly)
            Button("Submit advanced order") { Task { await place(advancedType) } }.disabled(
              size.isEmpty)
          case .twap:
            DemoDecimalField(title: "TWAP ID", text: $twapID, identifier: "perps_twap_id")
            Button("Cancel TWAP") {
              run {
                guard let id = Int64(twapID), id > 0 else {
                  throw ValidationError.malformedData(reason: "Enter a positive integer TWAP ID")
                }
                return .cancelTwap(market: .coin(coin), id: id)
              }
            }.disabled(twapID.isEmpty)
          case .market: EmptyView()
          }
        }.disabled(busy || !canSign || (coin.isEmpty && item != .transfer))
        Section {
          feedback
          if let readError { DemoFeedback(error: readError, prefix: "perps_read") }
        }
      }.navigationTitle(item.title).navigationBarTitleDisplayMode(.inline).demoForm()
    }
  }

  /// Reads a typed endpoint from synthetic UI data or the existing connected SDK client.
  @MainActor private func read<T>(_ query: PerpsQuery<T>) async throws -> T {
    if let scenario = DemoScenario.current { return try scenario.response(query) }
    guard let client = sdkManager.client else { throw CancellationError() }
    return try await client.info.perps(query)
  }

  /// Refreshes selected-DEX data and drops obsolete reads after selection or connection changes.
  @MainActor private func refresh() async {
    guard let address else { return }
    let key = requestKey
    let id = UUID()
    readID = id
    loading = true
    defer { if key == requestKey && readID == id { loading = false } }
    do {
      if DemoScenario.current == .loading { try await Task.sleep(for: .seconds(30)) }
      let data = try await read(PerpsQuery<PerpsMetaAndContexts>.metaAndContexts(dex: dex))
      try Task.checkCancellation()
      guard key == requestKey, readID == id else { return }
      marketData = data
      if coin.isEmpty || !data.meta.universe.contains(where: { $0.name == coin }) {
        coin =
          data.meta.universe.first(where: { $0.name == "BTC" && $0.isDelisted != true })?.name
          ?? data.meta.universe.first(where: { $0.isDelisted != true })?.name ?? ""
        return
      }
      let nextBalances: AccountBalances
      if let scenario = DemoScenario.current {
        nextBalances = try scenario.balances()
      } else if let client = sdkManager.client {
        nextBalances = try await client.info.getBalances(
          address: address, dexes: dex.isEmpty ? [""] : ["", dex])
      } else {
        return
      }
      let nextOrders: [PerpsOrder] = try await read(.openOrders(address: address, dex: dex))
      let nextCapacity: PerpsActiveAssetData = try await read(
        .activeAsset(address: address, coin: coin))
      try Task.checkCancellation()
      guard key == requestKey, readID == id else { return }
      balances = nextBalances
      orders = nextOrders
      capacity = nextCapacity
      readError = nil
    } catch is CancellationError {} catch {
      guard key == requestKey, readID == id else { return }
      self.readError = error.demoDescription
    }
  }
  /// Parses an exact signed decimal input; action-specific sign rules remain enforced by the SDK.
  private func amount(_ text: String) throws -> Decimal {
    guard text.range(of: #"^-?[0-9]+(?:\.[0-9]+)?$"#, options: .regularExpression) != nil,
      text.filter({ $0.isNumber }).drop(while: { $0 == "0" }).count <= 38,
      let value = Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")), !value.isNaN
    else {
      throw ValidationError.malformedData(reason: "Enter a decimal amount")
    }
    return value
  }
  /// Requires a positive amount for order and transfer fields while allowing signed margin changes.
  private func positiveAmount(_ text: String) throws -> Decimal {
    let value = try amount(text)
    guard value > 0 else {
      throw ValidationError.malformedData(reason: "Enter an amount greater than zero")
    }
    return value
  }
  /// Builds the selected typed order from validated decimal inputs and submits it once.
  @MainActor private func place(_ orderType: String? = nil) async {
    let type = orderType ?? self.type
    await perform {
      let size = try positiveAmount(size)
      if type == "TWAP" {
        guard let duration = Int(minutes), (5...1440).contains(duration) else {
          throw ValidationError.malformedData(reason: "Enter a duration of 5–1440 minutes")
        }
        return .twap(
          market: .coin(selectedPosition ?? coin), side: side, size: size, minutes: duration,
          reduceOnly: reduceOnly,
          randomize: false)
      }
      if type == "Trailing stop" {
        return .trailingStop(
          market: .coin(selectedPosition ?? coin), side: side, size: size, reduceOnly: reduceOnly,
          retracement: .percent(try positiveAmount(retracement)), activationPrice: nil)
      }
      let kind: PerpsOrderKind
      switch type {
      case "Market": kind = .market()
      case "Take profit":
        kind = .trigger(price: try positiveAmount(trigger), kind: .takeProfit, market: true)
      case "Stop loss":
        kind = .trigger(price: try positiveAmount(trigger), kind: .stopLoss, market: true)
      default: kind = .limit(tif)
      }
      return .orders(
        [
          .init(
            market: .coin(selectedPosition ?? coin), side: side, size: size,
            price: type == "Limit" ? try positiveAmount(price) : nil, kind: kind,
            reduceOnly: reduceOnly)
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
    guard !busy else { return }
    busy = true
    result = nil
    error = nil
    defer { busy = false }
    do {
      let prepared = try action()
      if let scenario = DemoScenario.current {
        result =
          scenario == .partial
          ? "1 accepted; 1 rejected: sample precision error"
          : "Sample action validated; no exchange request sent"
        return
      }
      guard let client = sdkManager.client else {
        throw ValidationError.malformedData(reason: "Connect in Settings first")
      }
      let response = try await client.exchange.executePerps(prepared)
      result = describe(response)
      error = nil
      await refresh()
    } catch { show(error) }
  }
  /// Cancels only orders on the current market using their actual exchange identifiers.
  @MainActor private func cancelOpenOrders() async {
    let selected = orders.filter { $0.coin == coin }
    guard !selected.isEmpty else {
      result = "No open orders"
      return
    }
    await perform {
      .cancel(selected.map { .init(market: .coin($0.coin), identifier: .orderID($0.oid)) })
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
    case .cancellations(let statuses):
      return statuses.map { status in
        switch status {
        case .success: return "Cancellation accepted"
        case .rejected(let reason): return "Rejected: " + reason
        @unknown default: return "Unknown cancellation status"
        }
      }.joined(separator: "\n")
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
    self.error = (error as? any HeliqError)?.errorDescription ?? error.demoDescription
  }
}
