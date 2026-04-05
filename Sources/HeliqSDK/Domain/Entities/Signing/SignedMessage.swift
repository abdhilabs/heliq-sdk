//
//  SignedMessage.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct SignedMessage: Sendable, Codable {
  public let message: String
  public let signature: SignatureTypes
  public let signer: String
  
  public init(message: String, signature: SignatureTypes, signer: String) {
    self.message = message
    self.signature = signature
    self.signer = signer
  }
}
