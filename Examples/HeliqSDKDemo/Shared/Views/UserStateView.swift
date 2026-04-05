//
//  UserStateView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI
import HeliqSDK

struct UserStateView: View {
  let userState: UserState
  
  var body: some View {
    List {
      Section("Account Info") {
        LabeledContent("Address", value: userState.accountAddress)
        LabeledContent("Margin Mode", value: userState.marginMode.rawValue.capitalized)
        LabeledContent("Leverage", value: "\(userState.leverage)x")
      }
      
      Section("Margin") {
        LabeledContent("Used", value: String(format: "%.2f", userState.marginUsed))
        LabeledContent("Total", value: String(format: "%.2f", userState.marginTotal))
      }
      
      Section("Positions (\(userState.assetPositions.count))") {
        if userState.assetPositions.isEmpty {
          Text("No open positions")
            .foregroundStyle(.secondary)
        } else {
          ForEach(userState.assetPositions, id: \.asset) { position in
            PositionRow(position: position)
          }
        }
      }
    }
  }
}

struct PositionRow: View {
  let position: AssetPosition
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text("Asset #\(position.asset)")
          .font(.headline)
        Spacer()
        Text(position.positionSize > 0 ? "Long" : "Short")
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 2)
          .background(position.positionSize > 0 ? .green.opacity(0.2) : .red.opacity(0.2))
          .clipShape(Capsule())
      }
      
      HStack {
        VStack(alignment: .leading) {
          Text("Size")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(String(format: "%.4f", abs(position.positionSize)))
            .font(.subheadline)
        }
        
        Spacer()
        
        VStack(alignment: .center) {
          Text("Entry")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(String(format: "%.2f", position.entryPrice))
            .font(.subheadline)
        }
        
        Spacer()
        
        VStack(alignment: .trailing) {
          Text("PnL")
            .font(.caption)
            .foregroundStyle(.secondary)
          Text(String(format: "%.2f", position.unrealizedPnl))
            .font(.subheadline)
            .foregroundStyle(position.unrealizedPnl >= 0 ? .green : .red)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

struct SpotUserStateView: View {
  let spotState: SpotUserState
  
  var body: some View {
    List {
      Section("Account Info") {
        LabeledContent("Address", value: spotState.accountAddress)
        LabeledContent("Total USDC", value: String(format: "%.2f", spotState.totalUsdc))
      }
      
      Section("Spot Positions (\(spotState.spotPositions.count))") {
        if spotState.spotPositions.isEmpty {
          Text("No spot positions")
            .foregroundStyle(.secondary)
        } else {
          ForEach(spotState.spotPositions, id: \.asset) { position in
            SpotPositionRow(position: position)
          }
        }
      }
    }
  }
}

struct SpotPositionRow: View {
  let position: SpotPosition
  
  var body: some View {
    HStack {
      Text("Asset #\(position.asset)")
        .font(.headline)
      Spacer()
      Text(String(format: "%.4f", position.totalSize))
        .font(.subheadline)
      if position.hold > 0 {
        Text("Hold: \(String(format: "%.4f", position.hold))")
          .font(.caption)
          .foregroundStyle(.orange)
      }
    }
  }
}
