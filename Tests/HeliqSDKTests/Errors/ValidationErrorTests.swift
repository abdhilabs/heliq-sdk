//
//  ValidationErrorTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct ValidationErrorTests {
  @Test func testMissingRequiredField_includesFieldNameInDescription() throws {
    let error = ValidationError.missingRequiredField(field: "orderId")
    
    #expect(error.errorCode == "VALIDATION_MISSING_FIELD")
    #expect(error.errorDescription == "Missing required field: orderId")
    #expect(error.isRetryable == false)
  }
  
  @Test func testInvalidFieldFormat_includesFieldAndExpectedInDescription() throws {
    let error = ValidationError.invalidFieldFormat(field: "email", expected: "valid email format")
    
    #expect(error.errorCode == "VALIDATION_INVALID_FORMAT")
    #expect(error.errorDescription == "Invalid format for field 'email'. Expected: valid email format")
    #expect(error.isRetryable == false)
  }
  
  @Test func testTypeMismatch_includesExpectedAndActualInDescription() throws {
    let error = ValidationError.typeMismatch(expected: "String", actual: "Int")
    
    #expect(error.errorCode == "VALIDATION_TYPE_MISMATCH")
    #expect(error.errorDescription == "Type mismatch. Expected: String, Actual: Int")
    #expect(error.isRetryable == false)
  }
  
  @Test func testOutOfRange_withMinOnly_includesMinInDescription() throws {
    let error = ValidationError.outOfRange(field: "price", min: 0.01, max: nil)
    
    #expect(error.errorCode == "VALIDATION_OUT_OF_RANGE")
    #expect(error.errorDescription.contains(">= 0.01") == true)
    #expect(error.isRetryable == false)
  }
  
  @Test func testOutOfRange_withMaxOnly_includesMaxInDescription() throws {
    let error = ValidationError.outOfRange(field: "price", min: nil, max: 1000.0)
    
    #expect(error.errorCode == "VALIDATION_OUT_OF_RANGE")
    #expect(error.errorDescription.contains("<= 1000.0") == true)
    #expect(error.isRetryable == false)
  }
  
  @Test func testOutOfRange_withBothMinAndMax_includesBothInDescription() throws {
    let error = ValidationError.outOfRange(field: "price", min: 0.01, max: 1000.0)
    
    #expect(error.errorCode == "VALIDATION_OUT_OF_RANGE")
    #expect(error.errorDescription.contains("between 0.01 and 1000.0") == true)
    #expect(error.isRetryable == false)
  }
  
  @Test func testMalformedData_withReason_includesReasonInDescription() throws {
    let error = ValidationError.malformedData(reason: "Invalid JSON structure")
    
    #expect(error.errorCode == "VALIDATION_MALFORMED_DATA")
    #expect(error.errorDescription == "Malformed data: Invalid JSON structure")
    #expect(error.isRetryable == false)
  }
  
  @Test func testInvalidEnumValue_includesTypeAndValueInDescription() throws {
    let error = ValidationError.invalidEnumValue(type: "OrderSide", value: "BUY")
    
    #expect(error.errorCode == "VALIDATION_INVALID_ENUM")
    #expect(error.errorDescription == "Invalid value 'BUY' for enum type 'OrderSide'")
    #expect(error.isRetryable == false)
  }
}
