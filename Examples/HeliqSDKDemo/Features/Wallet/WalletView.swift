//
//  WalletView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI
import HeliqSDK

struct WalletView: View {
  @State private var walletAddress = ""
  @State private var messageToSign = "Hello, Hyperliquid!"
  @State private var signatureResult: SignatureTypes?
  @State private var isSigning = false
  @State private var errorMessage: String?
  
  private let sdkManager = SDKManager.shared
  
  var body: some View {
    List {
      Section("Wallet Address") {
        if let address = sdkManager.walletAddress {
          VStack(alignment: .leading, spacing: 8) {
            Text("Connected Wallet")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(address)
              .font(.system(.body, design: .monospaced))
              .textSelection(.enabled)
          }
        } else {
          Text("No wallet connected")
            .foregroundStyle(.secondary)
        }
      }
      
      Section("Wallet Types") {
        VStack(alignment: .leading, spacing: 4) {
          Label("EOA Wallet", systemImage: "key.fill")
            .font(.headline)
          Text("Externally Owned Account - Direct private key control")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        
        VStack(alignment: .leading, spacing: 4) {
          Label("Agent Wallet", systemImage: "person.2.fill")
            .font(.headline)
          Text("Delegated signing through agent service")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        
        VStack(alignment: .leading, spacing: 4) {
          Label("Multi-Sig Wallet", systemImage: "person.3.fill")
            .font(.headline)
          Text("Multi-signature requiring multiple approvals")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
      }
      
      Section("Signing Demo") {
        TextField("Message to Sign", text: $messageToSign)
          .textInputAutocapitalization(.never)
        
        Button {
          Task { await signMessage() }
        } label: {
          HStack {
            if isSigning {
              ProgressView()
                .scaleEffect(0.8)
            }
            Text("Sign Message")
          }
        }
        .disabled(messageToSign.isEmpty || sdkManager.walletAddress == nil)
      }
      
      if let signature = signatureResult {
        Section("Signature Result") {
          VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Type") {
              Text(signature.signatureType == .eoa ? "EOA" : "Contract")
                .font(.system(.body, design: .monospaced))
            }
            
            VStack(alignment: .leading, spacing: 4) {
              Text("r:")
                .font(.caption)
                .foregroundStyle(.secondary)
              Text(signature.r)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
            }
            
            VStack(alignment: .leading, spacing: 4) {
              Text("s:")
                .font(.caption)
                .foregroundStyle(.secondary)
              Text(signature.s)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
            }
            
            LabeledContent("v") {
              Text("\(signature.v)")
                .font(.system(.body, design: .monospaced))
            }
          }
        }
      }
      
      if let error = errorMessage {
        Section("Error") {
          Text(error)
            .foregroundStyle(.red)
        }
      }
      
      Section("Key Manager") {
        VStack(alignment: .leading, spacing: 8) {
          Text("Direct Private Key")
            .font(.headline)
          Text("Create wallet from raw private key")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Button("Create from Private Key") {
            // Demo implementation
          }
          .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
        
        VStack(alignment: .leading, spacing: 8) {
          Text("Keychain Storage")
            .font(.headline)
          Text("Secure wallet using iOS Keychain")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Button("Create from Keychain") {
            // Demo implementation
          }
          .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
        
        VStack(alignment: .leading, spacing: 8) {
          Text("Agent-Based")
            .font(.headline)
          Text("Sign via external agent service")
            .font(.caption)
            .foregroundStyle(.secondary)
          
          Button("Create Agent Wallet") {
            // Demo implementation
          }
          .buttonStyle(.bordered)
        }
        .padding(.vertical, 4)
      }
      
      Section("Security Notes") {
        VStack(alignment: .leading, spacing: 4) {
          Label("Never share your private key", systemImage: "exclamationmark.shield.fill")
            .foregroundStyle(.red)
          Text("Your private key should never leave your device")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        
        VStack(alignment: .leading, spacing: 4) {
          Label("Use testnet for demos", systemImage: "flask.fill")
            .foregroundStyle(.orange)
          Text("Use testnet environment to avoid real fund loss")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Wallet")
  }
  
  private func signMessage() async {
    isSigning = true
    errorMessage = nil
    signatureResult = nil
    
    do {
      let wallet = MockWalletService()
      let signature = try await wallet.sign(message: messageToSign)
      await MainActor.run {
        signatureResult = signature
        isSigning = false
      }
    } catch {
      await MainActor.run {
        errorMessage = error.localizedDescription
        isSigning = false
      }
    }
  }
}
