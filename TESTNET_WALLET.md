# Dedicated Hyperliquid testnet wallet

Funding address: `0x444483eba5faa8a1499a4d2261c5e4e927b558cf`

Send **Hyperliquid testnet Core USDC** to this address. It is a dedicated testing
account. The private key is in `.local/hyperliquid-testnet.key`, ignored by Git,
with file permissions 0600 and directory permissions 0700. Its contents must not
be committed, logged, or pasted into chat.

The demo imports this same wallet into private simulator storage (0600); device builds use iOS Keychain. Disconnecting or relaunching
the app keeps the address. Mainnet initialization continues to use the read-only
mock; this key is only selected for testnet. Automated rejection probes launch with
`-fresh-testnet-wallet` so they do not use or alter the account funded here.

The [official faucet](https://app.hyperliquid-testnet.xyz/drip) requires the same
address to have deposited on mainnet, according to the
[faucet documentation](https://hyperliquid.gitbook.io/hyperliquid-docs/onboarding/testnet-faucet).
This newly generated address has no such history. If you already have an eligible,
funded testnet wallet, send its testnet USDC to the address above.

For an app install on another simulator/device, copy the key locally to that app's
`Library/Application Support/testnet-wallet-import.key` with permissions 0600,
then initialize Testnet. The app validates it, stores it privately (Keychain on devices), and removes
the import file. An existing different saved wallet is never overwritten silently.
Keep the ignored local key file as the backup for this testing account.

Once funded, successful order placement, fill, modification, and cancellation can
be tested with the same SDK signer. Funding alone does not verify those outcomes;
`TRADING_TEST_REPORT.md` records the checks completed so far.

Verified on 2026-10-15: this exact address survives demo disconnect/reconnect and
process relaunch. The simulator saved key matches the private local backup; its
permissions are 0600 and the temporary import was removed. The wallet has been
funded and passed order, position, transfer, and demo trading tests. Its unified
account uses Spot USDC as collateral, so zero separate Perps account value does
not mean it cannot trade. See `TRADING_TEST_REPORT.md` for results and cleanup.
Device Keychain storage compiles but has not been exercised on hardware.

Additional controlled test keys (also ignored, mode 0600):
- `.local/hyperliquid-testnet-recipient.key`: transfer recipient and referral test account.
- `.local/hyperliquid-testnet-multisig.key`: disposable multisig account, restored to normal signing.

Both secondary accounts have zero balance and no orders/positions after cleanup.
