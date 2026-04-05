//
//  CandleChartView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI
import HeliqSDK

struct CandleChartView: View {
  let candles: [Candle]
  let coin: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Candlestick - \(coin)")
        .font(.headline)
        .padding(.horizontal)
      
      if candles.isEmpty {
        Text("No candle data available")
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(alignment: .bottom, spacing: 4) {
            ForEach(candles) { candle in
              CandleBar(candle: candle)
            }
          }
          .padding(.horizontal)
        }
        .frame(height: 200)
        
        VStack(alignment: .leading, spacing: 4) {
          if let latest = candles.last {
            HStack {
              Text("Latest: \(String(format: "%.2f", latest.close))")
              Spacer()
              Text(formatDate(latest.timestamp))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
          }
        }
        .padding(.horizontal)
      }
    }
  }
  
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: date)
  }
}

struct CandleBar: View {
  let candle: Candle
  
  private var isGreen: Bool {
    candle.close >= candle.open
  }
  
  var body: some View {
    let maxPrice = candle.high
    let minPrice = candle.low
    let open = candle.open
    let close = candle.close
    
    let range = maxPrice - minPrice
    let scale: CGFloat = range > 0 ? 150 / CGFloat(range) : 1
    
    GeometryReader { geometry in
      let height = CGFloat(abs(close - open)) * scale
      let width: CGFloat = 8
      let wickTop = CGFloat(maxPrice - max(open, close)) * scale
      let wickBottom = CGFloat(min(open, close) - minPrice) * scale
      
      VStack(spacing: 0) {
        Rectangle()
          .fill(isGreen ? .green : .red)
          .frame(width: 2, height: max(1, wickTop))
        
        Rectangle()
          .fill(isGreen ? .green : .red)
          .frame(width: width, height: max(2, height))
        
        Rectangle()
          .fill(isGreen ? .green : .red)
          .frame(width: 2, height: max(1, wickBottom))
      }
    }
  }
}
