//
//  BuilderInfo.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a value for builder info.
public struct BuilderInfo: Sendable, Codable {
  /// The builder address associated with this value.
  public let builderAddress: String
  /// The role associated with this value.
  public let role: BuilderRole
  /// The commission bps associated with this value.
  public let commissionBps: Int
  
  /// Creates an instance with the supplied values.
  public init(builderAddress: String, role: BuilderRole, commissionBps: Int) {
    self.builderAddress = builderAddress
    self.role = role
    self.commissionBps = commissionBps
  }
}

/// Represents a set of supported values for builder role.
public enum BuilderRole: String, Sendable, Codable {
  /// The `builder` case.
  case builder = "Builder"
  /// The `router` case.
  case router = "Router"
}
