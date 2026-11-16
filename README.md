# Finlark
Personal finance app for iOS built to production standards: modular SwiftUI architecture, Swift 6 concurrency, CI/CD, ADRs and an AI-assisted development workflow.

## Documentation

See [docs/](docs/README.md): vision, requirements, roadmap, glossary, design, architecture and ADRs.

## Build and run

Open `Finlark.xcodeproj` in the Xcode version CI uses (`DEVELOPER_DIR` in
[ci.yml](.github/workflows/ci.yml)) and run the `Finlark` scheme. The command that builds and runs the tests, and the
lint script, are in [architecture.md](docs/architecture.md#build-and-ci). CI runs the same two on every pull request
and on every push to `main`.

Agents working in this repository start from [AGENTS.md](AGENTS.md). The skills that read Jira tickets use the
Atlassian MCP server in [`.mcp.json`](.mcp.json), and opening pull requests uses the GitHub CLI (`gh`).

## License

Source code is published for portfolio purposes. All rights reserved.
