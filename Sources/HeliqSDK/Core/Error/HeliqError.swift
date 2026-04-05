//
//  HeliqError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public protocol HeliqError: Error, Sendable {
  var isRetryable: Bool { get }
  var errorCode: String { get }
  var errorDescription: String { get }
}

public extension HeliqError {
  var isRetryable: Bool {
    false
  }
}
