# Logging and diagnostics

Logging is disabled by default. Configure it during initialization:

```swift
builder.logging(.verbose)
```

``LogLevel`` is an `OptionSet`:

- ``LogLevel/disabled`` emits nothing.
- ``LogLevel/debug`` emits errors and recoverable warnings.
- ``LogLevel/verbose`` additionally emits lifecycle and timing information.
- Custom combinations such as `[.error, .info]` are supported.

Logs use Apple OSLog. At verbose level, non-2xx HTTP bodies are emitted up to 16 KB and report whether they were truncated. Request bodies and successful response bodies are never emitted. Avoid enabling verbose logging in contexts where non-success server responses may contain sensitive application data.
