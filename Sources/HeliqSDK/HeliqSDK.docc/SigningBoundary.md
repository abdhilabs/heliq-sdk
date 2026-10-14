# Signing boundary

The SDK creates canonical protocol payloads and typed-data envelopes, but wallet custody remains outside the SDK.

``WalletServiceProtocol`` is the signing seam. Applications implement `signL1(action:nonce:isMainnet:)` and `signUserSigned(primaryType:fields:action:isMainnet:)` through their chosen wallet. The native `WalletService(keyManager:)` implements both. `sign(message:)` alone is insufficient for trading; its protocol defaults throw rather than fabricate a signature.

Canonical MessagePack ordering is protocol-significant. Do not replace order-preserving encoding with unordered nested dictionaries in signed actions.

Signing diagnostics record operation outcome and elapsed time only. They do not emit address values, action hashes, nonces, signatures, or key material.
