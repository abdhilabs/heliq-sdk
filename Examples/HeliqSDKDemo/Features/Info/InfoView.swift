//
//  InfoView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI
import HeliqSDK

struct InfoView: View {
  @State private var selectedSection: InfoSection = .marketData
  @State private var isLoading = false
  @State private var errorMessage: String?
  
  @State private var allMids: AllMids?
  @State private var assetCtxs: [AssetContext] = []
  @State private var spotAssetCtxs: [SpotAssetContext] = []
  @State private var l2Book: L2Book?
  @State private var candles: [Candle] = []
  @State private var userState: UserState?
  @State private var spotUserState: SpotUserState?
  @State private var fills: [Fill] = []
  @State private var userFundings: [UserFunding] = []
  @State private var meta: Meta?
  @State private var spotMeta: Meta?
  @State private var builderFee: BuilderFee?
  @State private var orders: [Order] = []
  
  @State private var selectedCoin = "BTC"
  @State private var orderIdInput = ""
  @State private var cloidInput = ""
  @State private var userAddressInput = ""
  @State private var builderAddressInput = ""
  @State private var candleInterval = "1m"
  @State private var candleCoinInput = "BTC"
  
  private let sdkManager = SDKManager.shared
  
  enum InfoSection: String, CaseIterable {
    case marketData = "Market Data"
    case userData = "User Data"
    case metadata = "Metadata"
  }
  
  var body: some View {
    List {
      Section {
        Picker("Section", selection: $selectedSection) {
          ForEach(InfoSection.allCases, id: \.self) { section in
            Text(section.rawValue).tag(section)
          }
        }
        .pickerStyle(.segmented)
      }
      
      switch selectedSection {
      case .marketData:
        marketDataSection
      case .userData:
        userDataSection
      case .metadata:
        metadataSection
      }

      if isLoading {
        Section {
          HStack {
            ProgressView()
            Text("Loading…")
          }
        }
      }

      if let errorMessage {
        Section("Error") {
          Text(errorMessage)
            .foregroundStyle(.red)
            .accessibilityIdentifier("info_error")
        }
      }
    }
    .navigationTitle("Info API")
    .refreshable {
      await refreshCurrentSection()
    }
  }
  
  @ViewBuilder
  private var marketDataSection: some View {
    Section("All Mids") {
      if let mids = allMids {
        ForEach(Array(mids.prices.sorted(by: { $0.key < $1.key }).prefix(20)), id: \.key) { coin, price in
          HStack {
            Text(coin)
              .font(.headline)
            Spacer()
            Text(String(format: "%.2f", price))
              .font(.system(.body, design: .monospaced))
          }
        }
        if mids.prices.count > 20 {
          Text("... and \(mids.prices.count - 20) more")
            .foregroundStyle(.secondary)
        }
      } else {
        Text("Tap to load")
          .foregroundStyle(.secondary)
      }
      Button("Load All Mids") {
        Task { await loadAllMids() }
      }
    }
    
    Section("Asset Contexts (Perpetual)") {
      if assetCtxs.isEmpty {
        Text("No asset contexts loaded")
          .foregroundStyle(.secondary)
      } else {
        ForEach(assetCtxs, id: \.asset) { ctx in
          VStack(alignment: .leading, spacing: 2) {
            Text(ctx.name)
              .font(.headline)
            Text("Asset #\(ctx.asset) | Sz: \(ctx.szDecimals) | Wei: \(ctx.weiDecimals)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      Button("Load Asset Contexts") {
        Task { await loadAssetCtxs() }
      }
    }
    
    Section("Spot Asset Contexts") {
      if spotAssetCtxs.isEmpty {
        Text("No spot asset contexts loaded")
          .foregroundStyle(.secondary)
      } else {
        ForEach(spotAssetCtxs, id: \.asset) { ctx in
          VStack(alignment: .leading, spacing: 2) {
            Text(ctx.name)
              .font(.headline)
            Text("Asset #\(ctx.asset)")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      Button("Load Spot Asset Contexts") {
        Task { await loadSpotAssetCtxs() }
      }
    }
    
    Section("Order Book (L2)") {
      TextField("Coin (e.g. BTC)", text: $selectedCoin)
        .textInputAutocapitalization(.characters)
      if let book = l2Book {
        VStack(alignment: .leading, spacing: 4) {
          Text("Coin: \(book.coin)")
            .font(.headline)
          Text("Levels: \(book.levels.count)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        HStack {
          Text("Bids")
            .foregroundStyle(.green)
            .frame(maxWidth: .infinity)
          Text("Asks")
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity)
        }
        .font(.caption)
        .padding(.vertical, 4)
        
        let bids = book.levels.filter { $0.side == .sell }.prefix(5)
        let asks = book.levels.filter { $0.side == .buy }.prefix(5)
        
        HStack(alignment: .top) {
          VStack(alignment: .trailing, spacing: 2) {
            ForEach(bids) { level in
              Text("\(String(format: "%.2f", level.price)) | \(String(format: "%.4f", level.size))")
                .font(.system(.caption2, design: .monospaced))
            }
          }
          .frame(maxWidth: .infinity)
          
          VStack(alignment: .leading, spacing: 2) {
            ForEach(asks) { level in
              Text("\(String(format: "%.2f", level.price)) | \(String(format: "%.4f", level.size))")
                .font(.system(.caption2, design: .monospaced))
            }
          }
          .frame(maxWidth: .infinity)
        }
      }
      Button("Load Order Book") {
        Task { await loadL2Book() }
      }
    }
    
    Section("Candles") {
      TextField("Coin", text: $candleCoinInput)
        .textInputAutocapitalization(.characters)
      Picker("Interval", selection: $candleInterval) {
        Text("1m").tag("1m")
        Text("15m").tag("15m")
        Text("1h").tag("1h")
        Text("1d").tag("1d")
      }
      .pickerStyle(.segmented)
      
      if !candles.isEmpty {
        CandleChartView(candles: candles, coin: candleCoinInput)
          .frame(height: 250)
      }
      
      Button("Load Candles") {
        Task { await loadCandles() }
      }
    }
    
  }
  
  @ViewBuilder
  private var userDataSection: some View {
    Section("User Address") {
      TextField("Wallet Address", text: $userAddressInput)
        .textInputAutocapitalization(.never)
      if sdkManager.walletAddress != nil && userAddressInput.isEmpty {
        Button("Use Demo Wallet") {
          userAddressInput = sdkManager.walletAddress ?? ""
        }
        .foregroundStyle(.secondary)
      }
    }
    
    Section("User State (Perpetual)") {
      if let state = userState {
        UserStateView(userState: state)
      }
      Button("Load User State") {
        Task { await loadUserState() }
      }
      .disabled(userAddressInput.isEmpty)
    }
    
    Section("Spot User State") {
      if let state = spotUserState {
        SpotUserStateView(spotState: state)
      }
      Button("Load Spot User State") {
        Task { await loadSpotUserState() }
      }
      .disabled(userAddressInput.isEmpty)
    }
    
    Section("Fills") {
      if !fills.isEmpty {
        ForEach(fills) { fill in
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text(fill.symbol)
                .font(.headline)
              Text(fill.side.rawValue)
                .foregroundStyle(fill.side == .buy ? .green : .red)
              Spacer()
              Text(String(format: "%.4f @ %.2f", fill.size, fill.price))
                .font(.system(.caption, design: .monospaced))
            }
            Text("Fee: \(String(format: "%.2f", fill.fee)) | \(formatDate(fill.timestamp))")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      Button("Load Fills") {
        Task { await loadFills() }
      }
      .disabled(userAddressInput.isEmpty)
    }
    
    Section("User Fundings") {
      if !userFundings.isEmpty {
        ForEach(userFundings, id: \.time) { funding in
          HStack {
            Text("Asset #\(funding.asset)")
              .font(.headline)
            Spacer()
            Text(String(format: "%.4f", funding.payment))
              .foregroundStyle(funding.payment >= 0 ? .green : .red)
          }
          Text("Rate: \(String(format: "%.6f", funding.rate)) | \(formatDate(funding.time))")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      Button("Load Fundings") {
        Task { await loadUserFundings() }
      }
      .disabled(userAddressInput.isEmpty)
    }
    
    Section("Order Queries") {
      TextField("Order ID", text: $orderIdInput)
        .textInputAutocapitalization(.never)
      Button("Query by OID") {
        Task { await queryOrderByOid() }
      }
      .disabled(orderIdInput.isEmpty)
      
      Divider()
      
      TextField("CLOB ID (cloid)", text: $cloidInput)
        .textInputAutocapitalization(.never)
      Button("Query by CLOB ID") {
        Task { await queryOrderByCloid() }
      }
      .disabled(cloidInput.isEmpty)
    }
  }
  
  @ViewBuilder
  private var metadataSection: some View {
    Section("Meta (Perpetual)") {
      if let meta = meta {
        ForEach(meta.universe.prefix(10)) { asset in
          VStack(alignment: .leading, spacing: 2) {
            Text(asset.name)
              .font(.headline)
            Text("Asset #\(asset.asset) | Sz: \(asset.szDecimals) | Wei: \(asset.weiDecimals)")
              .font(.caption)
              .foregroundStyle(.secondary)
            if asset.onlyIsolatedMargin {
              Text("Isolated Margin Only")
                .font(.caption2)
                .foregroundStyle(.orange)
            }
          }
        }
        if meta.universe.count > 10 {
          Text("... and \(meta.universe.count - 10) more")
            .foregroundStyle(.secondary)
        }
      }
      Button("Load Meta") {
        Task { await loadMeta() }
      }
    }
    
    Section("Spot Meta") {
      if let meta = spotMeta {
        ForEach(Array(meta.universe.prefix(10)), id: \.id) { asset in
          VStack(alignment: .leading, spacing: 2) {
            Text(asset.name)
              .font(.headline)
            if let tokenCfg = meta.spotAssetConfigs["\(asset.asset)"]?.tokenCfg {
              Text(tokenCfg.symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
        if meta.universe.count > 10 {
          Text("... and \(meta.universe.count - 10) more")
            .foregroundStyle(.secondary)
        }
      }
      Button("Load Spot Meta") {
        Task { await loadSpotMeta() }
      }
    }
    
    Section("Builder Fee") {
      TextField("Builder Address", text: $builderAddressInput)
        .textInputAutocapitalization(.never)
      if let fee = builderFee {
        VStack(alignment: .leading, spacing: 4) {
          Text(fee.builderAddress)
            .font(.caption)
            .foregroundStyle(.secondary)
          Text("Fee: \(fee.feeBps) bps")
            .font(.headline)
        }
      }
      Button("Fetch Builder Fee") {
        Task { await fetchBuilderFee() }
      }
      .disabled(builderAddressInput.isEmpty)
    }
  }
  
  private func refreshCurrentSection() async {
    switch selectedSection {
    case .marketData:
      await loadAllMids()
      await loadAssetCtxs()
      await loadSpotAssetCtxs()
    case .userData:
      if !userAddressInput.isEmpty {
        await loadUserState()
        await loadSpotUserState()
        await loadFills()
        await loadUserFundings()
      }
    case .metadata:
      await loadMeta()
      await loadSpotMeta()
    }
  }
  
  private func performInfoRequest(_ operation: () async throws -> Void) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      try await operation()
    } catch {
      let displayedError: String
      if let heliqError = error as? any HeliqError {
        displayedError = "\(heliqError.errorCode): \(heliqError.errorDescription)"
      } else {
        displayedError = error.localizedDescription
      }
      errorMessage = displayedError
      Logger.shared.error("info-ui-error message=\(displayedError)", category: .general)
    }
  }

  private func loadAllMids() async {
    await performInfoRequest {
      allMids = try await sdkManager.sdk.info.getAllMids()
    }
  }
  
  private func loadAssetCtxs() async {
    await performInfoRequest {
      assetCtxs = try await sdkManager.sdk.info.getAssetCtxs()
    }
  }
  
  private func loadSpotAssetCtxs() async {
    await performInfoRequest {
      spotAssetCtxs = try await sdkManager.sdk.info.getSpotAssetCtxs()
    }
  }
  
  private func loadL2Book() async {
    guard !selectedCoin.isEmpty else { return }
    await performInfoRequest {
      l2Book = try await sdkManager.sdk.info.getL2Book(coin: selectedCoin.uppercased())
    }
  }
  
  private func loadCandles() async {
    guard !candleCoinInput.isEmpty else { return }
    let endTime = Date()
    let startTime = endTime.addingTimeInterval(-3600 * 24)
    await performInfoRequest {
      candles = try await sdkManager.sdk.info.getCandleSnapshot(
        coin: candleCoinInput.uppercased(),
        interval: candleInterval,
        startTime: startTime,
        endTime: endTime
      )
    }
  }
  
  private func loadUserState() async {
    guard !userAddressInput.isEmpty else { return }
    await performInfoRequest {
      userState = try await sdkManager.sdk.info.getUserState(address: userAddressInput)
    }
  }
  
  private func loadSpotUserState() async {
    guard !userAddressInput.isEmpty else { return }
    await performInfoRequest {
      spotUserState = try await sdkManager.sdk.info.getSpotUserState(address: userAddressInput)
    }
  }
  
  private func loadFills() async {
    guard !userAddressInput.isEmpty else { return }
    await performInfoRequest {
      fills = try await sdkManager.sdk.info.queryFills(address: userAddressInput)
    }
  }
  
  private func loadUserFundings() async {
    guard !userAddressInput.isEmpty else { return }
    await performInfoRequest {
      userFundings = try await sdkManager.sdk.info.queryUserFundings(address: userAddressInput)
    }
  }
  
  private func queryOrderByOid() async {
    guard !orderIdInput.isEmpty else { return }
    await performInfoRequest {
      orders = try await sdkManager.sdk.info.queryOrderByOid(orderId: orderIdInput)
    }
  }
  
  private func queryOrderByCloid() async {
    guard !cloidInput.isEmpty else { return }
    await performInfoRequest {
      orders = try await sdkManager.sdk.info.queryOrderByCloid(cloid: cloidInput)
    }
  }
  
  private func loadMeta() async {
    await performInfoRequest {
      meta = try await sdkManager.sdk.info.getMeta()
    }
  }
  
  private func loadSpotMeta() async {
    await performInfoRequest {
      spotMeta = try await sdkManager.sdk.info.getSpotMeta()
    }
  }
  
  private func fetchBuilderFee() async {
    guard !builderAddressInput.isEmpty else { return }
    await performInfoRequest {
      builderFee = try await sdkManager.sdk.info.fetchBuilderFee(builderAddress: builderAddressInput)
    }
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter.string(from: date)
  }
}
