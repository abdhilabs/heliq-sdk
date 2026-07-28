//
//  WebSocketView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI
import HeliqSDK
import Combine

struct WebSocketView: View {
  @State private var connectionState: WSConnectionState = .disconnected
  @State private var activeSubscriptions: [SubscriptionChannel] = []
  @State private var messages: [WSMessage] = []
  @State private var selectedChannel: SubscriptionChannel = .allMids
  @State private var customCoin = "BTC"
  @State private var candleInterval = "1m"
  @State private var isSubscribed = false
  
  @StateObject private var webSocketManager = WebSocketManager()
  
  private let maxMessages = 100
  
  enum WSConnectionState: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting..."
    case connected = "Connected"
    case reconnecting = "Reconnecting..."
  }
  
  var body: some View {
    List {
      Section("Connection") {
        HStack {
          Circle()
            .fill(connectionColor)
            .frame(width: 12, height: 12)
          Text(connectionState.rawValue)
            .font(.headline)
          Spacer()
          if connectionState == .disconnected {
            Button("Connect") {
              connect()
            }
            .buttonStyle(.bordered)
          } else if connectionState == .connected {
            Button("Disconnect") {
              disconnect()
            }
            .buttonStyle(.bordered)
            .tint(.red)
          } else {
            ProgressView()
          }
        }
      }
      
      Section("Subscribe") {
        Picker("Channel", selection: $selectedChannel) {
          ForEach(availableChannels, id: \.self) { channel in
            Text(channel.channelName).tag(channel)
          }
        }
        .pickerStyle(.menu)
        
        if selectedChannel.requiresCoin {
          TextField("Coin", text: $customCoin)
            .textInputAutocapitalization(.characters)
        }
        
        if case .candle = selectedChannel {
          Picker("Interval", selection: $candleInterval) {
            Text("1m").tag("1m")
            Text("15m").tag("15m")
            Text("1h").tag("1h")
            Text("1d").tag("1d")
          }
          .pickerStyle(.segmented)
        }
        
        Button(isSubscribed ? "Unsubscribe" : "Subscribe") {
          toggleSubscription()
        }
        .disabled(connectionState != .connected)
      }
      
      Section("Active Subscriptions (\(activeSubscriptions.count))") {
        if activeSubscriptions.isEmpty {
          Text("No active subscriptions")
            .foregroundStyle(.secondary)
        } else {
          ForEach(activeSubscriptions, id: \.self) { channel in
            HStack {
              Text(channel.channelName)
                .font(.headline)
              if let coin = channel.coin {
                Text(coin)
                  .font(.caption)
                  .foregroundStyle(.secondary)
              }
              Spacer()
              Button {
                unsubscribe(channel)
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .foregroundStyle(.red)
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      
      Section("Messages (\(messages.count))") {
        Button("Clear Messages") {
          messages.removeAll()
        }
        .foregroundStyle(.red)
        
        if messages.isEmpty {
          Text("No messages received")
            .foregroundStyle(.secondary)
        } else {
          ForEach(messages.reversed().prefix(20), id: \.id) { message in
            MessageRow(message: message)
          }
        }
      }
    }
    .navigationTitle("WebSocket")
    .onReceive(webSocketManager.$state) { state in
      connectionState = mapState(state)
    }
    .onReceive(webSocketManager.$subscriptions) { subs in
      activeSubscriptions = subs
    }
    .onReceive(webSocketManager.$messages) { newMessages in
      messages.append(contentsOf: newMessages.prefix(maxMessages - messages.count))
    }
  }
  
  private var availableChannels: [SubscriptionChannel] {
    [
      .allMids,
      .l2Book(coin: customCoin),
      .trades(coin: customCoin),
      .candle(coin: customCoin, interval: candleInterval),
      .bbo(coin: customCoin),
      .userEvents,
      .userFills,
      .orderUpdates,
      .userFundings,
      .userNonFundingLedgerUpdates,
      .webData2
    ]
  }
  
  private var connectionColor: Color {
    switch connectionState {
    case .connected: return .green
    case .connecting, .reconnecting: return .yellow
    case .disconnected: return .red
    }
  }
  
  private func connect() {
    connectionState = .connecting
    webSocketManager.connect()
  }
  
  private func disconnect() {
    webSocketManager.disconnect()
  }
  
  private func toggleSubscription() {
    if isSubscribed {
      unsubscribe(selectedChannel)
    } else {
      subscribe()
    }
  }
  
  private func subscribe() {
    let channel: SubscriptionChannel
    switch selectedChannel {
    case .l2Book:
      channel = .l2Book(coin: customCoin.uppercased())
    case .trades:
      channel = .trades(coin: customCoin.uppercased())
    case .candle:
      channel = .candle(coin: customCoin.uppercased(), interval: candleInterval)
    case .bbo:
      channel = .bbo(coin: customCoin.uppercased())
    default:
      channel = selectedChannel
    }
    webSocketManager.subscribe(to: channel)
    isSubscribed = true
  }
  
  private func unsubscribe(_ channel: SubscriptionChannel) {
    webSocketManager.unsubscribe(from: channel)
    if channel == selectedChannel {
      isSubscribed = false
    }
  }
  
  private func mapState(_ state: WebSocketState) -> WSConnectionState {
    switch state {
    case .disconnected: return .disconnected
    case .connecting: return .connecting
    case .connected: return .connected
    case .reconnecting: return .reconnecting
    @unknown default:
      fatalError("no env define mapState()")
    }
  }
}

extension SubscriptionChannel {
  var requiresCoin: Bool {
    switch self {
    case .l2Book, .trades, .candle, .bbo, .activeAssetCtx, .activeAssetData:
      return true
    default:
      return false
    }
  }
  
  var coin: String? {
    switch self {
    case .l2Book(let coin), .trades(let coin), .bbo(let coin):
      return coin
    case .candle(let coin, _):
      return coin
    default:
      return nil
    }
  }
}

struct MessageRow: View {
  let message: WSMessage
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(message.channel)
          .font(.caption)
          .fontWeight(.semibold)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(.blue.opacity(0.2))
          .clipShape(Capsule())
        Spacer()
        Text(formatTime(message.timestamp))
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
      Text(message.data)
        .font(.system(.caption2, design: .monospaced))
        .lineLimit(3)
    }
    .padding(.vertical, 2)
  }
  
  private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: date)
  }
}

struct WSMessage: Identifiable {
  let id = UUID()
  let channel: String
  let data: String
  let timestamp: Date
}

@MainActor
class WebSocketManager: ObservableObject, @unchecked Sendable {
  @Published var state: WebSocketState = .disconnected
  @Published var subscriptions: [SubscriptionChannel] = []
  @Published var messages: [WSMessage] = []
  
  private var webSocketService: WebSocketService?
  private let sdkManager = SDKManager.shared
  
  init() {
    setupWebSocket()
  }
  
  private func setupWebSocket() {
    let wsURLString = Constants.WebSocket.url(for: sdkManager.currentEnvironment)
    guard let url = URL(string: wsURLString) else { return }
    
    let service = WebSocketService(url: url) { [weak self] event in
      Task { @MainActor [weak self] in
        self?.handle(event)
      }
    }
    webSocketService = service
  }
  
  func connect() {
    state = .connecting
    Task {
      await webSocketService?.connect()
    }
  }
  
  func disconnect() {
    Task {
      await webSocketService?.disconnect()
    }
    state = .disconnected
    subscriptions.removeAll()
  }
  
  func subscribe(to channel: SubscriptionChannel) {
    guard !subscriptions.contains(channel) else { return }

    Task {
      do {
        try await webSocketService?.subscribe(
          channel: channel.channelName,
          payload: channel.payload
        )
        subscriptions.append(channel)
      } catch {
        state = .disconnected
      }
    }
  }
  
  func unsubscribe(from channel: SubscriptionChannel) {
    guard subscriptions.contains(channel) else { return }

    Task {
      do {
        try await webSocketService?.unsubscribe(
          channel: channel.channelName,
          payload: channel.payload
        )
        subscriptions.removeAll { $0 == channel }
      } catch {
        state = .disconnected
      }
    }
  }
  
  func unsubscribeAll() {
    let channels = subscriptions
    Task {
      for channel in channels {
        try? await webSocketService?.unsubscribe(
          channel: channel.channelName,
          payload: channel.payload
        )
      }
      subscriptions.removeAll()
    }
  }

  private func handle(_ event: WebSocketEvent) {
    switch event {
    case .stateChanged(let webSocketState):
      state = webSocketState
    case .message(let data):
      parseMessage(data)
    case .failed:
      state = .disconnected
    @unknown default:
      state = .disconnected
    }
  }

  private func parseMessage(_ data: Data) {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      return
    }
    
    let channel = json["channel"] as? String ?? "unknown"
    var dataString = ""
    
    if let payload = json["data"] as? [String: Any] {
      if let prettyData = try? JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted),
         let prettyString = String(data: prettyData, encoding: .utf8) {
        dataString = prettyString
      } else {
        dataString = String(describing: payload)
      }
    } else if let dataStr = json["data"] as? String {
      dataString = dataStr
    } else {
      dataString = String(describing: json)
    }
    
    let message = WSMessage(channel: channel, data: dataString, timestamp: Date())
    messages.append(message)
    
    if messages.count > 200 {
      messages.removeFirst(messages.count - 200)
    }
  }
}
