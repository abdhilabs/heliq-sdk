//
//  SettingsView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI
import HeliqSDK

struct SettingsView: View {
  @State private var selectedEnvironment: HeliqEnvironment = .mainnet
  @State private var isInitializing = false
  @State private var showInitSuccess = false
  @State private var errorMessage: String?
  
  @ObservedObject private var sdkManager = SDKManager.shared
  
  var body: some View {
    List {
      Section("SDK Status") {
        HStack {
          Text("Initialized")
          Spacer()
          if sdkManager.isInitialized {
            Label("Yes", systemImage: "checkmark.circle.fill")
              .foregroundStyle(.green)
          } else {
            Label("No", systemImage: "xmark.circle.fill")
              .foregroundStyle(.red)
          }
        }
        
        if sdkManager.isInitialized {
          HStack {
            Text("Environment")
            Spacer()
            Text(environmentName(sdkManager.currentEnvironment))
              .foregroundStyle(.secondary)
          }
          
          if let address = sdkManager.walletAddress {
            HStack {
              Text("Signing wallet")
              Spacer()
              Text("\(address.prefix(10))...")
                .foregroundStyle(.secondary)
            }
          }
        }
      }
      
      Section("Selected environment") {
        ForEach([HeliqEnvironment.mainnet, .testnet, .local], id: \.self) { env in
          Button {
            selectedEnvironment = env
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 4) {
                Text(environmentName(env))
                  .font(.headline)
                Text(environmentURL(env))
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              if selectedEnvironment == env {
                Image(systemName: "checkmark")
                  .foregroundStyle(.blue)
              }
            }
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("environment_" + environmentName(env).lowercased())
          .disabled(isInitializing)
        }
      }
      
      Section {
        Text(sdkManager.isInitialized
          ? "Connected to \(environmentName(sdkManager.currentEnvironment)). Disconnect before applying a different environment."
          : "Choose an environment, then initialize. Testnet uses the saved test wallet; other environments use a read-only mock.")
          .font(.subheadline).foregroundStyle(.secondary)
        if sdkManager.isInitialized {
          LabeledContent("Wallet type", value: sdkManager.currentEnvironment == .testnet ? "Persistent testnet wallet" : "Read-only mock")
        }
      }
      Section("Initialize SDK") {
        Button {
          Task { await initializeSDK() }
        } label: {
          HStack {
            if isInitializing {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text("Initialize for \(environmentName(selectedEnvironment))")
          }
        }
        .disabled(isInitializing || sdkManager.isInitialized)
        .foregroundStyle(sdkManager.isInitialized ? .secondary : .primary)
        .accessibilityIdentifier("initialize_sdk")
      }
      
      if sdkManager.isInitialized {
        Section("Disconnect") {
          Button(role: .destructive) {
            sdkManager.disconnect()
          } label: {
            HStack {
              Image(systemName: "xmark.circle")
              Text("Disconnect SDK")
            }
          }
        }
      }
      
      Section("SDK Info") {
        LabeledContent("Version") {
          Text("1.0.0")
            .foregroundStyle(.secondary)
        }
        
        LabeledContent("Build") {
          Text("1")
            .foregroundStyle(.secondary)
        }
        
        LabeledContent("Swift Version") {
          Text("6.1 tools · Swift 6 mode")
            .foregroundStyle(.secondary)
        }
      }
      
      Section("API Endpoints") {
        VStack(alignment: .leading, spacing: 8) {
          Text("Mainnet")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(Constants.API.mainnetBaseURL)
            .font(.system(.caption, design: .monospaced))
          Text(Constants.WebSocket.mainnetURL)
            .font(.system(.caption2, design: .monospaced))
        }
        
        VStack(alignment: .leading, spacing: 8) {
          Text("Testnet")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(Constants.API.testnetBaseURL)
            .font(.system(.caption, design: .monospaced))
          Text(Constants.WebSocket.testnetURL)
            .font(.system(.caption2, design: .monospaced))
        }
        
        VStack(alignment: .leading, spacing: 8) {
          Text("Local")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(Constants.API.localBaseURL)
            .font(.system(.caption, design: .monospaced))
          Text(Constants.WebSocket.localURL)
            .font(.system(.caption2, design: .monospaced))
        }
      }
      
      if let error = errorMessage {
        Section("Error") {
          Text(error)
            .accessibilityIdentifier("settings_error")
            .foregroundStyle(.red)
        }
      }
    }
    .navigationTitle("Settings")
    .demoForm()
    .alert("SDK Initialized", isPresented: $showInitSuccess) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("SDK has been successfully initialized for \(environmentName(selectedEnvironment))")
    }
    .onAppear {
      selectedEnvironment = sdkManager.currentEnvironment
    }
  }
  
  private func environmentName(_ env: HeliqEnvironment) -> String {
    switch env {
    case .mainnet: return "Mainnet"
    case .testnet: return "Testnet"
    case .local: return "Local"
    @unknown default:
      fatalError("no env define environmentName()")
    }
  }
  
  private func environmentURL(_ env: HeliqEnvironment) -> String {
    switch env {
    case .mainnet: return Constants.API.mainnetBaseURL
    case .testnet: return Constants.API.testnetBaseURL
    case .local: return Constants.API.localBaseURL
    @unknown default:
      fatalError("no env define environmentURL()")
    }
  }
  
  private func initializeSDK() async {
    isInitializing = true
    errorMessage = nil
    
    do {
      try await sdkManager.initialize(with: selectedEnvironment)
      await MainActor.run {
        isInitializing = false
        showInitSuccess = true
      }
    } catch {
      await MainActor.run {
        isInitializing = false
        errorMessage = (error as? any HeliqError)?.errorDescription ?? error.localizedDescription
      }
    }
  }
}
