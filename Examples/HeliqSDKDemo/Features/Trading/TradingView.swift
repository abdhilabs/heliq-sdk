//
//  TradingView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI
import HeliqSDK

struct TradingView: View {
  @State private var selectedSection: TradingSection = .orders
  @State private var operationResult: String?
  @State private var isLoading = false
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
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.green)
        }
      }
      
      if let error = errorMessage {
        Section("Error") {
          Text(error)
            .foregroundStyle(.red)
        }
      }
    }
    .navigationTitle("Exchange API")
  }
  
  @ViewBuilder
  private var ordersSection: some View {
    Section("Place Order") {
      PlaceOrderForm(onSubmit: { response in
        operationResult = "Order placed: \(response.status) | ID: \(response.orderId ?? "N/A")"
      })
    }
    
    Section("Bulk Orders") {
      BulkOrdersForm(onSubmit: { response in
        operationResult = "Bulk orders: \(response.responses.count) responses"
      })
    }
    
    Section("Cancel Order") {
      CancelOrderForm(onSubmit: { response in
        operationResult = "Cancel: \(response.status)"
      })
    }
    
    Section("Cancel by CLOB ID") {
      CancelByCloidForm(onSubmit: { response in
        operationResult = "Cancel: \(response.status)"
      })
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
        operationResult = "Modify: \(response.status)"
      })
    }
  }
  
  @ViewBuilder
  private var positionSection: some View {
    Section("Set Leverage") {
      SetLeverageForm(onSubmit: { response in
        operationResult = "Leverage set: \(response.leverage)x"
      })
    }
    
    Section("Set Margin Mode") {
      SetMarginModeForm(onSubmit: { response in
        operationResult = "Margin mode: \(response.status)"
      })
    }
  }
  
  @ViewBuilder
  private var transfersSection: some View {
    Section("Internal Transfer") {
      TransferForm(onSubmit: { response in
        operationResult = "Transfer: \(response.status) | Hash: \(response.hash ?? "N/A")"
      })
    }
    
    Section("Send to Address") {
      SendToAddressForm(onSubmit: { response in
        operationResult = "Send: \(response.status) | Hash: \(response.hash ?? "N/A")"
      })
    }
    
    Section("Spot Transfer") {
      SpotTransferForm(onSubmit: { response in
        operationResult = "Spot transfer: \(response.status)"
      })
    }
    
    Section("Vault Transfer") {
      VaultTransferForm(onSubmit: { response in
        operationResult = "Vault transfer: \(response.status)"
      })
    }
    
    Section("Update Builder") {
      UpdateBuilderForm(onSubmit: { response in
        operationResult = "Update builder: \(response.status)"
      })
    }
  }
  
  @ViewBuilder
  private var accountSection: some View {
    Section("Schedule Cancel") {
      ScheduleCancelForm(onSubmit: { response in
        operationResult = "Scheduled cancel: \(response.status) at \(response.scheduledTime)"
      })
    }
    
    Section("Set Referrer") {
      SetReferrerForm(onSubmit: { response in
        operationResult = "Referrer set: \(response.status)"
      })
    }
    
    Section("Multi-Sig") {
      Button("Convert to Multi-Sig User") {
        Task {
          await convertToMultiSig()
        }
      }
    }
    
    Section("USDC Send") {
      UsdSendForm(onSubmit: { response in
        operationResult = "USDC send: \(response.status) | Hash: \(response.hash ?? "N/A")"
      })
    }
  }
  
  private func cancelAll() async {
    do {
      let response = try await sdkManager.sdk.exchange.cancelAll()
      operationResult = "Cancelled: \(response.cancelledOrders.count) orders"
      if !response.failedCancels.isEmpty {
        errorMessage = "Failed cancels: \(response.failedCancels.count)"
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }
  
  private func convertToMultiSig() async {
    do {
      let response = try await sdkManager.sdk.exchange.convertToMultiSigUser()
      operationResult = "Multi-sig conversion: \(response.status)"
    } catch {
      errorMessage = error.localizedDescription
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
  
  enum OrderTypeSelection: String, CaseIterable {
    case market = "Market"
    case limit = "Limit"
  }
  
  var body: some View {
    TextField("Asset (#)", text: $asset)
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
      .keyboardType(.decimalPad)
    if orderType == .limit {
      TextField("Price", text: $price)
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
        await MainActor.run {
          // Handle error
        }
      }
    }
  }
}

struct BulkOrdersForm: View {
  @State private var ordersJson = "[{\"asset\":1,\"side\":\"Buy\",\"type\":\"limit\",\"size\":0.01,\"price\":50000}]"
  
  let onSubmit: (BulkOrderResponse) -> Void
  
  var body: some View {
    TextEditor(text: $ordersJson)
      .font(.system(.caption, design: .monospaced))
      .frame(height: 100)
    Button("Submit Bulk Orders") {
      submit()
    }
  }
  
  private func submit() {
    // Simplified - in real app would parse JSON
    let order = OrderRequest(
      asset: 1,
      side: .buy,
      orderType: .limit,
      size: 0.01,
      price: 50000
    )
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.bulkOrders([order])
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        // Handle error
      }
    }
  }
}

struct CancelOrderForm: View {
  @State private var orderId = ""
  @State private var asset = "1"
  
  let onSubmit: (CancelResponse) -> Void
  
  var body: some View {
    TextField("Order ID", text: $orderId)
      .textInputAutocapitalization(.never)
    TextField("Asset (#)", text: $asset)
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
        // Handle error
      }
    }
  }
}

struct CancelByCloidForm: View {
  @State private var cloid = ""
  @State private var asset = "1"
  
  let onSubmit: (CancelResponse) -> Void
  
  var body: some View {
    TextField("CLOB ID", text: $cloid)
      .textInputAutocapitalization(.never)
    TextField("Asset (#)", text: $asset)
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
        // Handle error
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
  
  var body: some View {
    TextField("Order ID", text: $orderId)
      .textInputAutocapitalization(.never)
    TextField("Asset (#)", text: $asset)
    TextField("New Size (optional)", text: $size)
      .keyboardType(.decimalPad)
    TextField("New Price (optional)", text: $price)
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
        // Handle error
      }
    }
  }
}

struct SetLeverageForm: View {
  @State private var asset = "1"
  @State private var leverage = "10"
  
  let onSubmit: (SetLeverageResponse) -> Void
  
  var body: some View {
    TextField("Asset (#)", text: $asset)
    TextField("Leverage", text: $leverage)
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
        // Handle error
      }
    }
  }
}

struct SetMarginModeForm: View {
  @State private var asset = "1"
  @State private var mode: MarginMode = .cross
  
  let onSubmit: (SetMarginModeResponse) -> Void
  
  var body: some View {
    TextField("Asset (#)", text: $asset)
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
        // Handle error
      }
    }
  }
}

struct TransferForm: View {
  @State private var toAddress = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (TransferResponse) -> Void
  
  var body: some View {
    TextField("To Address", text: $toAddress)
      .textInputAutocapitalization(.never)
    TextField("Amount", text: $amount)
      .keyboardType(.decimalPad)
    TextField("Asset (#)", text: $asset)
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
        // Handle error
      }
    }
  }
}

struct SendToAddressForm: View {
  @State private var address = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (SendToAddressResponse) -> Void
  
  var body: some View {
    TextField("Address", text: $address)
      .textInputAutocapitalization(.never)
    TextField("Amount", text: $amount)
      .keyboardType(.decimalPad)
    TextField("Asset (#)", text: $asset)
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
        // Handle error
      }
    }
  }
}

struct SpotTransferForm: View {
  @State private var toAddress = ""
  @State private var amount = ""
  @State private var asset = "0"
  
  let onSubmit: (SpotTransferResponse) -> Void
  
  var body: some View {
    TextField("To Address", text: $toAddress)
      .textInputAutocapitalization(.never)
    TextField("Amount", text: $amount)
      .keyboardType(.decimalPad)
    TextField("Asset (#)", text: $asset)
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
        // Handle error
      }
    }
  }
}

struct VaultTransferForm: View {
  @State private var vaultAddress = ""
  @State private var isFromVault = true
  @State private var amount = ""
  
  let onSubmit: (VaultTransferResponse) -> Void
  
  var body: some View {
    TextField("Vault Address", text: $vaultAddress)
      .textInputAutocapitalization(.never)
    Picker("Direction", selection: $isFromVault) {
      Text("To Vault").tag(true)
      Text("From Vault").tag(false)
    }
    .pickerStyle(.segmented)
    TextField("USDC Amount", text: $amount)
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
        // Handle error
      }
    }
  }
}

struct UpdateBuilderForm: View {
  @State private var builderAddress = ""
  
  let onSubmit: (UpdateBuilderResponse) -> Void
  
  var body: some View {
    TextField("Builder Address", text: $builderAddress)
      .textInputAutocapitalization(.never)
    Button("Update Builder") {
      submit()
    }
    .disabled(builderAddress.isEmpty)
  }
  
  private func submit() {
    Task {
      do {
        let response = try await SDKManager.shared.sdk.exchange.updateBuilder(builderAddress: builderAddress)
        await MainActor.run {
          onSubmit(response)
        }
      } catch {
        // Handle error
      }
    }
  }
}

struct ScheduleCancelForm: View {
  @State private var timeOffset: TimeInterval = 60
  
  let onSubmit: (ScheduleCancelResponse) -> Void
  
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
        // Handle error
      }
    }
  }
}

struct SetReferrerForm: View {
  @State private var referrer = ""
  
  let onSubmit: (SetReferrerResponse) -> Void
  
  var body: some View {
    TextField("Referrer Address", text: $referrer)
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
        // Handle error
      }
    }
  }
}

struct UsdSendForm: View {
  @State private var destination = ""
  @State private var amount = ""
  
  let onSubmit: (UsdSendResponse) -> Void
  
  var body: some View {
    TextField("Destination", text: $destination)
      .textInputAutocapitalization(.never)
    TextField("Amount", text: $amount)
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
        // Handle error
      }
    }
  }
}
