//
//  TradingView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import HeliqSDK
import SwiftUI

struct TradingView: View {
  @State private var selectedSection: TradingSection = .orders
  @State private var operationResult: String?
  @State private var isPerforming = false
  @State private var authorizedUsers = ""
  @State private var threshold = ""
  @State private var errorMessage: String?
  
  private let sdkManager = SDKManager.shared
  
  enum TradingSection: String, CaseIterable {
    case orders = "Orders"
    case position = "Position"
    case transfers = "Transfers"
    case account = "Account"
  }
  
  var body: some View {
    List {
      Section {
        Picker("Section", selection: $selectedSection) {
          ForEach(TradingSection.allCases, id: \.self) { section in
            Text(section.rawValue).tag(section)
          }
        }
        .pickerStyle(.segmented)
      }

      if !sdkManager.isInitialized {
        Section {
          Text("SDK not initialized. Go to Settings to initialize.")
            .foregroundStyle(.secondary)
        }
      } else {
        if operationResult != nil || errorMessage != nil {
          Section("Request feedback") {
            DemoFeedback(result: operationResult, error: errorMessage, prefix: "trade")
          }
        }
        if isPerforming { ProgressView("Submitting…") }
        switch selectedSection {
        case .orders:
          ordersSection
        case .position:
          positionSection
        case .transfers:
          transfersSection
        case .account:
          accountSection
        }
      }
    }
    .disabled(isPerforming)
    .navigationTitle("Exchange API")
    .demoForm()
  }
  
  @ViewBuilder
  private var ordersSection: some View {
    Section("Place Order") {
      PlaceOrderForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Order placed: \(response.status) | ID: \(response.orderId ?? "N/A")"
      }, onError: showError)
    }
    
    Section("Bulk Orders") {
      BulkOrdersForm(onSubmit: { response in
        errorMessage = nil
        let failures = response.responses.compactMap(\.error)
        operationResult = "Bulk orders: \(response.responses.count - failures.count) accepted, \(failures.count) failed"
        if !failures.isEmpty { errorMessage = failures.joined(separator: "\n") }
      }, onError: showError)
    }
    
    Section("Cancel Order") {
      CancelOrderForm(onSubmit: { response in
        errorMessage = nil
        operationResult = response.error == nil ? "Cancel: \(response.status)" : nil
        errorMessage = response.error
      }, onError: showError)
    }
    
    Section("Cancel by CLOB ID") {
      CancelByCloidForm(onSubmit: { response in
        errorMessage = nil
        operationResult = response.error == nil ? "Cancel: \(response.status)" : nil
        errorMessage = response.error
      }, onError: showError)
    }
    
    Section("Cancel All") {
      Button("Cancel All Orders") {
        Task {
          await cancelAll()
        }
      }
    }
    
    Section("Modify Order") {
      ModifyOrderForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Modify: \(response.status)"
      }, onError: showError)
    }
  }
  
  @ViewBuilder
  private var positionSection: some View {
    Section("Set Leverage") {
      SetLeverageForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Leverage set: \(response.leverage)x"
      }, onError: showError)
    }
    
    Section("Set Margin Mode") {
      SetMarginModeForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Margin mode: \(response.status)"
      }, onError: showError)
    }
  }
  
  @ViewBuilder
  private var transfersSection: some View {
    Section("Internal Transfer") {
      TransferForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Transfer: \(response.status) | Hash: \(response.hash ?? "N/A")"
      }, onError: showError)
    }
    
    Section("Send to Address") {
      SendToAddressForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Send: \(response.status) | Hash: \(response.hash ?? "N/A")"
      }, onError: showError)
    }
    
    Section("Spot Transfer") {
      SpotTransferForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Spot transfer: \(response.status)"
      }, onError: showError)
    }
    
    Section("Vault Transfer") {
      VaultTransferForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Vault transfer: \(response.status)"
      }, onError: showError)
    }
    
    Section("Update Builder") {
      UpdateBuilderForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Update builder: \(response.status)"
      }, onError: showError)
    }
  }
  
  @ViewBuilder
  private var accountSection: some View {
    Section("Schedule Cancel") {
      ScheduleCancelForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Scheduled cancel: \(response.status) at \(response.scheduledTime)"
      }, onError: showError)
    }
    
    Section("Set Referrer") {
      SetReferrerForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "Referrer set: \(response.status)"
      }, onError: showError)
    }
    
    Section("Multi-Sig") {
      DemoTextField("Signer addresses, comma separated", text: $authorizedUsers)
        .accessibilityIdentifier("trade_multisig_users")
        .textInputAutocapitalization(.never)
      DemoTextField("Approval threshold", text: $threshold)
        .accessibilityIdentifier("trade_multisig_threshold")
        .keyboardType(.numberPad)
      Button("Convert to Multi-Sig User") {
        Task {
          await convertToMultiSig()
        }
      }
      .disabled(authorizedUsers.isEmpty || threshold.isEmpty)
    }
    
    Section("USDC Send") {
      UsdSendForm(onSubmit: { response in
        errorMessage = nil
        operationResult = "USDC send: \(response.status) | Hash: \(response.hash ?? "N/A")"
      }, onError: showError)
    }
  }
  
  private func showError(_ error: Error) {
    operationResult = nil
    if let sdkError = error as? any HeliqError {
      errorMessage = "\(sdkError.errorCode): \(sdkError.errorDescription)"
    } else {
      errorMessage = error.localizedDescription
    }
  }

  /// Submits the account operation once using the current connection.
  private func cancelAll() async {
    guard !isPerforming, let client = sdkManager.client else { return }
    isPerforming = true
    defer { isPerforming = false }
    errorMessage = nil
    do {
      let response = try await client.exchange.cancelAll()
      operationResult = "Cancelled: \(response.cancelledOrders.count) orders"
      if !response.failedCancels.isEmpty {
        errorMessage = "Failed cancels: \(response.failedCancels.count)"
      }
    } catch {
      showError(error)
    }
  }
  
  /// Submits the account operation once using the current connection.
  private func convertToMultiSig() async {
    guard !isPerforming, let client = sdkManager.client else { return }
    isPerforming = true
    defer { isPerforming = false }
    errorMessage = nil
    do {
      let response = try await client.exchange.convertToMultiSigUser(authorizedUsers: authorizedUsers.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }, threshold: Int(threshold) ?? 0)
      operationResult = "Multi-sig conversion: \(response.status)"
    } catch {
      showError(error)
    }
  }
}

struct PlaceOrderForm: View {
  @State private var isSubmitting = false
  @State private var asset = "1"
  @State private var side: OrderSide = .buy
  @State private var orderType: OrderTypeSelection = .limit
  @State private var size = ""
  @State private var price = ""
  
  let onSubmit: (OrderResponse) -> Void
  let onError: (Error) -> Void
  
  enum OrderTypeSelection: String, CaseIterable {
    case market = "Market"
    case limit = "Limit"
  }
  
  var body: some View {
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_PlaceOrderForm_asset")
    Picker("Side", selection: $side) {
      Text("Buy").tag(OrderSide.buy)
      Text("Sell").tag(OrderSide.sell)
    }
    .pickerStyle(.segmented)
    Picker("Type", selection: $orderType) {
      ForEach(OrderTypeSelection.allCases, id: \.self) { orderType in
        Text(orderType.rawValue).tag(orderType)
      }
    }
    .pickerStyle(.segmented)
    DemoTextField("Size", text: $size)
      .accessibilityIdentifier("trade_PlaceOrderForm_size")
      .keyboardType(.decimalPad)
    if orderType == .limit {
      DemoTextField("Price", text: $price)
      .accessibilityIdentifier("trade_PlaceOrderForm_price")
        .keyboardType(.decimalPad)
    }
    Button("Place Order") {
      submit()
    }
    .disabled(isSubmitting || asset.isEmpty || size.isEmpty || (orderType == .limit && price.isEmpty))
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    let type: OrderType = orderType == .market ? .market : .limit
    let order = OrderRequest(
      asset: Int(asset) ?? 1,
      side: side,
      orderType: type,
      size: Double(size) ?? 0,
      price: orderType == .limit ? Double(price) : nil
    )
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.placeOrder(order)
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct BulkOrdersForm: View {
  @State private var isSubmitting = false
  @State private var ordersJson = "[{\"asset\":1,\"side\":\"Buy\",\"orderType\":{\"type\":\"limit\"},\"size\":0.01,\"price\":50000,\"reduceOnly\":false}]"
  
  let onSubmit: (BulkOrderResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextEditor(text: $ordersJson)
      .font(.system(.caption, design: .monospaced))
      .frame(height: 100)
    Button("Submit Bulk Orders") {
      submit()
    }
    .disabled(isSubmitting)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.bulkOrders(JSONDecoder().decode([OrderRequest].self, from: Data(ordersJson.utf8)))
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct CancelOrderForm: View {
  @State private var isSubmitting = false
  @State private var orderId = ""
  @State private var asset = "1"
  
  let onSubmit: (CancelResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Order ID", text: $orderId)
      .accessibilityIdentifier("trade_CancelOrderForm_orderId")
      .textInputAutocapitalization(.never)
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_CancelOrderForm_asset")
    Button("Cancel Order") {
      submit()
    }
    .disabled(isSubmitting || orderId.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.cancelOrder(
          orderId: orderId,
          asset: Int(asset) ?? 1
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct CancelByCloidForm: View {
  @State private var isSubmitting = false
  @State private var cloid = ""
  @State private var asset = "1"
  
  let onSubmit: (CancelResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("CLOB ID", text: $cloid)
      .accessibilityIdentifier("trade_CancelByCloidForm_cloid")
      .textInputAutocapitalization(.never)
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_CancelByCloidForm_asset")
    Button("Cancel by CLOB ID") {
      submit()
    }
    .disabled(isSubmitting || cloid.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.cancelByCloid(
          cloid: cloid,
          asset: Int(asset) ?? 1
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct ModifyOrderForm: View {
  @State private var isSubmitting = false
  @State private var orderId = ""
  @State private var asset = "1"
  @State private var size = ""
  @State private var price = ""
  
  let onSubmit: (OrderResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Order ID", text: $orderId)
      .accessibilityIdentifier("trade_ModifyOrderForm_orderId")
      .textInputAutocapitalization(.never)
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_ModifyOrderForm_asset")
    DemoTextField("New Size (optional)", text: $size)
      .accessibilityIdentifier("trade_ModifyOrderForm_size")
      .keyboardType(.decimalPad)
    DemoTextField("New Price (optional)", text: $price)
      .accessibilityIdentifier("trade_ModifyOrderForm_price")
      .keyboardType(.decimalPad)
    Button("Modify Order") {
      submit()
    }
    .disabled(isSubmitting || orderId.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.modifyOrder(
          orderId: orderId,
          asset: Int(asset) ?? 1,
          size: size.isEmpty ? nil : Double(size),
          price: price.isEmpty ? nil : Double(price)
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct SetLeverageForm: View {
  @State private var isSubmitting = false
  @State private var asset = "1"
  @State private var leverage = "10"
  
  let onSubmit: (SetLeverageResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_SetLeverageForm_asset")
    DemoTextField("Leverage", text: $leverage)
      .accessibilityIdentifier("trade_SetLeverageForm_leverage")
      .keyboardType(.numberPad)
    Button("Set Leverage") {
      submit()
    }
    .disabled(isSubmitting || leverage.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.setLeverage(
          asset: Int(asset) ?? 1,
          leverage: Int(leverage) ?? 10
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct SetMarginModeForm: View {
  @State private var isSubmitting = false
  @State private var asset = "1"
  @State private var mode: MarginMode = .cross
  
  let onSubmit: (SetMarginModeResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_SetMarginModeForm_asset")
    Picker("Mode", selection: $mode) {
      Text("Cross").tag(MarginMode.cross)
      Text("Isolated").tag(MarginMode.isolated)
    }
    .pickerStyle(.segmented)
    Button("Set Margin Mode") {
      submit()
    }
    .disabled(isSubmitting)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.setMarginMode(
          asset: Int(asset) ?? 1,
          mode: mode
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct TransferForm: View {
  @State private var isSubmitting = false
  @State private var toAddress = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (TransferResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("To Address", text: $toAddress)
      .accessibilityIdentifier("trade_TransferForm_toAddress")
      .textInputAutocapitalization(.never)
    DemoTextField("Amount", text: $amount)
      .accessibilityIdentifier("trade_TransferForm_amount")
      .keyboardType(.decimalPad)
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_TransferForm_asset")
    Button("Transfer") {
      submit()
    }
    .disabled(isSubmitting || toAddress.isEmpty || amount.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.transfer(
          fromAddress: SDKManager.shared.walletAddress ?? "",
          toAddress: toAddress,
          amount: Double(amount) ?? 0,
          asset: Int(asset) ?? 0
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct SendToAddressForm: View {
  @State private var isSubmitting = false
  @State private var address = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (SendToAddressResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Address", text: $address)
      .accessibilityIdentifier("trade_SendToAddressForm_address")
      .textInputAutocapitalization(.never)
    DemoTextField("Amount", text: $amount)
      .accessibilityIdentifier("trade_SendToAddressForm_amount")
      .keyboardType(.decimalPad)
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_SendToAddressForm_asset")
    Button("Send to Address") {
      submit()
    }
    .disabled(isSubmitting || address.isEmpty || amount.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.sendToAddress(
          address: address,
          amount: Double(amount) ?? 0,
          asset: Int(asset) ?? 0
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct SpotTransferForm: View {
  @State private var isSubmitting = false
  @State private var toAddress = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (SpotTransferResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("To Address", text: $toAddress)
      .accessibilityIdentifier("trade_SpotTransferForm_toAddress")
      .textInputAutocapitalization(.never)
    DemoTextField("Amount", text: $amount)
      .accessibilityIdentifier("trade_SpotTransferForm_amount")
      .keyboardType(.decimalPad)
    DemoTextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_SpotTransferForm_asset")
    Button("Spot Transfer") {
      submit()
    }
    .disabled(isSubmitting || toAddress.isEmpty || amount.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.spotTransfer(
          toAddress: toAddress,
          amount: Double(amount) ?? 0,
          asset: Int(asset) ?? 0
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct VaultTransferForm: View {
  @State private var isSubmitting = false
  @State private var vaultAddress = ""
  @State private var isFromVault = true
  @State private var amount = ""
  
  let onSubmit: (VaultTransferResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Vault Address", text: $vaultAddress)
      .accessibilityIdentifier("trade_VaultTransferForm_vaultAddress")
      .textInputAutocapitalization(.never)
    Picker("Direction", selection: $isFromVault) {
      Text("To Vault").tag(false)
      Text("From Vault").tag(true)
    }
    .pickerStyle(.segmented)
    DemoTextField("USDC Amount", text: $amount)
      .accessibilityIdentifier("trade_VaultTransferForm_amount")
      .keyboardType(.decimalPad)
    Button("Vault Transfer") {
      submit()
    }
    .disabled(isSubmitting || vaultAddress.isEmpty || amount.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    let vaultTransfer = VaultTransfer(
      fromVault: isFromVault,
      toVault: !isFromVault,
      usdcAmount: Double(amount) ?? 0,
      vaultAddress: vaultAddress
    )
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.vaultTransfer(vaultTransfer: vaultTransfer)
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct UpdateBuilderForm: View {
  @State private var isSubmitting = false
  @State private var builderAddress = ""
  @State private var maxFeeRate = ""
  
  let onSubmit: (UpdateBuilderResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Builder Address", text: $builderAddress)
      .accessibilityIdentifier("trade_UpdateBuilderForm_builderAddress")
      .textInputAutocapitalization(.never)
    DemoTextField("Maximum fee (e.g. 0.01%)", text: $maxFeeRate)
      .accessibilityIdentifier("trade_UpdateBuilderForm_maxFeeRate")
    Button("Update Builder") {
      submit()
    }
    .disabled(isSubmitting || builderAddress.isEmpty || maxFeeRate.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.updateBuilder(builderAddress: builderAddress, maxFeeRate: maxFeeRate)
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct ScheduleCancelForm: View {
  @State private var isSubmitting = false
  @State private var timeOffset: TimeInterval = 60
  
  let onSubmit: (ScheduleCancelResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    Picker("Cancel In", selection: $timeOffset) {
      Text("1 min").tag(60.0)
      Text("5 min").tag(300.0)
      Text("10 min").tag(600.0)
      Text("1 hour").tag(3600.0)
    }
    .pickerStyle(.segmented)
    Button("Schedule Cancel") {
      submit()
    }
    .disabled(isSubmitting)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.scheduleCancel(
          time: Date().addingTimeInterval(timeOffset)
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct SetReferrerForm: View {
  @State private var isSubmitting = false
  @State private var referrer = ""
  
  let onSubmit: (SetReferrerResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Referral Code", text: $referrer)
      .accessibilityIdentifier("trade_SetReferrerForm_referrer")
      .textInputAutocapitalization(.never)
    Button("Set Referrer") {
      submit()
    }
    .disabled(isSubmitting || referrer.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.setReferrer(referrer: referrer)
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}

struct UsdSendForm: View {
  @State private var isSubmitting = false
  @State private var destination = ""
  @State private var amount = ""
  
  let onSubmit: (UsdSendResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    DemoTextField("Destination", text: $destination)
      .accessibilityIdentifier("trade_UsdSendForm_destination")
      .textInputAutocapitalization(.never)
    DemoTextField("Amount", text: $amount)
      .accessibilityIdentifier("trade_UsdSendForm_amount")
      .keyboardType(.decimalPad)
    Button("Send USDC") {
      submit()
    }
    .disabled(isSubmitting || destination.isEmpty || amount.isEmpty)
    if isSubmitting { ProgressView("Submitting…") }
  }
  
  /// Submits this example once and retains the entered parameters after a failure.
  private func submit() {
    guard !isSubmitting else { return }
    isSubmitting = true
    Task {
      defer { isSubmitting = false }
      guard let client = SDKManager.shared.client else {
        onError(ValidationError.malformedData(reason: "Connect in Settings first")); return
      }
      do {
        let response = try await client.exchange.usdSend(
          destination: destination,
          amount: Double(amount) ?? 0
        )
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        await MainActor.run { onError(error) }
      }
    }
  }
}
