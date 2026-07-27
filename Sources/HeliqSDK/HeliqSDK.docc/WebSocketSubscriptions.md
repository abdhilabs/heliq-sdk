# WebSocket subscriptions

Use the SDK WebSocket layer for live subscriptions. Connection lifecycle, subscription activity, and disconnects become OSLog lifecycle events when ``LogLevel/verbose`` is enabled.

Subscriptions are protocol-specific. Subscribe only after connecting, retain the service for as long as updates are needed, and explicitly disconnect when your feature is no longer active.

See <doc:Architecture> for reconnection and routing responsibilities.
