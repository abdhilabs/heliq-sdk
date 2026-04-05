//
//  APIErrorTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct APIErrorTests {
  @Test func testRateLimited_withRetryAfter_returnsCorrectDescription() throws {
    let error = APIError.rateLimited(retryAfter: 30.0)
    
    #expect(error.errorDescription == "Rate limited. Retry after 30.0 seconds")
    #expect(error.isRetryable == true)
    #expect(error.errorCode == "API_RATE_LIMITED")
  }
  
  @Test func testRateLimited_withoutRetryAfter_returnsCorrectDescription() throws {
    let error = APIError.rateLimited(retryAfter: nil)
    
    #expect(error.errorDescription == "Rate limited")
    #expect(error.isRetryable == true)
  }
  
  @Test func testServerError_withStatusCode_returnsCorrectCode() throws {
    let error = APIError.serverError(statusCode: 500)
    
    #expect(error.errorCode == "API_SERVER_ERROR_500")
    #expect(error.errorDescription == "Server error with status code: 500")
    #expect(error.isRetryable == true)
  }
  
  @Test func testClientError_withMessage_returnsCorrectDescription() throws {
    let error = APIError.clientError(statusCode: 400, message: "Bad request")
    
    #expect(error.errorCode == "API_CLIENT_ERROR_400")
    #expect(error.errorDescription == "Client error (400): Bad request")
    #expect(error.isRetryable == false)
  }
  
  @Test func testClientError_withoutMessage_returnsCorrectDescription() throws {
    let error = APIError.clientError(statusCode: 401, message: nil)
    
    #expect(error.errorDescription == "Client error with status code: 401")
  }
  
  @Test func testInvalidResponse_returnsRetryableTrue() throws {
    let error = APIError.invalidResponse
    
    #expect(error.isRetryable == true)
    #expect(error.errorCode == "API_INVALID_RESPONSE")
  }
  
  @Test func testDecodingFailed_withUnderlyingError_returnsNonRetryable() throws {
    let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)
    let error = APIError.decodingFailed(underlying: underlyingError)
    
    #expect(error.isRetryable == false)
    #expect(error.errorDescription.contains("Failed to decode response:") == true)
  }
  
  @Test func testDecodingFailed_withoutUnderlyingError_returnsNonRetryable() throws {
    let error = APIError.decodingFailed(underlying: nil)
    
    #expect(error.isRetryable == false)
    #expect(error.errorDescription == "Failed to decode response")
  }
  
  @Test func testHyperliquidError_returnsCorrectCodeAndMessage() throws {
    let error = APIError.hyperliquidError(code: 1001, message: "Invalid operation")
    
    #expect(error.errorCode == "API_HYPERLIQUID_ERROR_1001")
    #expect(error.errorDescription == "Hyperliquid API error (1001): Invalid operation")
    #expect(error.isRetryable == false)
  }
}
