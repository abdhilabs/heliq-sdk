# Local wallet storage

Use ``KeychainWalletStore`` when an application chooses SDK-managed local custody on
iOS 16+ or macOS 13+. External wallets remain supported through ``WalletServiceProtocol``;
this feature does not select a wallet provider for an application.

## Import, open, export, and delete

```swift
import HeliqSDK
import LocalAuthentication

let context = LAContext()
context.localizedReason = "Authorize access to your trading wallet"
let store = KeychainWalletStore(
  service: "com.example.app.trading-wallet",
  authenticationContext: context)

// Import an app-supplied valid 32-byte secp256k1 key as 64 hex digits, optionally with 0x.
// Never embed a real key in source code, logs, analytics, preferences, or environment files.
try store.store(privateKey: privateKeyHex, for: "primary")

// On subsequent launches, construct the same store and open without calling store again.
let manager = try KeyManager(keychainKey: "primary", store: store)
let wallet = try await WalletService(keyManager: manager)
let client = try HeliqClient.Builder()
  .environment(.testnet)
  .wallet(wallet)
  .build()

// Explicit account backup: fresh authentication, never the cached signing session.
// Keep the returned secret only as long as required by the app's secure reveal/backup UX.
let accountPrivateKey = try await store.exportPrivateKey(for: "primary",
  authenticationReason: "Back up your account private key")

// Destructive and unrecoverable by the SDK. Require app authorization/confirmation first.
try store.deleteKey(for: "primary")
context.invalidate()
```

The original `KeyManager(keychainKey:)` initializer now works with the default service
`com.heliq.sdk.local-wallet`. Store with `KeychainWalletStore()` to use that namespace.
An identifier is an exact Keychain account within the service and app's default access group.
No shared access group or synchronizable/cloud item is requested.

`store` validates the scalar using the existing crypto dependency and uses atomic
`SecItemAdd`. Duplicates throw; it never deletes, updates, or silently replaces an existing
wallet. `store(privateKey:for:)` is also the import API for a previously exported key.
There is no key-generation, mnemonic, cloud-recovery, or overwrite API. The caller must
dispose of its own imported/exported key material. Deleting and then storing a replacement is an
explicit app decision. An already-open manager binds to the first derived public address
and refuses to sign with a different replacement key; create a new manager for a new wallet.

## Fixed security policy

- Generic-password bytes protected with
  `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` and `SecAccessControl.userPresence`.
- The device must have a passcode; reads require an unlocked device and system user presence
  through **biometry OR the device passcode**. This is not biometric-only custody or
  `biometryCurrentSet`: biometric enrollment changes do not intentionally invalidate the key.
- No weaker fallback, legacy macOS file Keychain, iCloud synchronization, or migration to
  another device. macOS uses `kSecUseDataProtectionKeychain: true` as well. A signed app with
  appropriate Keychain access is required; command-line/test hosts may fail entitlement checks.
- Adding a key does not authenticate the user. **Deletion does not require user presence**
  under Apple's generic-password ACL semantics. The app must protect import/delete UX and
  must not expose these operations as unauthenticated remote commands.
- Device loss, device erase, or passcode removal can permanently lose this wallet. Apple
  deletes this protection class's items when the passcode is removed. Backups do not migrate
  these items to another device. Treat a missing key as missing, not as permission to create
  a replacement wallet or as proof the user never had one. Uninstall is not a deletion API;
  Keychain items may survive app reinstall.

Apple references: [accessibility](https://developer.apple.com/documentation/security/ksecattraccessiblewhenpasscodesetthisdeviceonly),
[user presence](https://developer.apple.com/documentation/security/secaccesscontrolcreateflags/userpresence),
[macOS data protection](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain).

## Authentication and operation lifetime

Constructing a manager does no Keychain I/O. Constructing `WalletService` derives its public
address by reading the key and can prompt. Every subsequent address lookup or signing call
loads again; no decrypted signer or private-key cache is kept by a Keychain-backed manager.
The same existing HyperCore L1/contextual L1 and user-action EIP-712 signer is used. Legacy
arbitrary-message signing remains unsupported; this adds no EVM transaction signing.

Without an injected context each read uses a fresh `LAContext` with the reason
"Access your local wallet". This is not a promise of one prompt per signature: Apple controls
authentication UI. Apps own prompt localization, foreground gating, authentication reuse,
and session expiry through their context. Do not mutate or invalidate it during an operation;
invalidate it when ending a session. A context can opt out of interaction with
`interactionNotAllowed = true`; an unsatisfied ACL must fail, not bypass authentication.
For Face ID, provide `NSFaceIDUsageDescription` in the host app's Info.plist.

**Export has a stricter session boundary than signing.** `exportPrivateKey` requires a nonempty,
app-localized authentication reason, creates a fresh `LAContext`, sets biometric reuse duration
to zero, and explicitly evaluates `.deviceOwnerAuthentication`. Only after success does it
read the ACL-protected key using that context. It never accepts the store's previously
authenticated signing context. It invalidates its own context on return or failure and does
not cache exported bytes or strings. OS authentication can use biometry or device credentials;
this is not a biometric-only guarantee. The platform still controls how the challenge is shown.
Missing-item export authenticates before looking up the item. Cancellation/failure returns
no key and triggers no fallback. Cancellation of a Swift task is checked before authentication
and before the read, but does not itself dismiss an already-displayed OS prompt.

Security calls are synchronous and may block while the OS authenticates. Wallet APIs are
async; `KeyManager` is an actor to serialize loading and address binding off the main actor.
Cancelling a Swift task does not automatically dismiss the system prompt or revoke a
signature already in flight. The app can invalidate its context to end authentication.
Deletion prevents later loads but cannot revoke an operation that already loaded a key,
an existing signature, or on-chain/HyperCore permissions.

## Failures

| Failure | SDK result |
| --- | --- |
| Missing, deleted, or invalidated item | `SigningError.keyNotFound` |
| Invalid hex, length, scalar, or loaded key bytes | `SigningError.invalidPrivateKey` |
| Existing item on add | `KeychainWalletError.duplicateKey` |
| `errSecUserCanceled` | `.authenticationCancelled` |
| `errSecAuthFailed` | `.authenticationFailed` |
| `errSecInteractionNotAllowed` (e.g. locked/background/noninteractive) | `.interactionNotAllowed` |
| `errSecNotAvailable` or ACL creation failure | `.unavailable` |
| Other Security errors, including missing entitlements | `.unexpectedStatus(OSStatus)` |

Apple can coalesce different authentication conditions into the same status. These errors
report what Security returned, not a definitive diagnosis of passcode/lock/biometry state.
No error triggers an automatic retry, key creation, or fallback. Apps decide whether to offer
a deliberate retry after unlocking, returning to foreground, or changing a session context.
For explicit export authentication, `LAError` user/app/system cancellation maps to
`.authenticationCancelled`; noninteractive access to `.interactionNotAllowed`; unavailable,
unenrolled, passcode-not-set, or invalid-context conditions to `.unavailable`; other authentication
failures (and an empty reason) to `.authenticationFailed`. Swift task cancellation throws
`CancellationError` rather than returning a secret.

## Remaining limitations and application responsibilities

This is **Keychain-backed software secp256k1 signing**, not signing inside Apple's P-256
Secure Enclave. Plaintext key bytes briefly exist in process memory for derivation/signing.
Temporary buffers and the released signer are reset on a best-effort basis; Swift copy-on-write,
caller-owned strings, compiler/runtime copies, and the crypto dependency prevent guaranteed
zeroization. Explicit export intentionally returns a plaintext hex string whose lifetime the
SDK cannot control or erase. Never send it to a backend, telemetry, logs, crash breadcrumbs,
or analytics. Export UI, clipboard handling, warnings, and recovery orchestration belong in
the app; a previous successful export is not authorization for a subsequent reveal/copy action.
This does not defend against a compromised process, debugger, or malicious code
running in the app's access group. System user presence authorizes key access, not a trusted
transaction-content display or application-level trading approval.

Applications, including Eigtrade, still own recovery policy, backup/export UX, prompts and
session policy, agent approval/revocation, and whether to use an external or local wallet.
An exported **account** key can restore that account. A device-local HyperCore agent key is
only delegated signing authority, **not the main wallet backup**; the app must keep key roles
distinct and must not label an agent-key export as account recovery. Storage identifiers do
not infer or enforce HyperCore roles, and `KeyManager(agentAddress:)` supplies no private key.
This SDK does not add mnemonic recovery, cloud backup, MPC/embedded-wallet integration,
or application screens.

## Validation

`swift test --filter KeychainWalletTests` runs public wallet lifecycle and signing-vector tests
with only platform calls replaced by a locked in-memory test backend. Cryptography is
real; storage encryption, passcode enforcement, and authentication UI are **not** simulated
proof of Apple security behavior. Status tests cover cancellation, failed authentication,
locked/noninteractive access, unavailable protection, and missing entitlements after a wallet
has already opened, to catch decrypted-key caching regressions. Import/export round-trips
restore the same address and fixture signatures; exports after a previous successful export
must still fail when fresh authentication is denied.

On a signed, foreground Apple test host with Keychain access and a configured passcode, run
`HELIQ_TEST_KEYCHAIN=1 swift test --filter KeychainWalletTests.realAppleKeychainLifecycle`.
This opt-in test includes explicit export, uses an unfunded public fixture, requires real human
authentication, and deletes its unique test item. Do not enable it on an unattended host that
cannot authenticate.
Physical-device validation must additionally exercise cancellation, lock/background access,
and passcode removal using disposable test wallets; the SDK must never change device security
settings to make a test pass.

### Implementation validation record (23 October 2026)

On the Mac mini with Xcode 27 / Swift 6.4, the implementation passed the serialized macOS
unit suite (434 Swift Testing tests across 59 suites and four XCTest tests) and compiled the
SDK and test bundles for arm64 iOS 16 Simulator. These lifecycle/import/export tests used
the platform-response test backend and real signing cryptography. The real-Keychain opt-in
test failed at the initial add with `errSecMissingEntitlement` (-34018), before signing or
export. Successful real authentication, storage, signing, and export therefore remain
unvalidated on a properly signed app/device. No policy was weakened to bypass this failure.

On that newer toolchain, normal SwiftPM resolution advanced only `swift-collections` from
1.6.0 to 1.7.3 in the validation environment; the repository's frozen lock was rejected as
out of date with `--force-resolved-versions`. The implementation does not change dependencies
or the checked-in lock. Validation with the frozen lock on the supported Swift 6.1 toolchain
remains outstanding.
