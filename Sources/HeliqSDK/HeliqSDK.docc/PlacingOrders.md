# Placing orders

Use ``HeliqSDK/exchange`` for implemented typed exchange workflows. Your application owns wallet access through ``WalletServiceProtocol``.

Before submitting a production order, validate the typed request fields, handle failures explicitly, and use testnet for integration verification where appropriate.

For exchange actions outside the typed convenience layer, use ``HyperliquidAPI`` only with the official request schema and caller-provided signing material.
