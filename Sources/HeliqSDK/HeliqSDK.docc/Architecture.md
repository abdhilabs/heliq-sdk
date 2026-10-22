# Architecture

## Module structure

``HeliqClient`` is the public composition root. ``HeliqClient/Builder`` constructs a ``DIContainer``, which wires repositories, raw transport, network clients, cache state, and environment configuration.

## Repository seam

``InfoRepository`` and ``ExchangeRepository`` are the typed convenience seams. Implementations translate domain requests to protocol calls. Keep new typed wrappers separate from raw transport so the SDK can add ergonomic APIs without overstating typed protocol coverage.

## Raw transport invariant

``HyperliquidAPI`` preserves documented request parameters and response fields as ``JSONValue``. Do not silently coerce an unmodelled protocol response into a legacy typed model.

## Cache and WebSocket state

Asset metadata caching records only coin-to-asset mappings and expires entries by its configured policy. WebSocket connection, reconnection, message routing, and subscription ownership remain separate responsibilities so they can evolve without changing repository interfaces.

## Logging

``Logger`` is configured by ``HeliqClient/Builder``. It is global to the SDK process and the most recently built client replaces its configured ``LogLevel``.
