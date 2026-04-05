//
//  ValidationError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum ValidationError: HeliqError, Sendable {
  case missingRequiredField(field: String)
  case invalidFieldFormat(field: String, expected: String)
  case typeMismatch(expected: String, actual: String)
  case outOfRange(field: String, min: Double?, max: Double?)
  case invalidEnumValue(type: String, value: String)
  case malformedData(reason: String)
  
  public var errorCode: String {
    switch self {
    case .missingRequiredField:
      return "VALIDATION_MISSING_FIELD"
    case .invalidFieldFormat:
      return "VALIDATION_INVALID_FORMAT"
    case .typeMismatch:
      return "VALIDATION_TYPE_MISMATCH"
    case .outOfRange:
      return "VALIDATION_OUT_OF_RANGE"
    case .invalidEnumValue:
      return "VALIDATION_INVALID_ENUM"
    case .malformedData:
      return "VALIDATION_MALFORMED_DATA"
    }
  }
  
  public var errorDescription: String {
    switch self {
    case .missingRequiredField(let field):
      return "Missing required field: \(field)"
    case .invalidFieldFormat(let field, let expected):
      return "Invalid format for field '\(field)'. Expected: \(expected)"
    case .typeMismatch(let expected, let actual):
      return "Type mismatch. Expected: \(expected), Actual: \(actual)"
    case .outOfRange(let field, let min, let max):
      var range = ""
      if let min = min, let max = max {
        range = "between \(min) and \(max)"
      } else if let min = min {
        range = ">= \(min)"
      } else if let max = max {
        range = "<= \(max)"
      }
      return "Field '\(field)' is out of range \(range)"
    case .invalidEnumValue(let type, let value):
      return "Invalid value '\(value)' for enum type '\(type)'"
    case .malformedData(let reason):
      return "Malformed data: \(reason)"
    }
  }
  
  public var isRetryable: Bool {
    false
  }
}
