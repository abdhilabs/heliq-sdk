//
//  TradingView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import HeliqSDK
import SwiftUI
import UIKit

struct TradingView: View {
  @State private var selectedSection: TradingSection = .orders
  @State private var operationResult: String?
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
      
      if let result = operationResult {
        Section("Result") {
          Text(result)
            .accessibilityIdentifier("trade_result")
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.green)
        }
      }
      
      if let error = errorMessage {
        Section("Error") {
          Text(error)
            .accessibilityIdentifier("trade_error")
            .foregroundStyle(.red)
        }
      }
    }
    .navigationTitle("Exchange API")
    .toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button("Done") {
          UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil
          )
        }
      }
    }
  }
  
  @ViewBuilder
  private var ordersSection: some View {
    Section {
      NavigationLink("Typed Perps trading", destination: PerpsTradingView())
        .accessibilityIdentifier("open_typed_perps")
    }
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
      TextField("Signer addresses, comma separated", text: $authorizedUsers)
        .accessibilityIdentifier("trade_multisig_users")
        .textInputAutocapitalization(.never)
      TextField("Approval threshold", text: $threshold)
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

  private func cancelAll() async {
    errorMessage = nil
    do {
      let response = try await sdkManager.sdk.exchange.cancelAll()
      operationResult = "Cancelled: \(response.cancelledOrders.count) orders"
      if !response.failedCancels.isEmpty {
        errorMessage = "Failed cancels: \(response.failedCancels.count)"
      }
    } catch {
      showError(error)
    }
  }
  
  private func convertToMultiSig() async {
    errorMessage = nil
    do {
      let response = try await sdkManager.sdk.exchange.convertToMultiSigUser(authorizedUsers: authorizedUsers.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }, threshold: Int(threshold) ?? 0)
      operationResult = "Multi-sig conversion: \(response.status)"
    } catch {
      showError(error)
    }
  }
}

struct PlaceOrderForm: View {
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
    TextField("Asset (#)", text: $asset)
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
    TextField("Size", text: $size)
      .accessibilityIdentifier("trade_PlaceOrderForm_size")
      .keyboardType(.decimalPad)
    if orderType == .limit {
      TextField("Price", text: $price)
      .accessibilityIdentifier("trade_PlaceOrderForm_price")
        .keyboardType(.decimalPad)
    }
    Button("Place Order") {
      submit()
    }
    .disabled(asset.isEmpty || size.isEmpty || (orderType == .limit && price.isEmpty))
  }
  
  private func submit() {
    let type: OrderType = orderType == .market ? .market : .limit
    let order = OrderRequest(
      asset: Int(asset) ?? 1,
      side: side,
      orderType: type,
      size: Double(size) ?? 0,
      price: orderType == .limit ? Double(price) : nil
    )
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.placeOrder(order)
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
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.bulkOrders(JSONDecoder().decode([OrderRequest].self, from: Data(ordersJson.utf8)))
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
  @State private var orderId = ""
  @State private var asset = "1"
  
  let onSubmit: (CancelResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Order ID", text: $orderId)
      .accessibilityIdentifier("trade_CancelOrderForm_orderId")
      .textInputAutocapitalization(.never)
    TextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_CancelOrderForm_asset")
    Button("Cancel Order") {
      submit()
    }
    .disabled(orderId.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.cancelOrder(
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
  @State private var cloid = ""
  @State private var asset = "1"
  
  let onSubmit: (CancelResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("CLOB ID", text: $cloid)
      .accessibilityIdentifier("trade_CancelByCloidForm_cloid")
      .textInputAutocapitalization(.never)
    TextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_CancelByCloidForm_asset")
    Button("Cancel by CLOB ID") {
      submit()
    }
    .disabled(cloid.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.cancelByCloid(
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
  @State private var orderId = ""
  @State private var asset = "1"
  @State private var size = ""
  @State private var price = ""
  
  let onSubmit: (OrderResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Order ID", text: $orderId)
      .accessibilityIdentifier("trade_ModifyOrderForm_orderId")
      .textInputAutocapitalization(.never)
    TextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_ModifyOrderForm_asset")
    TextField("New Size (optional)", text: $size)
      .accessibilityIdentifier("trade_ModifyOrderForm_size")
      .keyboardType(.decimalPad)
    TextField("New Price (optional)", text: $price)
      .accessibilityIdentifier("trade_ModifyOrderForm_price")
      .keyboardType(.decimalPad)
    Button("Modify Order") {
      submit()
    }
    .disabled(orderId.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.modifyOrder(
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
  @State private var asset = "1"
  @State private var leverage = "10"
  
  let onSubmit: (SetLeverageResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_SetLeverageForm_asset")
    TextField("Leverage", text: $leverage)
      .accessibilityIdentifier("trade_SetLeverageForm_leverage")
      .keyboardType(.numberPad)
    Button("Set Leverage") {
      submit()
    }
    .disabled(leverage.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.setLeverage(
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
  @State private var asset = "1"
  @State private var mode: MarginMode = .cross
  
  let onSubmit: (SetMarginModeResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_SetMarginModeForm_asset")
    Picker("Mode", selection: $mode) {
      Text("Cross").tag(MarginMode.cross)
      Text("Isolated").tag(MarginMode.isolated)
    }
    .pickerStyle(.segmented)
    Button("Set Margin Mode") {
      submit()
    }
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.setMarginMode(
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
  @State private var toAddress = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (TransferResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("To Address", text: $toAddress)
      .accessibilityIdentifier("trade_TransferForm_toAddress")
      .textInputAutocapitalization(.never)
    TextField("Amount", text: $amount)
      .accessibilityIdentifier("trade_TransferForm_amount")
      .keyboardType(.decimalPad)
    TextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_TransferForm_asset")
    Button("Transfer") {
      submit()
    }
    .disabled(toAddress.isEmpty || amount.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.transfer(
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
  @State private var address = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (SendToAddressResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Address", text: $address)
      .accessibilityIdentifier("trade_SendToAddressForm_address")
      .textInputAutocapitalization(.never)
    TextField("Amount", text: $amount)
      .accessibilityIdentifier("trade_SendToAddressForm_amount")
      .keyboardType(.decimalPad)
    TextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_SendToAddressForm_asset")
    Button("Send to Address") {
      submit()
    }
    .disabled(address.isEmpty || amount.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.sendToAddress(
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
  @State private var toAddress = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (SpotTransferResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("To Address", text: $toAddress)
      .accessibilityIdentifier("trade_SpotTransferForm_toAddress")
      .textInputAutocapitalization(.never)
    TextField("Amount", text: $amount)
      .accessibilityIdentifier("trade_SpotTransferForm_amount")
      .keyboardType(.decimalPad)
    TextField("Asset (#)", text: $asset)
      .accessibilityIdentifier("trade_SpotTransferForm_asset")
    Button("Spot Transfer") {
      submit()
    }
    .disabled(toAddress.isEmpty || amount.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.spotTransfer(
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
  @State private var vaultAddress = ""
  @State private var isFromVault = true
  @State private var amount = ""
  
  let onSubmit: (VaultTransferResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Vault Address", text: $vaultAddress)
      .accessibilityIdentifier("trade_VaultTransferForm_vaultAddress")
      .textInputAutocapitalization(.never)
    Picker("Direction", selection: $isFromVault) {
      Text("To Vault").tag(false)
      Text("From Vault").tag(true)
    }
    .pickerStyle(.segmented)
    TextField("USDC Amount", text: $amount)
      .accessibilityIdentifier("trade_VaultTransferForm_amount")
      .keyboardType(.decimalPad)
    Button("Vault Transfer") {
      submit()
    }
    .disabled(vaultAddress.isEmpty || amount.isEmpty)
  }
  
  private func submit() {
    let vaultTransfer = VaultTransfer(
      fromVault: isFromVault,
      toVault: !isFromVault,
      usdcAmount: Double(amount) ?? 0,
      vaultAddress: vaultAddress
    )
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.vaultTransfer(vaultTransfer: vaultTransfer)
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
  @State private var builderAddress = ""
  @State private var maxFeeRate = ""
  
  let onSubmit: (UpdateBuilderResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Builder Address", text: $builderAddress)
      .accessibilityIdentifier("trade_UpdateBuilderForm_builderAddress")
      .textInputAutocapitalization(.never)
    TextField("Maximum fee (e.g. 0.01%)", text: $maxFeeRate)
      .accessibilityIdentifier("trade_UpdateBuilderForm_maxFeeRate")
    Button("Update Builder") {
      submit()
    }
    .disabled(builderAddress.isEmpty || maxFeeRate.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.updateBuilder(builderAddress: builderAddress, maxFeeRate: maxFeeRate)
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
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.scheduleCancel(
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
  @State private var referrer = ""
  
  let onSubmit: (SetReferrerResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Referral Code", text: $referrer)
      .accessibilityIdentifier("trade_SetReferrerForm_referrer")
      .textInputAutocapitalization(.never)
    Button("Set Referrer") {
      submit()
    }
    .disabled(referrer.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.setReferrer(referrer: referrer)
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
  @State private var destination = ""
  @State private var amount = ""
  
  let onSubmit: (UsdSendResponse) -> Void
  let onError: (Error) -> Void
  
  var body: some View {
    TextField("Destination", text: $destination)
      .accessibilityIdentifier("trade_UsdSendForm_destination")
      .textInputAutocapitalization(.never)
    TextField("Amount", text: $amount)
      .accessibilityIdentifier("trade_UsdSendForm_amount")
      .keyboardType(.decimalPad)
    Button("Send USDC") {
      submit()
    }
    .disabled(destination.isEmpty || amount.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.usdSend(
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
