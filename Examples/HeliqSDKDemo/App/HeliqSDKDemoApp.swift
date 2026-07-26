//
//  HeliqSDKDemoApp.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI
import HeliqSDK

@main
struct HeliqSDKDemoApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

struct ContentView: View {
  @State private var sdkManager = SDKManager.shared
  
  var body: some View {
    NavigationStack {
      List {
        if !sdkManager.isInitialized {
          ConnectionBanner()
        }
        
        NavigationLink("Info") {
          InfoView()
        }
        .accessibilityIdentifier("nav_info")
        NavigationLink("Trading") {
          TradingView()
        }
        .accessibilityIdentifier("nav_trading")
        NavigationLink("WebSocket") {
          WebSocketView()
        }
        .accessibilityIdentifier("nav_websocket")
        NavigationLink("Wallet") {
          WalletView()
        }
        .accessibilityIdentifier("nav_wallet")
        NavigationLink("Settings") {
          SettingsView()
        }
        .accessibilityIdentifier("nav_settings")
      }
      .navigationTitle("HeliqSDK Demo")
      .accessibilityIdentifier("home_list")
    }
  }
}

struct ConnectionBanner: View {
  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: "exclamationmark.triangle.fill")
        .foregroundStyle(.orange)
        .font(.caption)
      Text("Not connected")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }
}
