# Error handling

SDK operations throw SDK errors for invalid responses, rate limits, decoding failures, network failures, validation failures, and signing failures.

```swift
do {
  let mids = try await HeliqSDK.shared.info.getAllMids()
  print(mids.prices)
} catch {
  // Surface a user-appropriate message in your application.
  // Enable `.verbose` logging only when diagnostics are needed.
  print(error)
}
```

Use structured error types when your application needs recovery behavior. Do not parse server error-body text as a stable machine contract; upstream response text may change.
