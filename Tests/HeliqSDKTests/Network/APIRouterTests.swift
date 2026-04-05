//
//  APIRouterTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import XCTest
@testable import HeliqSDK

final class APIRouterTests: XCTestCase {
  func testAPIRouterInfoPath() {
    XCTAssertEqual(HyperliquidAPI.userState(address: "0x123").path, "/info")
  }
  
  func testAPIRouterExchangePath() {
    XCTAssertEqual(HyperliquidAPI.placeOrder(signature: "sig", payload: OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 1.0
    )).path, "/exchange")
  }
  
  func testHTTPMethodInfo() {
    XCTAssertEqual(HyperliquidAPI.allMids.method, .post)
  }
  
  func testHTTPMethodExchange() {
    XCTAssertEqual(HyperliquidAPI.cancel(orderId: "123", asset: 0).method, .post)
  }
}

enum HyperliquidAPI {
  case userState(address: String)
  case allMids
  case placeOrder(signature: String, payload: OrderRequest)
  case cancel(orderId: String, asset: Int)
}

extension HyperliquidAPI: APIRouterProtocol {
  var path: String {
    switch self {
    case .userState: return "/info"
    case .allMids: return "/info"
    case .placeOrder: return "/exchange"
    case .cancel: return "/exchange"
    }
  }
  
  var method: HTTPMethod {
    .post
  }
}
