# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.2] — 2026-06-26

### Changed
- add CODEOWNERS and verify tag is on main before publish

## [0.2.1] — 2026-06-26

### Changed
- fix RuboCop offenses from TargetRubyVersion 3.4 upgrade

## [0.2.0] — 2026-06-26

### Changed
- add CI/CD workflows and fix release script newline bug

## [0.1.1] — 2026-06-26

### Added
- wire up top-level A2A module with error classes and requires
- add JSONRPCEnvelope for server-side request/response handling
- add JSON-RPC and HTTP+JSON protocol bindings and client
- add push notification config, dispatcher, and Rack receiver
- add security schemes and OAuth flow types
- add AgentCard, discovery, and agent metadata types
- add streaming types and SSE parser/writer
- add core data model (Task, Message, Artifact, Part types, Role)

### Changed
- pre-publish fixes (gemspec author, URLs, license, dev deps to Gemfile)
- add conventional commits hook and automated changelog generation (release)
- add rubocop config, ruby version pin, and gemspec

### Other
- update CLAUDE.md
- add README, examples, changelog, and Claude harness
- add full spec suite (595 examples)

## [0.1.0] — 2026-06-17

### Added
- Initial gem scaffold (lib, spec, bin/console, bin/setup, gemspec)

[Unreleased]: https://github.com/rafaelqfigueiredo/a2a-rb/compare/v0.2.2...HEAD
[0.1.1]: https://github.com/rafaelqfigueiredo/a2a-rb/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/rafaelqfigueiredo/a2a-rb/releases/tag/v0.1.0

[0.2.0]: https://github.com/rafaelqfigueiredo/a2a-rb/compare/v0.1.1...v0.2.0

[0.2.1]: https://github.com/rafaelqfigueiredo/a2a-rb/compare/v0.2.0...v0.2.1

[0.2.2]: https://github.com/rafaelqfigueiredo/a2a-rb/compare/v0.2.1...v0.2.2
