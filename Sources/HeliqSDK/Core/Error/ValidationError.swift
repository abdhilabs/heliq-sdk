//
//  ValidationError.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Describes validation failures returned by the SDK.
public enum ValidationError: HeliqError, Sendable {
  /// A required field was absent.
  case missingRequiredField(field: String)
  /// A field did not match its expected format.
  case invalidFieldFormat(field: String, expected: String)
  /// A value had an unexpected type.
  case typeMismatch(expected: String, actual: String)
  /// A numeric field was outside its allowed range.
  case outOfRange(field: String, min: Double?, max: Double?)
  /// A value was not valid for an enumeration.
  case invalidEnumValue(type: String, value: String)
  /// Input data was malformed.
  case malformedData(reason: String)
  
  /// Stable machine-readable code for this error.
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
  
  /// Human-readable description of this error.
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
  
  /// Whether retrying the failed operation may succeed.
  public var isRetryable: Bool {
    false
  }
}
