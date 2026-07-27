//
//  AgentAbstraction.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

/// Represents a set of supported values for agent type.
public enum AgentType: String, Sendable, Codable {
  /// The `user` case.
  case user = "u"
  /// The `paper` case.
  case paper = "p"
  /// The `info` case.
  case info = "i"
}

/// Represents a value for agent abstraction.
public struct AgentAbstraction: Sendable, Codable {
  /// The agent type associated with this value.
  public let agentType: AgentType
  /// The address associated with this value.
  public let address: String?
  
  /// Creates an instance with the supplied values.
  public init(agentType: AgentType, address: String? = nil) {
    self.agentType = agentType
    self.address = address
  }
}
