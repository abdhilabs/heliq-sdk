//
//  OverviewView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 15/10/26.
//

import HeliqSDK
import SwiftUI

struct OverviewView: View {
  var onTrade: () -> Void
  var onSettings: () -> Void
  @State private var balances: AccountBalances?
  @State private var loading = false
  @State private var error: String?
  @State private var transfer = false
  @State private var readID = UUID()
  @ObservedObject private var manager = SDKManager.shared
  private var address: String? {
    DemoScenario.current != nil ? DemoScenario.address : manager.walletAddress
  }

  private var requestKey: String {
    "\(address ?? "")|\(String(describing: manager.client.map(ObjectIdentifier.init)))"
  }

  var body: some View {
    List {
      Section {
        DemoStatus()
        if DemoScenario.current != nil {
          Label("Synthetic UI sample", systemImage: "testtube.2").font(.caption)
        }
      }
      if let address {
        Section("Account") {
          Text(address).font(.footnote.monospaced()).textSelection(.enabled)
            .accessibilityIdentifier("overview_wallet")
          Button(action: onTrade) { Label("Trade", systemImage: "chart.xyaxis.line") }
            .buttonStyle(.borderedProminent).controlSize(.large)
          Button { transfer = true } label: {
            Label("Transfer", systemImage: "arrow.left.arrow.right")
          }
            .buttonStyle(.bordered).controlSize(.large)
          NavigationLink("Wallet details") { WalletView() }.disabled(DemoScenario.current != nil)
        }
        if loading {
          Section {
            ProgressView("Loading balances…").accessibilityElement(children: .ignore)
              .accessibilityLabel("Loading balances").accessibilityIdentifier("balances_loading")
          }
        }
        if let balances { BalanceSections(balances: balances) }
        if let error { Section { DemoFeedback(error: error, prefix: "balance") } }
        if balances == nil && !loading && error == nil {
          Section {
            DemoEmptyState(
              title: "No balances loaded", message: "Pull to refresh account balances.")
          }
        }
      } else {
        Section {
          DemoEmptyState(
            title: "Your trading workspace",
            message:
              "Connect an environment to view balances, explore markets, and trade with the SDK.",
            symbol: "chart.xyaxis.line")
          Button("Open Settings", action: onSettings).buttonStyle(.borderedProminent).controlSize(
            .large)
        }
        Section("Explore the sample") {
          Text(
            "Perpetuals provides a trading workspace. API Explorer keeps individual SDK examples available."
          )
          .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Overview")
    .toolbar {
      Button(action: { Task { await refresh() } }) { Image(systemName: "arrow.clockwise") }
        .accessibilityLabel("Refresh balances").disabled(address == nil || loading)
    }
    .refreshable { await refresh() }
    .task(id: requestKey) { await refresh() }
    .sheet(isPresented: $transfer) { PerpsTradingView(initialSheet: .transfer) }
  }

  /// Loads balances for the current connection and discards canceled or superseded responses.
  @MainActor private func refresh() async {
    guard let address else {
      balances = nil
      error = nil
      return
    }
    let key = requestKey
    let id = UUID()
    readID = id
    loading = true
    defer { if readID == id { loading = false } }
    do {
      if DemoScenario.current == .loading { try await Task.sleep(for: .seconds(30)) }
      let value: AccountBalances
      if let scenario = DemoScenario.current {
        value = try scenario.balances()
      } else if let client = manager.client {
        value = try await client.info.getBalances(address: address)
      } else {
        return
      }
      try Task.checkCancellation()
      guard key == requestKey, readID == id else { return }
      balances = value
      error = nil
    } catch is CancellationError {} catch {
      if readID == id && key == requestKey { self.error = error.demoDescription }
    }
  }
}

struct BalanceSections: View {
  let balances: AccountBalances
  var body: some View {
    Section("Balance model") {
      Label(
        balances.hasSharedCollateral
          ? "Shared Spot / Perps collateral"
          : (balances.abstraction.hasSeparateBalances
            ? "Separate Spot and Perps balances" : "Unresolved account mode"),
        systemImage: balances.hasSharedCollateral ? "link" : "rectangle.split.2x1"
      )
      .accessibilityIdentifier("balance_mode")
      Text(balances.abstraction.rawValue).font(.caption).foregroundStyle(.secondary)
      Text("Unheld funds are not a guarantee of withdrawal or trading capacity.")
        .font(.caption).foregroundStyle(.secondary)
    }
    if balances.spot.isEmpty {
      Section {
        DemoEmptyState(
          title: "No Spot balances", message: "This account has no token balances to display.")
      }
    }
    ForEach(balances.spot, id: \.token) { token in
      Section(token.coin) {
        DemoAmountRow(title: "Total", value: token.total)
        DemoAmountRow(title: "Held", value: token.held)
        DemoAmountRow(title: "Unheld", value: token.unheld)
        DemoAmountRow(title: "Available after maintenance", value: token.availableAfterMaintenance)
        DemoAmountRow(title: "Withdrawable", value: token.withdrawable)
      }
    }
    ForEach(balances.perps, id: \.dex) { dex in
      Section(dex.dex.isEmpty ? "Validator Perps" : dex.dex) {
        if balances.hasSharedCollateral {
          Text("Collateral is included in Spot above.").font(.subheadline).foregroundStyle(
            .secondary)
        } else {
          DemoAmountRow(title: "Account value", value: dex.accountValue)
          DemoAmountRow(title: "Margin used", value: dex.marginUsed)
          DemoAmountRow(title: "Withdrawable", value: dex.withdrawable)
        }
        LabeledContent("Positions", value: String(dex.positions.count))
      }
    }
  }
}
