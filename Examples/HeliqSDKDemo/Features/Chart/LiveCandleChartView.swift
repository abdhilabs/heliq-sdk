//
//  LiveCandleChartView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 17/10/26.
//

import SwiftUI

/// Demonstrates the same historical and live candle flow without an order ticket.
struct LiveCandleChartView: View {
  @State private var dex = ""
  @State private var coin = "BTC"
  @State private var choosingMarket = false

  var body: some View {
    List {
      Section {
        DemoStatus()
        Button { choosingMarket = true } label: {
          LabeledContent("Market", value: coin)
        }.accessibilityIdentifier("chart_market")
        Text(dex.isEmpty ? "Validator Perps" : dex).font(.caption).foregroundStyle(.secondary)
      }
      Section { StreamingCandleChartView(coin: coin) }
      Section("How this example works") {
        Text(
          "A typed candle snapshot seeds the chart. The SDK WebSocket stream updates "
          + "the current candle or adds a new bar. Leaving this screen stops its subscription.")
      }
    }
    .navigationTitle("Live candle chart").navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $choosingMarket) {
      NavigationStack { PerpsMarketPicker(dex: $dex, coin: $coin) }
    }
  }
}
