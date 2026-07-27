//
//  AllMidsWireFormatTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct AllMidsWireFormatTests {
  @Test func decodesOfficialFlatStringPriceMap() throws {
    let data = Data("{\"BTC\":\"104321.5\",\"ETH\":\"2512.34\"}".utf8)

    let mids = try JSONDecoder().decode(AllMids.self, from: data)

    #expect(mids.price(for: "BTC") == 104_321.5)
    #expect(mids.price(for: "ETH") == 2_512.34)
  }
}
