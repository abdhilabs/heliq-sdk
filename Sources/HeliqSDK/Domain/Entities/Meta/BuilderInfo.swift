//
//  BuilderInfo.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public struct BuilderInfo: Sendable, Codable {
  public let builderAddress: String
  public let role: BuilderRole
  public let commissionBps: Int
  
  public init(builderAddress: String, role: BuilderRole, commissionBps: Int) {
    self.builderAddress = builderAddress
    self.role = role
    self.commissionBps = commissionBps
  }
}

public enum BuilderRole: String, Sendable, Codable {
  case builder = "Builder"
  case router = "Router"
}
