# Signing boundary

The SDK creates canonical protocol payloads and typed-data envelopes, but wallet custody remains outside the SDK.

``WalletServiceProtocol`` is the signing seam. Applications provide an implementation that exposes an address and signs a typed message through their chosen secure wallet solution.

Canonical MessagePack ordering is protocol-significant. Do not replace order-preserving encoding with unordered nested dictionaries in signed actions.

Signing diagnostics record operation outcome and elapsed time only. They do not emit address values, action hashes, nonces, signatures, or key material.
