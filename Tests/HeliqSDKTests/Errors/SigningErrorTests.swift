//
//  SigningErrorTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct SigningErrorTests {
  @Test func testInvalidPrivateKey_returnsCorrectCode() throws {
    let error = SigningError.invalidPrivateKey
    
    #expect(error.errorCode == "SIGNING_INVALID_KEY")
    #expect(error.errorDescription == "Invalid private key")
    #expect(error.isRetryable == false)
  }
  
  @Test func testInvalidSignature_returnsCorrectCode() throws {
    let error = SigningError.invalidSignature
    
    #expect(error.errorCode == "SIGNING_INVALID_SIGNATURE")
    #expect(error.errorDescription == "Invalid signature format")
    #expect(error.isRetryable == false)
  }
  
  @Test func testSignatureVerificationFailed_returnsCorrectCode() throws {
    let error = SigningError.signatureVerificationFailed
    
    #expect(error.errorCode == "SIGNING_VERIFICATION_FAILED")
    #expect(error.errorDescription == "Signature verification failed")
    #expect(error.isRetryable == false)
  }
  
  @Test func testSigningFailed_withReason_includesReasonInDescription() throws {
    let error = SigningError.signingFailed(reason: "User cancelled")
    
    #expect(error.errorCode == "SIGNING_FAILED")
    #expect(error.errorDescription == "Signing failed: User cancelled")
    #expect(error.isRetryable == false)
  }
  
  @Test func testUserRejected_isRetryableFalse() throws {
    let error = SigningError.userRejected
    
    #expect(error.errorCode == "SIGNING_USER_REJECTED")
    #expect(error.errorDescription == "User rejected the signing request")
    #expect(error.isRetryable == false)
  }
  
  @Test func testKeyNotFound_returnsCorrectCode() throws {
    let error = SigningError.keyNotFound
    
    #expect(error.errorCode == "SIGNING_KEY_NOT_FOUND")
    #expect(error.errorDescription == "Signing key not found")
    #expect(error.isRetryable == false)
  }
  
  @Test func testUnsupportedSignatureType_returnsCorrectCode() throws {
    let error = SigningError.unsupportedSignatureType
    
    #expect(error.errorCode == "SIGNING_UNSUPPORTED_TYPE")
    #expect(error.errorDescription == "Unsupported signature type")
    #expect(error.isRetryable == false)
  }
}
