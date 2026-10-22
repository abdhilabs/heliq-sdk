# Placing orders

Use ``HeliqClient/exchange`` for implemented typed exchange workflows. Your application owns wallet access through ``WalletServiceProtocol``.

Before submitting a production order, validate the typed request fields, handle failures explicitly, and use testnet for integration verification where appropriate.

For exchange actions outside the typed convenience layer, use ``HyperliquidAPI`` only with the official request schema and caller-provided signing material.

Typed actions sign official L1 or EIP-712 payloads and never retry exchange mutations automatically.
Market orders use an IOC limit with 5% slippage from current mids; supply `price` for an explicit bound.
Check per-order errors in bulk results and per-cancel errors before reporting success.

Builder approval uses `updateBuilder(builderAddress:maxFeeRate:)` with an explicit percentage.
Multisig conversion uses `convertToMultiSigUser(authorizedUsers:threshold:)`; the SDK never selects signers for you.
Transfer asset 0 means perpetual USDC; other values are spot token indices. For spot USDC,
use `spotTransfer(..., asset: 0)`. Vault amounts are USDC units, encoded as micro-USDC.

The demo keeps its testnet wallet in the iOS Keychain on devices and in private simulator storage. Automated rejection probes use
fresh in-memory wallets. Its mainnet wallet is a read-only mock. Successful trading requires an application-managed, funded signing wallet.
