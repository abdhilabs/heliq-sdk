//
//  DemoComponents.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 15/10/26.
//

import HeliqSDK
import SwiftUI
import UIKit

struct DemoStatus: View {
  @ObservedObject var manager = SDKManager.shared
  var body: some View {
    Label(
      manager.isInitialized
        ? "Connected · \(String(describing: manager.currentEnvironment).capitalized)"
        : "Disconnected",
      systemImage: manager.isInitialized ? "checkmark.circle" : "circle.dashed"
    )
    .font(.caption).foregroundStyle(.secondary)
    .accessibilityIdentifier("demo_connection_status")
  }
}

struct DemoEmptyState: View {
  let title: String
  let message: String
  var symbol = "tray"
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Label(title, systemImage: symbol).font(.headline)
      Text(message).font(.subheadline).foregroundStyle(.secondary)
    }.padding(.vertical, 12).frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct DemoFeedback: View {
  var result: String?
  var error: String?
  var prefix: String
  var body: some View {
    if let result {
      Label(result, systemImage: "info.circle")
        .font(.subheadline).textSelection(.enabled).accessibilityIdentifier(prefix + "_result")
    }
    if let error {
      Label(error, systemImage: "exclamationmark.circle")
        .font(.subheadline).foregroundStyle(.red).textSelection(.enabled)
        .accessibilityIdentifier(prefix + "_error")
    }
  }
}

struct DemoAmountRow: View {
  let title: String
  let value: Decimal?
  var unit = ""
  var body: some View {
    LabeledContent(title) {
      Text(value.map { $0.description + (unit.isEmpty ? "" : " " + unit) } ?? "Unavailable")
        .monospacedDigit().multilineTextAlignment(.trailing)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(title)
    .accessibilityValue(
      value.map { $0.description + (unit.isEmpty ? "" : " " + unit) } ?? "Unavailable"
    )
    .accessibilityIdentifier("amount_" + title)
  }
}

struct DemoDecimalField: View {
  let title: String
  @Binding var text: String
  var unit = ""
  var identifier = ""
  var signed = false
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title + (unit.isEmpty ? "" : " (\(unit))")).font(.subheadline)
      TextField("0", text: $text).keyboardType(signed ? .numbersAndPunctuation : .decimalPad)
        .textInputAutocapitalization(.never).autocorrectionDisabled()
        .monospacedDigit().accessibilityLabel(title).accessibilityIdentifier(identifier)
        .frame(minHeight: 44).padding(.vertical, 6)
    }
  }
}

extension View {
  /// Adds consistent keyboard dismissal to demo forms without changing their requests.
  func demoForm() -> some View {
    self.scrollDismissesKeyboard(.interactively)
      .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
          Button("Done") {
            UIApplication.shared.sendAction(
              #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
          }.accessibilityIdentifier("dismiss_keyboard")
        }
      }
  }
}

struct DemoTextField: View {
  let title: String
  @Binding var text: String
  /// Creates a persistently labeled input for an SDK example parameter.
  init(_ title: String, text: Binding<String>) {
    self.title = title
    _text = text
  }
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title).font(.subheadline).foregroundStyle(.secondary)
      TextField(title, text: $text).frame(minHeight: 44).padding(.vertical, 4).accessibilityLabel(
        title)
    }
  }
}

extension Error {
  /// Preserves actionable SDK error details instead of an opaque NSError description.
  var demoDescription: String {
    if let sdkError = self as? any HeliqError { return sdkError.errorDescription }
    return localizedDescription
  }
}
