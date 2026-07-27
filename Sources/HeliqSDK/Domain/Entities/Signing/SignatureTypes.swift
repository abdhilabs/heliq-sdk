//
//  SignatureTypes.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a set of supported values for signature type.
public enum SignatureType: Sendable, Codable {
  /// The `eoa` case.
  case eoa
  /// The `contract` case.
  case contract
}

/// Represents a value for signature types.
public struct SignatureTypes: Sendable, Codable {
  /// The r associated with this value.
  public let r: String
  /// The s associated with this value.
  public let s: String
  /// The v associated with this value.
  public let v: Int
  /// The signature type associated with this value.
  public let signatureType: SignatureType
  
  /// Creates an instance with the supplied values.
  public init(r: String, s: String, v: Int, signatureType: SignatureType) {
    self.r = r
    self.s = s
    self.v = v
    self.signatureType = signatureType
  }
}
