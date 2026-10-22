//
//  MultiSigEnvelope.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for multi sig envelope.
public struct MultiSigEnvelope: Sendable, Codable {
  /// The threshold associated with this value.
  public let threshold: Int
  /// The signers associated with this value.
  public let signers: [String]
  /// The destination associated with this value.
  public let destination: String
  /// The value associated with this value.
  public let value: String
  /// The data associated with this value.
  public let data: String?
  
  /// Creates an instance with the supplied values.
  public init(
    threshold: Int,
    signers: [String],
    destination: String,
    value: String,
    data: String? = nil
  ) {
    self.threshold = threshold
    self.signers = signers
    self.destination = destination
    self.value = value
    self.data = data
  }
}
