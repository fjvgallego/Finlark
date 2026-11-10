---
name: check-architecture
description: Review Finlark code changes against the architecture rules in docs/architecture.md (module imports, writes through use cases, money types, clock, periods, routes, system frameworks, concurrency). Use to review a diff, branch or file before the owner reviews it, or when asked for an architecture check.
---

# Check architecture

Report only. Don't edit code while checking.

## 1. Pick what to review

- The owner's target if they gave one: a path, a branch or a commit range.
- Otherwise the current branch against `main`: `git diff main...HEAD` plus uncommitted changes (`git diff HEAD`).

Read the changed files in full, not just the diff lines, so you can see their imports and where they live.

## 2. Read the rules

Read [architecture.md](../../../docs/architecture.md) every time. Don't work from memory, because the page changes
through ADRs. Check against:

- **Modules:** each file's module, from its path under `Packages/FinlarkKit`, may import only what its row in the
  table allows. Code under `Finlark/` belongs to the App target row.
- **Rules:** every numbered rule in the Rules section.
- **Constraints:** no third-party SDKs that collect data, no network use except CloudKit, and a CloudKit-compatible
  model (no unique constraints, every property optional or defaulted, every relationship optional).
- **Data:** reads with `@Query` and Domain functions, writes through use cases with one save per user action, and
  drafts holding plain values.

`Finlark/DesignExplorations/` holds design prototypes, not production code. Skip it unless the owner asks.

## 3. Report

One finding per problem, most serious first:

```
path/to/File.swift:42: Rule 2 (views never change models)
`modelContext.insert(transaction)` in a view. Move it into the AddTransaction use case.
```

- Cite the rule or table row, and the ADR behind it when it helps.
- Suggest a concrete fix.
- If something looks wrong but no rule covers it, list it separately as a question for the owner. Changing the
  architecture needs an ADR ([write-adr](../write-adr/SKILL.md)).
- If you find nothing, say so, and say what you checked.
