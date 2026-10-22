//
//  SignedMessage.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for signed message.
public struct SignedMessage: Sendable, Codable {
  /// The message associated with this value.
  public let message: String
  /// The signature associated with this value.
  public let signature: SignatureTypes
  /// The signer associated with this value.
  public let signer: String
  
  /// Creates an instance with the supplied values.
  public init(message: String, signature: SignatureTypes, signer: String) {
    self.message = message
    self.signature = signature
    self.signer = signer
  }
}
