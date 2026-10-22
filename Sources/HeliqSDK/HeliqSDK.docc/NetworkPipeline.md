# Network pipeline

``APIClient`` builds requests from ``APIRouterProtocol``, applies ``RateLimitHandler``, executes through `URLSession`, maps HTTP results to SDK errors, and retries retryable failures according to ``RetryPolicy``.

## Invariants

- Decode only successful HTTP responses.
- Preserve non-2xx response text for the thrown client error.
- Retry only errors marked retryable.
- Log path, status, size, and elapsed time at the configured level.
- Emit non-2xx response bodies only at ``LogLevel/verbose`` and cap output at 16 KB.
- Never emit request bodies or successful response bodies.
