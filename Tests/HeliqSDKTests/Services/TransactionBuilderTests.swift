//
//  TransactionBuilderTests.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Foundation
import Testing
import HeliqSDK

struct TransactionBuilderTests {
  @Test func testBuildOrderTransaction_marketOrder_createsCorrectDictionary() throws {
    let builder = TransactionBuilder()
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 1.0,
      price: nil,
      reduceOnly: false,
      cloid: nil
    )
    
    let transaction = try builder.buildOrderTransaction(order: order)
    
    #expect(transaction["type"] as? String == "order")
    #expect(transaction["asset"] as? Int == 0)
    #expect(transaction["side"] as? String == "Buy")
    #expect(transaction["size"] as? Double == 1.0)
    #expect(transaction["reduceOnly"] as? Bool == false)
  }
  
  @Test func testBuildOrderTransaction_limitOrder_includesPrice() throws {
    let builder = TransactionBuilder()
    let order = OrderRequest(
      asset: 1,
      side: .sell,
      orderType: .limit,
      size: 0.5,
      price: 50000.0,
      reduceOnly: false,
      cloid: nil
    )
    
    let transaction = try builder.buildOrderTransaction(order: order)
    
    #expect(transaction["type"] as? String == "order")
    #expect(transaction["asset"] as? Int == 1)
    if let orderType = transaction["orderType"] as? [String: Any] {
      #expect(orderType["price"] as? Double == 50000.0)
    }
  }
  
  @Test func testBuildOrderTransaction_triggerMarket_includesTriggerParams() throws {
    let builder = TransactionBuilder()
    let trigger = TriggerParams(triggerPx: 50000.0, tpsl: "tp")
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .triggerMarket(trigger),
      size: 1.0,
      price: nil,
      reduceOnly: false,
      cloid: nil
    )
    
    let transaction = try builder.buildOrderTransaction(order: order)
    
    #expect(transaction["type"] as? String == "order")
    if let orderType = transaction["orderType"] as? [String: Any] {
      #expect(orderType["type"] as? String == "triggerMarket")
      if let triggerDict = orderType["trigger"] as? [String: Any] {
        #expect(triggerDict["triggerPx"] as? Double == 50000.0)
        #expect(triggerDict["tpsl"] as? String == "tp")
      }
    }
  }
  
  @Test func testBuildOrderTransaction_triggerLimit_includesTriggerParams() throws {
    let builder = TransactionBuilder()
    let trigger = TriggerParams(triggerPx: 45000.0, tpsl: "sl")
    let order = OrderRequest(
      asset: 0,
      side: .sell,
      orderType: .triggerLimit(trigger),
      size: 0.5,
      price: 50000.0,
      reduceOnly: false,
      cloid: nil
    )
    
    let transaction = try builder.buildOrderTransaction(order: order)
    
    #expect(transaction["type"] as? String == "order")
    if let orderType = transaction["orderType"] as? [String: Any] {
      #expect(orderType["type"] as? String == "triggerLimit")
      #expect(orderType["price"] as? Double == 50000.0)
    }
  }
  
  @Test func buildOrderTransactionRejectsMissingLimitPrice() throws {
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .limit,
      size: 1,
      price: nil,
      reduceOnly: false,
      cloid: nil
    )

    #expect(throws: ValidationError.self) {
      _ = try TransactionBuilder().buildOrderTransaction(order: order)
    }
  }

  @Test func buildOrderTransactionRejectsNonPositiveSize() throws {
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 0,
      price: nil,
      reduceOnly: false,
      cloid: nil
    )

    #expect(throws: ValidationError.self) {
      _ = try TransactionBuilder().buildOrderTransaction(order: order)
    }
  }

  @Test func testBuildCancelTransaction_createsCorrectDictionary() throws {
    let builder = TransactionBuilder()
    
    let transaction = builder.buildCancelTransaction(orderId: "123", asset: 0)
    
    #expect(transaction["type"] as? String == "cancel")
    #expect(transaction["oid"] as? String == "123")
    #expect(transaction["asset"] as? Int == 0)
  }
  
  @Test func testBuildCancelByCloidTransaction_createsCorrectDictionary() throws {
    let builder = TransactionBuilder()
    
    let transaction = builder.buildCancelByCloidTransaction(cloid: "0xabcdef", asset: 1)
    
    #expect(transaction["type"] as? String == "cancelByCloid")
    #expect(transaction["cloid"] as? String == "0xabcdef")
    #expect(transaction["asset"] as? Int == 1)
  }
  
  @Test func testBuildCancelAllTransaction_createsCorrectDictionary() throws {
    let builder = TransactionBuilder()
    
    let transaction = builder.buildCancelAllTransaction()
    
    #expect(transaction["type"] as? String == "cancelAll")
    #expect(transaction["asset"] == nil)
  }
  
  @Test func testBuildCancelAllTransaction_withAsset_includesAsset() throws {
    let builder = TransactionBuilder()
    
    let transaction = builder.buildCancelAllTransaction(asset: 0)
    
    #expect(transaction["type"] as? String == "cancelAll")
    #expect(transaction["asset"] as? Int == 0)
  }
  
  @Test func testBuildSetLeverageTransaction_createsCorrectDictionary() throws {
    let builder = TransactionBuilder()
    
    let transaction = builder.buildSetLeverageTransaction(asset: 0, leverage: 10)
    
    #expect(transaction["type"] as? String == "setLeverage")
    #expect(transaction["asset"] as? Int == 0)
    #expect(transaction["leverage"] as? Int == 10)
  }
  
  @Test func testBuildOrderTransaction_withCloid_includesCloid() throws {
    let builder = TransactionBuilder()
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 1.0,
      price: nil,
      reduceOnly: false,
      cloid: "0x1234567890abcdef"
    )
    
    let transaction = try builder.buildOrderTransaction(order: order)
    
    #expect(transaction["cloid"] as? String == "0x1234567890abcdef")
  }
  
  @Test func testBuildOrderTransaction_withVaultAddress_includesVaultAddress() throws {
    let builder = TransactionBuilder()
    let order = OrderRequest(
      asset: 0,
      side: .buy,
      orderType: .market,
      size: 1.0,
      price: nil,
      reduceOnly: false,
      cloid: nil
    )
    
    let transaction = try builder.buildOrderTransaction(order: order, vaultAddress: "0xvault123")
    
    #expect(transaction["vaultAddress"] as? String == "0xvault123")
  }
}

struct WalletServiceTests {
  @Test func testWalletService_init_withValidKeyManager_setsAddress() async throws {
    let validPrivateKey = "abcd".padding(toLength: 64, withPad: "a", startingAt: 0)
    let keyManager = try KeyManager(privateKey: "0x" + validPrivateKey)
    
    let walletService = try await WalletService(keyManager: keyManager)
    
    #expect(walletService.address.count == 42)
    #expect(walletService.address.hasPrefix("0x"))
  }
  
  @Test func testWalletService_init_whenKeyManagerThrows_throwsError() async throws {
    do {
      _ = try await WalletService(keyManager: try KeyManager(keychainKey: "invalid"))
      #expect(Bool(false), "Expected throw")
    } catch let error as SigningError {
      #expect(error.errorCode == SigningError.keyNotFound.errorCode)
    }
  }
  
  @Test func testWalletService_sign_withSigner_returnsSignatureTypes() async throws {
    let validPrivateKey = "abcd".padding(toLength: 64, withPad: "a", startingAt: 0)
    let keyManager = try KeyManager(privateKey: "0x" + validPrivateKey)
    let walletService = try await WalletService(keyManager: keyManager)
    
    do {
      _ = try await walletService.sign(message: "test message")
      #expect(Bool(false), "Expected throw - signer is stub")
    } catch let error as SigningError {
      #expect(error.errorCode == SigningError.signingFailed(reason: "Stub implementation").errorCode)
    }
  }
}

struct KeyManagerTests {
  @Test func testKeyManager_initWithPrivateKey_createsSigner() throws {
    let validPrivateKey = "abcd".padding(toLength: 64, withPad: "a", startingAt: 0)
    let keyManager = try KeyManager(privateKey: "0x" + validPrivateKey)
    
    #expect(Bool(true), "KeyManager created successfully")
  }
  
  @Test func testKeyManager_initWithPrivateKey_derivesCorrectAddress() async throws {
    let validPrivateKey = "abcd".padding(toLength: 64, withPad: "a", startingAt: 0)
    let keyManager = try KeyManager(privateKey: "0x" + validPrivateKey)
    
    let address = try await keyManager.getAddress()
    
    #expect(address.count == 42)
    #expect(address.hasPrefix("0x"))
  }
  
  @Test func testKeyManager_initWithPrivateKey_invalidKey_throws() throws {
    do {
      _ = try KeyManager(privateKey: "invalid")
      #expect(Bool(false), "Expected throw")
    } catch let error as SigningError {
      #expect(error.errorCode == SigningError.invalidPrivateKey.errorCode)
    }
  }
  
  @Test func testKeyManager_initWithKeychainKey_throwsKeyNotFound() async throws {
    let keyManager = try KeyManager(keychainKey: "some-key")
    
    do {
      _ = try await keyManager.getAddress()
      #expect(Bool(false), "Expected throw")
    } catch let error as SigningError {
      #expect(error.errorCode == SigningError.keyNotFound.errorCode)
    }
  }
  
  @Test func testKeyManager_initWithAgentAddress_returnsAddress() async throws {
    let keyManager = try KeyManager(agentAddress: "0x1234567890123456789012345678901234567890")
    
    let address = try await keyManager.getAddress()
    
    #expect(address == "0x1234567890123456789012345678901234567890")
  }
  
  @Test func testKeyManager_sign_withSigner_returnsSignature() async throws {
    let validPrivateKey = "abcd".padding(toLength: 64, withPad: "a", startingAt: 0)
    let keyManager = try KeyManager(privateKey: "0x" + validPrivateKey)
    
    do {
      _ = try await keyManager.sign(message: "test")
      #expect(Bool(false), "Expected throw - signer is stub")
    } catch let error as SigningError {
      #expect(error.errorCode == SigningError.signingFailed(reason: "Stub implementation").errorCode)
    }
  }
  
  @Test func testKeyManager_sign_withoutSigner_throwsKeyNotFound() async throws {
    let keyManager = try KeyManager(keychainKey: "some-key")
    
    do {
      _ = try await keyManager.sign(message: "test")
      #expect(Bool(false), "Expected throw")
    } catch let error as SigningError {
      #expect(error.errorCode == SigningError.keyNotFound.errorCode)
    }
  }
}
