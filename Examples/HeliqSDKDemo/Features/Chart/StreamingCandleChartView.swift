//
//  StreamingCandleChartView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 17/10/26.
//

import HeliqSDK
import LightweightCharts
import SwiftUI

private typealias TradingViewLayout = LayoutOptions

/// Shared read-only market chart, scoped to its current connection, coin, and interval.
struct StreamingCandleChartView: View {
  let coin: String
  @Environment(\.dynamicTypeSize) private var textSize
  @Environment(\.verticalSizeClass) private var verticalSize
  @State private var interval: PerpsCandleInterval = .minute
  @StateObject private var model = CandleChartModel()
  @ObservedObject private var sdkManager = SDKManager.shared
  @State private var revision = 0
  @State private var rendered = false
  @State private var renderError: String?
  private var key: String {
    let identity = String(describing: sdkManager.client.map(ObjectIdentifier.init))
    return "\(identity)|\(coin)|\(interval)|\(revision)"
  }

  private var license: String {
    guard let url = Bundle.main.url(forResource: "TradingView-LICENSE", withExtension: "txt"),
      let text = try? String(contentsOf: url, encoding: .utf8)
    else { return "Apache License 2.0: https://www.apache.org/licenses/LICENSE-2.0" }
    return text
  }

  private var statusLayout: AnyLayout {
    textSize.isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4)) : AnyLayout(HStackLayout())
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("Price & volume").font(.headline)
        Spacer()
        Button { revision += 1 } label: {
          Image(systemName: "arrow.clockwise").frame(minWidth: 44, minHeight: 44)
        }.buttonStyle(.borderless)
          .accessibilityLabel("Reload chart").accessibilityIdentifier("chart_reload")
      }
      Picker("Candle interval", selection: $interval) {
        ForEach([PerpsCandleInterval.minute, .fifteenMinutes, .hour, .day], id: \.self) {
          Text($0.rawValue).tag($0)
        }
      }.pickerStyle(.segmented).accessibilityIdentifier("chart_interval")
      Label(
        "\(coin) · \(interval.rawValue) · \(model.status)",
        systemImage: model.lastUpdate == nil ? "clock" : "waveform.path")
        .font(.caption).accessibilityIdentifier("chart_status")
      if let error = model.error ?? renderError {
        DemoFeedback(error: error, prefix: "chart")
      }
      CandleChartCanvas(
        candles: model.buffer.candles, rendered: $rendered, error: $renderError)
        .id(key).frame(height: verticalSize == .compact ? 180 : 300).accessibilityIdentifier("candle_chart")
        .accessibilityLabel("Candlestick and volume chart for \(coin)")
        .accessibilityHint("Drag to pan and pinch to zoom. The latest candle summary follows.")
        .overlay {
          if model.buffer.candles.isEmpty {
            if model.buffer.isReady {
              Text("No candles for this market").padding().background(.background)
                .accessibilityIdentifier("chart_empty")
            } else if model.error == nil {
              ProgressView("Loading candles…").padding().background(.background)
            }
          }
        }
      if let last = model.buffer.candles.last {
        Text(verbatim: "O \(last.o) · H \(last.h) · L \(last.l) · C \(last.c) · Vol \(last.v) \(coin)")
          .font(.caption).monospacedDigit().textSelection(.enabled)
          .accessibilityLabel("Latest candle in USD, volume in \(coin)")
          .accessibilityValue(Text(verbatim:
            "Open \(last.o), high \(last.h), low \(last.l), "
            + "close \(last.c), volume \(last.v)"))
          .accessibilityIdentifier("chart_ohlcv")
      }
      statusLayout {
        Text("\(model.buffer.candles.count) bars").accessibilityIdentifier("chart_bar_count")
        Text("\(model.updateCount) stream updates").accessibilityIdentifier("chart_update_count")
        if rendered { Text("Chart ready").accessibilityIdentifier("chart_ready") }
      }.font(.caption2).foregroundStyle(.secondary)
      if let date = model.lastUpdate {
        Text("Last stream update: \(date.formatted(date: .omitted, time: .standard))")
          .font(.caption).foregroundStyle(.secondary)
      }
      Text("TradingView Lightweight Charts™ · Copyright © 2026 TradingView, Inc.")
        .font(.caption2).foregroundStyle(.secondary)
      Link("Charts by TradingView", destination: URL(string: "https://www.tradingview.com/")!)
        .font(.caption).frame(minHeight: 44).buttonStyle(.borderless)
      DisclosureGroup("Chart open-source license") {
        ScrollView {
          Text(license).font(.caption).textSelection(.enabled)
        }.frame(maxHeight: 180)
      }.font(.caption)
    }
    .onChange(of: key) { _ in rendered = false; renderError = nil }
    .task(id: key) {
      renderError = nil
      await model.run(coin: coin, interval: interval, client: sdkManager.client)
    }
  }
}

/// Embeds the bundled TradingView canvas; only display values become floating point.
private struct CandleChartCanvas: UIViewRepresentable {
  let candles: [PerpsCandle]
  @Binding var rendered: Bool
  @Binding var error: String?
  @Environment(\.colorScheme) private var scheme

  /// Keeps series and rendering state stable across SwiftUI value updates.
  func makeCoordinator() -> Coordinator { Coordinator(rendered: $rendered, error: $error) }

  /// Builds candle and volume panes with native touch navigation and the attribution logo.
  func makeUIView(context: Context) -> LightweightCharts {
    let chart = LightweightCharts()
    chart.loadDelegate = context.coordinator
    chart.errorDelegate = context.coordinator
    context.coordinator.prices = chart.addCandlestickSeries(options: nil)
    context.coordinator.volume = chart.addHistogramSeries(
      options: HistogramSeriesOptions(
        priceFormat: .builtIn(.init(type: .volume, precision: 8, minMove: 0.00000001))),
      paneIndex: 1)
    return chart
  }

  /// Applies appearance and updates the current bar incrementally whenever possible.
  func updateUIView(_ chart: LightweightCharts, context: Context) {
    var options = ChartOptions()
    options.layout = TradingViewLayout(
      background: .solid(scheme == .dark ? "#1c1c1e" : "#ffffff"),
      textColor: ChartColor(scheme == .dark ? UIColor.white : UIColor.black), attributionLogo: true)
    let grid = GridLineOptions(color: ChartColor(hex: scheme == .dark ? 0x38383a : 0xe5e5ea))
    options.grid = GridOptions(verticalLines: grid, horizontalLines: grid)
    options.timeScale = TimeScaleOptions(timeVisible: true, secondsVisible: false)
    chart.applyOptions(options: options)
    context.coordinator.render(candles, chart: chart)
  }

  /// Constrains the web view to the list's proposal, including compact landscape layouts.
  func sizeThatFits(
    _ proposal: ProposedViewSize, uiView: LightweightCharts, context: Context
  ) -> CGSize? {
    let width = proposal.width ?? 300
    let height = proposal.height ?? 300
    return CGSize(
      width: width.isFinite ? max(1, width) : 300,
      height: height.isFinite ? max(1, height) : 300)
  }

  /// Releases the web renderer when navigation or market selection replaces this chart.
  static func dismantleUIView(_ chart: LightweightCharts, coordinator: Coordinator) {
    chart.loadDelegate = nil
    chart.errorDelegate = nil
    chart.remove()
  }

  @MainActor final class Coordinator: NSObject, LightweightChartsDelegate, JavaScriptErrorDelegate {
    var prices: CandlestickSeries?
    var volume: HistogramSeries?
    private var previous: [CandlestickData] = []
    private var previousVolume: [HistogramData] = []
    private var pricePrecision: Int?
    private var rendered: Binding<Bool>
    private var error: Binding<String?>

    /// Retains bindings without retaining the SwiftUI view or its stream model.
    init(rendered: Binding<Bool>, error: Binding<String?>) {
      self.rendered = rendered
      self.error = error
    }

    /// Updates the latest bar, or replaces sorted history for backfill and older corrections.
    func render(_ values: [PerpsCandle], chart: LightweightCharts) {
      let data = values.map {
        CandlestickData(
          time: .utc(timestamp: Double($0.t) / 1_000),
          open: NSDecimalNumber(decimal: $0.o).doubleValue,
          high: NSDecimalNumber(decimal: $0.h).doubleValue,
          low: NSDecimalNumber(decimal: $0.l).doubleValue,
          close: NSDecimalNumber(decimal: $0.c).doubleValue)
      }
      let volumes = values.map {
        HistogramData(
          time: .utc(timestamp: Double($0.t) / 1_000),
          value: NSDecimalNumber(decimal: $0.v).doubleValue,
          color: ChartColor($0.c >= $0.o ? .systemGreen : .systemRed))
      }
      guard data != previous || volumes != previousVolume else { return }
      if let lowest = data.compactMap(\.low).min(), lowest > 0 {
        let precision = max(0, min(8, 5 - Int(floor(log10(lowest)))))
        if pricePrecision != precision {
          prices?.applyOptions(options: CandlestickSeriesOptions(
            priceFormat: .builtIn(.init(
              type: .price, precision: Double(precision), minMove: pow(10, -Double(precision))))))
          pricePrecision = precision
        }
      }
      let incremental = !previous.isEmpty && (
        data.count == previous.count && Array(data.dropLast()) == Array(previous.dropLast())
        || data.count == previous.count + 1 && Array(data.dropLast()) == previous)
        && (Array(volumes.dropLast()) == Array(previousVolume.dropLast())
          || Array(volumes.dropLast()) == previousVolume)
      if incremental, let last = data.last, let lastVolume = volumes.last {
        prices?.update(bar: last)
        volume?.update(bar: lastVolume)
      } else {
        prices?.setData(data: data)
        volume?.setData(data: volumes)
      }
      if previous.isEmpty && !data.isEmpty { chart.timeScale().fitContent() }
      previous = data
      previousVolume = volumes
    }

    /// Exposes successful renderer bootstrap for UI verification.
    func lightweightChartsDidLoad(_ lightweightCharts: LightweightCharts) {
      rendered.wrappedValue = true
    }

    /// Shows renderer bootstrap failures beside the chart instead of leaving a silent blank view.
    func lightweightCharts(_ lightweightCharts: LightweightCharts, didFailLoadWithError error: Error) {
      self.error.wrappedValue = error.localizedDescription
    }

    /// Reports bridge errors without logging script contents or wallet-related data.
    func didFailEvaluateScript(_ script: String, withError error: Error) {
      self.error.wrappedValue = error.localizedDescription
    }
  }
}
