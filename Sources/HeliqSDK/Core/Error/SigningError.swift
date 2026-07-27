//
//  SigningError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Describes signing failures returned by the SDK.
public enum SigningError: HeliqError, Sendable {
  /// Private-key material is invalid.
  case invalidPrivateKey
  /// Signature data is invalid.
  case invalidSignature
  /// Signature verification failed.
  case signatureVerificationFailed
  /// Signing failed for the given reason.
  case signingFailed(reason: String)
  /// User rejected the signing request.
  case userRejected
  /// Required signing key was unavailable.
  case keyNotFound
  /// Requested signature format is unsupported.
  case unsupportedSignatureType
  
  /// Stable machine-readable code for this error.
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
  
  /// Human-readable description of this error.
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
  
  /// Whether retrying the failed operation may succeed.
  public var isRetryable: Bool {
    switch self {
    case .userRejected:
      return false
    default:
      return false
    }
  }
}
