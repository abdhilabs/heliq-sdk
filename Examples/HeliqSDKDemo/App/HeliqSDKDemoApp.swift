//
//  HeliqSDKDemoApp.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import HeliqSDK
import SwiftUI

@main
struct HeliqSDKDemoApp: App {
  var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
  @State private var tab = 0
  private var manager: SDKManager { .shared }

  var body: some View {
    TabView(selection: $tab) {
      NavigationStack {
        OverviewView(onTrade: { tab = 1 }, onSettings: { tab = 3 })
      }.tabItem { Label("Overview", systemImage: "rectangle.grid.1x2") }.tag(0)
      NavigationStack {
        if manager.isInitialized || DemoScenario.current != nil {
          PerpsTradingView()
        } else {
          disconnected(title: "Perpetual Trading")
        }
      }.tabItem { Label("Perpetuals", systemImage: "chart.xyaxis.line") }.tag(1)
      NavigationStack {
        List {
          Section { DemoStatus() }
          Section("Query and inspect") {
            NavigationLink {
              InfoView()
            } label: {
              Label("Info", systemImage: "magnifyingglass")
            }.accessibilityIdentifier("nav_info")
            NavigationLink {
              WebSocketView()
            } label: {
              Label("WebSocket", systemImage: "waveform.path")
            }.accessibilityIdentifier("nav_websocket")
          }
          .disabled(!manager.isInitialized)
          Section("Exchange and signing examples") {
            NavigationLink {
              TradingView()
            } label: {
              Label("Trading", systemImage: "arrow.left.arrow.right")
            }.accessibilityIdentifier("nav_trading")
            NavigationLink {
              WalletView()
            } label: {
              Label("Wallet", systemImage: "key")
            }.accessibilityIdentifier("nav_wallet")
          }
          .disabled(!manager.isInitialized)
          if !manager.isInitialized {
            Section {
              DemoEmptyState(
                title: "Connect to explore",
                message: "Initialize an environment in Settings to run SDK examples.",
                symbol: "network")
              Button("Open Settings") { tab = 3 }
            }
          }
        }
        .navigationTitle("API Explorer").accessibilityIdentifier("api_explorer")
      }.id(manager.isInitialized).tabItem { Label("API Explorer", systemImage: "curlybraces") }.tag(
        2)
      NavigationStack { SettingsView() }
        .tabItem { Label("Settings", systemImage: "gearshape") }.tag(3)
    }

  }

  /// Explains why trading is unavailable and offers a direct connection shortcut.
  private func disconnected(title: String) -> some View {
    List {
      Section { DemoStatus() }
      Section {
        DemoEmptyState(
          title: "Connect before trading",
          message: "Select an environment and initialize the SDK in Settings.", symbol: "network")
        Button("Open Settings") { tab = 3 }.accessibilityIdentifier("connect_from_perps")
      }
    }.navigationTitle(title)
  }
}
