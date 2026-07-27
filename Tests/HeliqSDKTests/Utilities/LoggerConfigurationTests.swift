//
//  LoggerConfigurationTests.swift
//  HeliqSDKTests
//
//  Created by Abdhilabs on 05/04/26.
//

import Testing
import HeliqSDK

struct LoggerConfigurationTests {
  @Test func builderDefaultsToDisabledLogging() {
    _ = HeliqSDK.builder().wallet(TestWallet()).build()
    #expect(Logger.shared.level == .disabled)
  }

  @Test func debugPresetIncludesOnlyErrorsAndWarnings() {
    #expect(LogLevel.debug.contains(.error))
    #expect(LogLevel.debug.contains(.warning))
    #expect(!LogLevel.debug.contains(.info))
  }

  @Test func verbosePresetIncludesEveryEventSeverity() {
    #expect(LogLevel.verbose.contains(.error))
    #expect(LogLevel.verbose.contains(.warning))
    #expect(LogLevel.verbose.contains(.info))
  }

  @Test func builderAcceptsCustomCombinations() {
    let level: LogLevel = [.error, .info]
    _ = HeliqSDK.builder().wallet(TestWallet()).logging(level).build()

    #expect(Logger.shared.level == level)
  }

  @Test func latestBuildReplacesLoggerLevel() {
    _ = HeliqSDK.builder().wallet(TestWallet()).logging(.verbose).build()
    _ = HeliqSDK.builder().wallet(TestWallet()).logging(.debug).build()

    #expect(Logger.shared.level == .debug)
  }

  private struct TestWallet: WalletServiceProtocol {
    let address = "0x0000000000000000000000000000000000000000"
    func sign(message: String) async throws -> SignatureTypes { fatalError("Unused") }
  }
}
