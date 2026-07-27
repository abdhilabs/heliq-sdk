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
  @Test func exposesTypedMetaAndAssetCtxsFromSDKRawAPI() {
    HeliqSDK.shared.initialize { builder in
      _ = builder.environment(.testnet).wallet(TestWallet())
    }

    let _: () async throws -> HyperliquidMetaAndAssetCtxs = HeliqSDK.shared.raw.metaAndAssetCtxs
  }

  private struct TestWallet: WalletServiceProtocol {
    let address = "0x0000000000000000000000000000000000000000"
    func sign(message: String) async throws -> SignatureTypes {
      SignatureTypes(r: "0x0", s: "0x0", v: 27, signatureType: .eoa)
    }
  }
}
