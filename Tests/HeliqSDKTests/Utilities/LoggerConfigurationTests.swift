//
//  LoggerConfigurationTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Testing
import HeliqSDK

struct LoggerConfigurationTests {
  @Test func builderDefaultsToLoggingOff() {
    _ = HeliqSDK.builder().wallet(TestWallet()).build()
    #expect(Logger.shared.level == .off)
  }

  @Test func levelsAreOrderedForCumulativeFiltering() {
    #expect(LogLevel.error < .warn)
    #expect(LogLevel.warn < .info)
    #expect(LogLevel.info < .debug)
    #expect(LogLevel.off < .error)
  }

  @Test func builderConfiguresLoggerLevel() {
    _ = HeliqSDK.builder().wallet(TestWallet()).logging(.debug).build()

    #expect(Logger.shared.level == .debug)
  }

  @Test func latestBuildReplacesLoggerLevel() {
    _ = HeliqSDK.builder().wallet(TestWallet()).logging(.debug).build()
    _ = HeliqSDK.builder().wallet(TestWallet()).logging(.error).build()

    #expect(Logger.shared.level == .error)
  }

  private struct TestWallet: WalletServiceProtocol {
    let address = "0x0000000000000000000000000000000000000000"
    func sign(message: String) async throws -> SignatureTypes { fatalError("Unused") }
  }
}
