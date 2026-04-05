//
//  MultiSigEnvelope.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct MultiSigEnvelope: Sendable, Codable {
  public let threshold: Int
  public let signers: [String]
  public let destination: String
  public let value: String
  public let data: String?
  
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
