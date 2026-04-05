//
//  NetworkErrorTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct NetworkErrorTests {
  @Test func testConnectivityLost_isRetryableTrue() throws {
    let error = NetworkError.connectivityLost
    
    #expect(error.isRetryable == true)
    #expect(error.errorCode == "NETWORK_CONNECTIVITY_LOST")
    #expect(error.errorDescription == "Network connectivity was lost")
  }
  
  @Test func testTimeout_isRetryableTrue() throws {
    let error = NetworkError.timeout
    
    #expect(error.isRetryable == true)
    #expect(error.errorCode == "NETWORK_TIMEOUT")
    #expect(error.errorDescription == "Request timed out")
  }
  
  @Test func testDNSResolutionFailed_isRetryableFalse() throws {
    let error = NetworkError.dnsResolutionFailed
    
    #expect(error.isRetryable == false)
    #expect(error.errorCode == "NETWORK_DNS_FAILED")
    #expect(error.errorDescription == "DNS resolution failed")
  }
  
  @Test func testConnectionRefused_isRetryableFalse() throws {
    let error = NetworkError.connectionRefused
    
    #expect(error.isRetryable == false)
    #expect(error.errorCode == "NETWORK_CONNECTION_REFUSED")
    #expect(error.errorDescription == "Connection refused")
  }
  
  @Test func testNetworkUnavailable_isRetryableTrue() throws {
    let error = NetworkError.networkUnavailable
    
    #expect(error.isRetryable == true)
    #expect(error.errorCode == "NETWORK_UNAVAILABLE")
    #expect(error.errorDescription == "Network is unavailable")
  }
  
  @Test func testInvalidResponse_isRetryableTrue() throws {
    let error = NetworkError.invalidResponse
    
    #expect(error.isRetryable == true)
    #expect(error.errorCode == "NETWORK_INVALID_RESPONSE")
    #expect(error.errorDescription == "Invalid response from server")
  }
  
  @Test func testUnknown_withUnderlyingError_isRetryableTrue() throws {
    let underlyingError = NSError(domain: "Test", code: 1, userInfo: nil)
    let error = NetworkError.unknown(underlying: underlyingError)
    
    #expect(error.isRetryable == true)
    #expect(error.errorCode == "NETWORK_UNKNOWN")
    #expect(error.errorDescription.contains("Unknown network error:") == true)
  }
  
  @Test func testUnknown_withoutUnderlyingError_isRetryableTrue() throws {
    let error = NetworkError.unknown(underlying: nil)
    
    #expect(error.isRetryable == true)
    #expect(error.errorDescription == "Unknown network error")
  }
}
