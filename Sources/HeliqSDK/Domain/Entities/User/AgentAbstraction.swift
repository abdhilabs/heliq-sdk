//
//  AgentAbstraction.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation

public enum AgentType: String, Sendable, Codable {
  case user = "u"
  case paper = "p"
  case info = "i"
}

public struct AgentAbstraction: Sendable, Codable {
  public let agentType: AgentType
  public let address: String?
  
  public init(agentType: AgentType, address: String? = nil) {
    self.agentType = agentType
    self.address = address
  }
}
