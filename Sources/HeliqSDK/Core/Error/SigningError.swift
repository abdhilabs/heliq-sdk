//
//  SigningError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum SigningError: HeliqError, Sendable {
  case invalidPrivateKey
  case invalidSignature
  case signatureVerificationFailed
  case signingFailed(reason: String)
  case userRejected
  case keyNotFound
  case unsupportedSignatureType
  
  public var errorCode: String {
    switch self {
    case .invalidPrivateKey:
      return "SIGNING_INVALID_KEY"
    case .invalidSignature:
      return "SIGNING_INVALID_SIGNATURE"
    case .signatureVerificationFailed:
      return "SIGNING_VERIFICATION_FAILED"
    case .signingFailed:
      return "SIGNING_FAILED"
    case .userRejected:
      return "SIGNING_USER_REJECTED"
    case .keyNotFound:
      return "SIGNING_KEY_NOT_FOUND"
    case .unsupportedSignatureType:
      return "SIGNING_UNSUPPORTED_TYPE"
    }
  }
  
  public var errorDescription: String {
    switch self {
    case .invalidPrivateKey:
      return "Invalid private key"
    case .invalidSignature:
      return "Invalid signature format"
    case .signatureVerificationFailed:
      return "Signature verification failed"
    case .signingFailed(let reason):
      return "Signing failed: \(reason)"
    case .userRejected:
      return "User rejected the signing request"
    case .keyNotFound:
      return "Signing key not found"
    case .unsupportedSignatureType:
      return "Unsupported signature type"
    }
  }
  
  public var isRetryable: Bool {
    switch self {
    case .userRejected:
      return false
    default:
      return false
    }
  }
}
