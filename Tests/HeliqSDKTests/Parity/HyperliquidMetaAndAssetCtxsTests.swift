//
//  HyperliquidMetaAndAssetCtxsTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct HyperliquidMetaAndAssetCtxsTests {
  @Test func exposesTypedMetaAndAssetCtxsFromClientRawAPI() throws {
    let client = try HeliqClient.Builder()
      .environment(.testnet)
      .build()

    let _: () async throws -> HyperliquidMetaAndAssetCtxs = client.raw.metaAndAssetCtxs
  }
}
