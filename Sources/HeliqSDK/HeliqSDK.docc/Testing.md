# Testing

Run Swift package validation in CI and iPhone Air simulator suites on the Mac build host for Xcode project verification.

## Required checks

- Unit tests validate models, protocol encoding, error behavior, logging configuration, and typed/raw parity boundaries.
- Integration tests validate implemented protocol calls.
- Demo UI tests validate user-facing workflows and error presentation.
- DocC validation builds documentation from the catalog and source comments.

When adding a protocol feature, update the implementation, regression tests, public symbol documentation, and architecture guide if an invariant changes.
