//
//  SignatureTypes.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum SignatureType: Sendable, Codable {
  case eoa
  case contract
}

public struct SignatureTypes: Sendable, Codable {
  public let r: String
  public let s: String
  public let v: Int
  public let signatureType: SignatureType
  
  public init(r: String, s: String, v: Int, signatureType: SignatureType) {
    self.r = r
    self.s = s
    self.v = v
    self.signatureType = signatureType
  }
}
