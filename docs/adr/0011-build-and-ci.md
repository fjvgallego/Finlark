# ADR-0011: Build and CI

Status: **Accepted** (2026-11-11) · Ticket: FIN-12 · Requirements: C-1, NFR-001, NFR-009

## Context

- NFR-009: the build and the tests run in CI on every pull request and on `main`.
- [ADR-0007](0007-testing-strategy.md) left the commands that run the tests to the CI setup, and
  [coding-style.md](../technical/coding-style.md) left how swift-format runs.
- The code lives in a local package, `Packages/FinlarkKit` ([ADR-0003](0003-module-structure.md)). Its modules build
  only for iOS, so `swift test`, which builds for macOS, can't run its tests. They need `xcodebuild` and a simulator.
- The project was created with Xcode 27.1. On GitHub's hosted runners, Xcode 27 is only on the `xcode-27` image, which
  is in public preview. `macos-latest` still has Xcode 26.
- The repository is public and hosted on GitHub. CI must not need secrets or code signing.
- `Finlark/DesignExplorations/` holds the FIN-9 designs as reference code. It was written before the
  [`.swift-format`](../../.swift-format) file existed and has about 13,000 findings, almost all indentation.

## Options considered

1. **GitHub Actions.** Lives in the repository, runs on pushes and pull requests, and is free for public
   repositories. It depends on GitHub's runner images having the right Xcode.
2. **Xcode Cloud.** Always has the current Xcode and handles signing for later releases. It's configured in Xcode and
   App Store Connect rather than in the repository, and its free hours are limited.
3. **No CI, local checks only.** Nothing to set up, but it doesn't meet NFR-009.

For running the package's tests, two ways were considered: the package's own scheme (`FinlarkKit-Package`), run from
the package's folder, and the app's scheme with a test plan that lists the package's test targets. The second builds
the app and runs the tests with one command, and it's the same scheme that Xcode's Test action uses.

## Decision

Option 1.

- **One scheme.** The shared `Finlark` scheme builds the app and runs `Finlark.xctestplan`, which lists the
  package's test targets. A new test target is added to the test plan in the same commit.
- **One command builds and tests**, locally and in CI:

  ```sh
  xcodebuild test -project Finlark.xcodeproj -scheme Finlark \
      -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' CODE_SIGNING_ALLOWED=NO
  ```

- **Lint** is `scripts/lint.sh`: `swift format lint --strict` with the repository's `.swift-format` over every Swift
  file in `Finlark/` and `Packages/`, except `Finlark/DesignExplorations/`. Any finding fails the job.
- **The workflow**, `.github/workflows/ci.yml`, runs a lint job and a build-and-test job on every pull request and
  on every push to `main`. A push to another branch doesn't start it, so a branch with an open pull request isn't
  checked twice. It uses the `xcode-27` runner with Xcode 27.1 selected by path, has read-only permissions and uses
  no secrets.
- The app target builds for iPhone only, portrait only, with iOS 26.0 as its minimum (C-1, NFR-001).

## Consequences

- A pull request that doesn't build, fails a test or breaks the formatting rules is flagged without anyone running
  anything by hand.
- A branch is checked only once it has a pull request. Before that, the same commands run locally.
- The Xcode version, the simulator and the runner label are written in the workflow. They need a manual update when
  the project moves to a new Xcode, and when the `xcode-27` image leaves preview or is renamed.
- Tests run on the iOS 27 simulator, not on iOS 26. The iOS 26.0 minimum is checked only by the compiler's
  availability errors, so behavior on iOS 26 is part of the manual checks before a release.
- The design explorations aren't linted. Code moved out of them into the package is linted like any other code.
- UI smoke tests ([ADR-0007](0007-testing-strategy.md)) need an Xcode UI test target, which doesn't exist yet. It
  joins the same test plan when the first smoke test is written.
- Releases, signing and TestFlight aren't covered. They get their own decision.
