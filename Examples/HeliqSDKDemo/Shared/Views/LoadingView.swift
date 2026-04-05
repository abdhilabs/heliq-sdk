//
//  LoadingView.swift
//  HeliqSDKDemo
//
//  Created by Abdhilabs on 05/04/26.
//

import SwiftUI

struct LoadingView: View {
  let message: String
  
  init(_ message: String = "Loading...") {
    self.message = message
  }
  
  var body: some View {
    VStack(spacing: 16) {
      ProgressView()
        .progressViewStyle(.circular)
        .scaleEffect(1.2)
      Text(message)
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct ErrorView: View {
  let error: String
  let retryAction: (() -> Void)?
  
  init(error: String, retryAction: (() -> Void)? = nil) {
    self.error = error
    self.retryAction = retryAction
  }
  
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 48))
        .foregroundStyle(.red)
      
      Text("Error")
        .font(.headline)
      
      Text(error)
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
      
      if let retryAction = retryAction {
        Button("Retry") {
          retryAction()
        }
        .buttonStyle(.bordered)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
