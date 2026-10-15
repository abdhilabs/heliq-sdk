# Perps fixtures

All account, history, market, and WebSocket fixtures are synthetic. They do not
contain the funded test wallets' balances, fills, fees, or ledger history.
The fast-context sample is the public official documentation sample; the larger
compression fixture is generated from synthetic prices.

Signing vectors use the publicly known test-only key consisting of 64 `1`
characters. It must never be funded or used for live transactions. Vectors were
generated with the official Hyperliquid Python SDK signing implementation at
revision `2fdb18f9517675ea03695a0962bd19eece9c83f0`. Newer documented action
schemas without specific Python helper functions use its generic EIP-712 signer.

Regeneration: run `Scripts/generate_perps_signing_fixtures.py` with that official
SDK importable and its dependencies installed in an isolated Python environment.
The generator does not read any local wallet key file or call an exchange endpoint.
