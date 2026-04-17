# Change Log

All notable changes to the "Test File Dimmer" extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-04-16

### Added
- Initial release.
- `FileDecorationProvider` that dims test files in the Explorer and adds a
  configurable badge (default: `T`).
- Default glob patterns covering Python, JavaScript/TypeScript, Go, Ruby,
  Rust, Java, Kotlin, Scala, C#, PHP, Swift, Groovy, and C/C++ test files.
- Settings:
  - `testFileDimmer.enabled`
  - `testFileDimmer.patterns`
  - `testFileDimmer.excludePatterns`
  - `testFileDimmer.badge`
  - `testFileDimmer.tooltip`
  - `testFileDimmer.propagateToFolders`
- Contributed theme color `testFileDimmer.foreground` so the dim shade can be
  customized through `workbench.colorCustomizations`.
- Commands: `Test File Dimmer: Toggle Decorations`, `Test File Dimmer: Refresh Decorations`.
