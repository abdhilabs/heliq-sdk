//
//  JSONCoderTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct JSONCoderTests {
  @Test func testEncode_encodesWithSnakeCaseStrategy() throws {
    let meta = Meta(universe: [], spotAssetConfigs: [:])
    let data = try JSONCoder.encode(meta)
    
    let jsonString = String(data: data, encoding: .utf8) ?? ""
    #expect(jsonString.contains("universe"))
    #expect(jsonString.contains("spot_asset_configs"))
  }
  
  @Test func testDecode_decodesWithSnakeCaseStrategy() throws {
    let jsonString = "{\"universe\":[],\"spot_asset_configs\":{}}"
    let data = jsonString.data(using: .utf8)!
    
    let decoded = try JSONCoder.decode(Meta.self, from: data)
    
    #expect(decoded.universe.count == 0)
    #expect(decoded.spotAssetConfigs.isEmpty == true)
  }
  
  @Test func testEncodeToString_returnsUTF8String() throws {
    let allMids = AllMids(prices: ["BTC": 50000.0])
    let string = try JSONCoder.encodeToString(allMids)
    
    #expect(string.contains("BTC"))
    #expect(string.contains("50000"))
  }
  
  @Test func testDecodeFromString_parsesStringCorrectly() throws {
    let string = "{\"prices\":{\"ETH\":3000}}"
    
    let decoded = try JSONCoder.decodeFromString(AllMids.self, from: string)
    
    #expect(decoded.price(for: "ETH") == 3000.0)
  }
}

struct DataExtensionsTests {
  @Test func testHexString_withValidData_returnsCorrectHex() throws {
    let data = Data([0xAB, 0xCD, 0xEF, 0x12])
    
    #expect(data.hexString == "abcdef12")
  }
  
  @Test func testHexString_withEmptyData_returnsEmptyString() throws {
    let data = Data()
    
    #expect(data.hexString == "")
  }
  
  @Test func testInitHexString_withValid0xPrefix_createsData() throws {
    let data = Data(hexString: "0xabcdef")
    
    #expect(data != nil)
    #expect(data?.hexString == "abcdef")
  }
  
  @Test func testInitHexString_withValidNoPrefix_createsData() throws {
    let data = Data(hexString: "abcdef")
    
    #expect(data != nil)
    #expect(data?.hexString == "abcdef")
  }
  
  @Test func testInitHexString_withInvalidLength_returnsNil() throws {
    let data = Data(hexString: "0xZZ")
    
    #expect(data == nil)
  }
  
  @Test func testInitHexString_withInvalidCharacters_returnsNil() throws {
    let data = Data(hexString: "ghijklmn")
    
    #expect(data == nil)
  }
  
  @Test func testPrettyPrintedJSON_withValidJSON_returnsFormattedString() throws {
    let jsonString = "{\"key\":\"value\"}"
    let data = jsonString.data(using: .utf8)!
    
    let pretty = data.prettyPrintedJSON
    
    #expect(pretty != nil)
    #expect(pretty?.contains("\n") == true)
  }
  
  @Test func testPrettyPrintedJSON_withInvalidJSON_returnsNil() throws {
    let data = Data([0xFF, 0xFE])
    
    let pretty = data.prettyPrintedJSON
    
    #expect(pretty == nil)
  }
}

struct StringExtensionsTests {
  @Test func testIsValidHex_withValidHex_returnsTrue() throws {
    #expect("abcdef123456".isValidHex == true)
    #expect("ABCDEF123456".isValidHex == true)
    #expect("0xabcdef".isValidHex == true)
  }
  
  @Test func testIsValidHex_withInvalidCharacters_returnsFalse() throws {
    #expect("ghijklmn".isValidHex == false)
  }
  
  @Test func testIsValidEthereumAddress_withValid40Chars_returnsTrue() throws {
    #expect("0x1234567890123456789012345678901234567890".isValidEthereumAddress == true)
  }
  
  @Test func testIsValidEthereumAddress_withInvalidLength_returnsFalse() throws {
    #expect("0x1234".isValidEthereumAddress == false)
  }
  
  @Test func testIsValidPrivateKey_withValid64Chars_returnsTrue() throws {
    #expect("a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2".isValidPrivateKey == true)
  }
  
  @Test func testIsValidPrivateKey_withInvalidLength_returnsFalse() throws {
    #expect("a1b2c3d4e5f6a1b2".isValidPrivateKey == false)
  }
  
  @Test func testWithout0xPrefix_removesPrefix() throws {
    #expect("0xabcdef".without0xPrefix == "abcdef")
    #expect("abcdef".without0xPrefix == "abcdef")
  }
  
  @Test func testWith0xPrefix_addsPrefixIfMissing() throws {
    #expect("abcdef".with0xPrefix == "0xabcdef")
    #expect("0xabcdef".with0xPrefix == "0xabcdef")
  }
  
  @Test func testLeftPadding_toLength4_withPad0_padsCorrectly() throws {
    #expect("AB".leftPadding(toLength: 4, withPad: "0") == "00AB")
    #expect("1234".leftPadding(toLength: 4, withPad: "0") == "1234")
  }
  
  @Test func testRightPadding_toLength4_withPad0_padsCorrectly() throws {
    #expect("AB".rightPadding(toLength: 4, withPad: "0") == "AB00")
    #expect("1234".rightPadding(toLength: 4, withPad: "0") == "1234")
  }
}

struct LoggerTests {
  @Test func testLog_info_doesNotThrow() throws {
    let logger = Logger.shared

    logger.info("test info message")
  }
  
  @Test func testLog_warning_doesNotThrow() throws {
    let logger = Logger.shared
    
    logger.warning("test warning message")
  }
  
  @Test func testLog_error_doesNotThrow() throws {
    let logger = Logger.shared
    
    logger.error("test error message")
  }
}
