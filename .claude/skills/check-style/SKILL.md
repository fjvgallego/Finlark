---
name: check-style
description: Review Finlark Swift changes against docs/technical/coding-style.md (design principles, naming, SwiftUI, localization, accessibility, logging, tests) and run swift-format lint. Use to review a diff, branch or file before the owner reviews it, or when asked for a style check.
---

# Check style

Report only. Don't edit code while checking.

## 1. Pick what to review

- The owner's target if they gave one: a path, a branch or a commit range.
- Otherwise the current branch against `main`: `git diff main...HEAD` plus uncommitted changes (`git diff HEAD`).

Only Swift files. Skip `Finlark/DesignExplorations/` unless the owner asks.

## 2. Run swift-format

```sh
xcrun swift-format lint --configuration .swift-format --strict <changed .swift files>
```

Report what it finds. If it can't run, say so and carry on with the manual review.

## 3. Read the guide

Read [coding-style.md](../../../docs/technical/coding-style.md) every time. Don't work from memory. Go through it
section by section against the changed code: design principles, functional style, formatting, naming, files, access
control, Swift, SwiftUI, localization, accessibility, comments, logging and tests.

Things that are easy to miss:

- A `default:` in a `switch` over one of our own enums.
- User-facing text outside String Catalogs, or amounts and dates built by concatenating strings.
- Literal colors, fonts or spacing in Features, or fixed font sizes.
- Icon-only buttons without an accessibility label, and status shown only by color.
- `print`, or a `Logger` call that shows an amount, name, note or category without `privacy: .private`.
- Missing `#Preview`s in light, dark, an accessibility text size and Spanish.
- Glossary terms used loosely: `spending` vs `balance`, a `Repayment` counted as income.

Module boundaries and data flow are [check-architecture](../check-architecture/SKILL.md)'s job, not this one's.

## 4. Report

One finding per problem, most serious first, each labelled with its guide section:

```
path/to/File.swift:18: SwiftUI
`.font(.system(size: 17))` doesn't scale with Dynamic Type. Use a text style or a DesignSystem font.
```

Suggest a concrete fix for each. If you find nothing, say so, and say what you checked.
