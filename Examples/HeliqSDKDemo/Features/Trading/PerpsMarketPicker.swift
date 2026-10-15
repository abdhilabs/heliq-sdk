//
//  PerpsMarketPicker.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 15/10/26.
//

import HeliqSDK
import SwiftUI

struct PerpsMarketPicker: View {
  @Binding var dex: String
  @Binding var coin: String
  @Environment(\.dismiss) private var dismiss
  @State private var selectedDex = ""
  @State private var dexs = [""]
  @State private var markets: [PerpsAsset] = []
  @State private var search = ""
  @State private var loading = false
  @State private var error: String?

  private var filteredDexs: [String] {
    dexs.filter {
      search.isEmpty || $0.localizedCaseInsensitiveContains(search) || $0 == selectedDex
    }
  }
  private var filteredMarkets: [PerpsAsset] {
    markets.filter { search.isEmpty || $0.name.localizedCaseInsensitiveContains(search) }
  }

  var body: some View {
    List {
      Section("DEX") {
        Picker("Trading venue", selection: $selectedDex) {
          ForEach(filteredDexs, id: \.self) { Text($0.isEmpty ? "Validator Perps" : $0).tag($0) }
        }.accessibilityIdentifier("perps_dex_picker")
        Text("Search a DEX name to narrow the venue list, or search a coin on the selected DEX.")
          .font(.caption).foregroundStyle(.secondary)
      }
      Section("Markets") {
        if loading { ProgressView("Loading markets…") }
        ForEach(filteredMarkets, id: \.name) { asset in
          Button {
            dex = selectedDex
            coin = asset.name
            dismiss()
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(asset.name).font(.headline)
                Text("Up to \(asset.maxLeverage)× · \(asset.szDecimals) size decimals").font(
                  .caption
                ).foregroundStyle(.secondary)
              }
              Spacer()
              if coin == asset.name && dex == selectedDex {
                Image(systemName: "checkmark").accessibilityLabel("Selected")
              }
            }.foregroundStyle(.primary).padding(.vertical, 4)
          }.accessibilityIdentifier("market_\(asset.name)")
        }
        if !loading && filteredMarkets.isEmpty && error == nil {
          DemoEmptyState(
            title: "No matching markets", message: "Try another coin name or DEX.",
            symbol: "magnifyingglass")
        }
        if let error { DemoFeedback(error: error, prefix: "market") }
      }
    }
    .navigationTitle("Choose market").navigationBarTitleDisplayMode(.inline)
    .searchable(text: $search, prompt: "Search DEX or coin")
    .onAppear { selectedDex = dex }
    .task { await loadDexs() }
    .task(id: selectedDex) { await loadMarkets() }
  }

  /// Loads the venue registry without changing the account's selected market.
  @MainActor private func loadDexs() async {
    do {
      let values: [PerpsDex?]
      if DemoScenario.current != nil {
        dexs = ["", "sample"]
        return
      }
      guard let client = SDKManager.shared.client else { return }
      values = try await client.info.perps(.dexs())
      try Task.checkCancellation()
      dexs = [""] + values.compactMap { $0?.name }.filter { !$0.isEmpty }
    } catch is CancellationError {} catch { self.error = error.demoDescription }
  }

  /// Loads searchable metadata for the selected venue and ignores superseded responses.
  @MainActor private func loadMarkets() async {
    let selected = selectedDex
    loading = true
    markets = []
    error = nil
    defer { if selected == selectedDex { loading = false } }
    do {
      let data: PerpsMetaAndContexts
      if let scenario = DemoScenario.current {
        data = try scenario.response(.metaAndContexts(dex: selected))
      } else if let client = SDKManager.shared.client {
        data = try await client.info.perps(.metaAndContexts(dex: selected))
      } else {
        return
      }
      try Task.checkCancellation()
      guard selected == selectedDex else { return }
      markets = data.meta.universe.filter { $0.isDelisted != true }
    } catch is CancellationError {} catch {
      guard selected == selectedDex else { return }
      self.error = error.demoDescription
    }
  }
}
