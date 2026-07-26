//
//  FastAssetCtxDecoder.swift
//  HeliqSDK
//
//  Created by Abdhilabs on 05/04/26.
//

import Compression
import Foundation

public struct FastAssetCtx: Sendable, Codable, Equatable {
  public let markPx: String?
  public let midPx: String?

  public init(markPx: String? = nil, midPx: String? = nil) {
    self.markPx = markPx
    self.midPx = midPx
  }
}

/// Decodes the Hyperliquid `fastAssetCtxs` raw-DEFLATE feed.
public enum FastAssetCtxDecoder {
  public static func decode(_ base64Payload: String) throws -> [String: FastAssetCtx] {
    guard let compressed = Data(base64Encoded: base64Payload) else {
      throw ValidationError.malformedData(reason: "fastAssetCtxs payload is not base64")
    }

    let decompressed = try inflateRaw(compressed)
    do {
      return try JSONDecoder().decode([String: FastAssetCtx].self, from: decompressed)
    } catch {
      throw ValidationError.malformedData(reason: "fastAssetCtxs payload is not valid JSON")
    }
  }

  private static func inflateRaw(_ input: Data) throws -> Data {
    let initialCapacity = max(input.count * 4, 256)
    var capacity = initialCapacity
    while capacity <= 4 * 1024 * 1024 {
      var output = Data(count: capacity)
      let decoded = output.withUnsafeMutableBytes { destination in
        input.withUnsafeBytes { source in
          compression_decode_buffer(
            destination.bindMemory(to: UInt8.self).baseAddress!,
            capacity,
            source.bindMemory(to: UInt8.self).baseAddress!,
            input.count,
            nil,
            COMPRESSION_ZLIB
          )
        }
      }
      if decoded > 0 {
        output.removeSubrange(decoded..<output.count)
        return output
      }
      capacity *= 2
    }
    throw ValidationError.malformedData(reason: "fastAssetCtxs raw-DEFLATE decompression failed")
  }
}
