---
name: swift-tca-code-review
description: Use when reviewing iOS SwiftUI code that uses The Composable Architecture (TCA) — checks Reducer composition, Effect correctness, @Dependency usage, Action naming, TestStore coverage, Firebase patterns, accessibility, snapshot coverage, and GitHub PR readiness
---

# Swift TCA Code Review

## Overview

Focused code review skill for iOS projects using **The Composable Architecture (TCA)**. Validates Reducer design, Effect safety, dependency injection, Action conventions, and test coverage — alongside universal checks for accessibility, Firebase, snapshot testing, security, and PR hygiene.

**This skill is read-only. It reports findings — it never modifies files.**

## When to Use

- Before opening a PR that adds or changes a TCA Reducer
- After implementing new State, Action, or Effect logic
- When a PR uses `@Dependency`, `ifLet`, `forEach`, or `Scope`
- When TCA + Firebase are used together in the same feature
- When snapshot tests fail after a TCA state change

**Not this skill:**
- MVVM `ObservableObject`/`@Published` codebase → use `swift-mvvm-code-review`
- VIPER modules → use `swift-viper-code-review`

## Input

| Type | Example |
|---|---|
| File path | `Sources/Features/Home/HomeFeature.swift` |
| PR number | `#247` |
| Directory | `Sources/Features/Checkout/` |
| Git diff | pasted `git diff main...HEAD` |
| Freeform | `"Review the CartReducer before I open the PR"` |

If no input is given: scan `git diff --name-only HEAD~1 HEAD` for changed Swift files.

## Phase 0 — Scope Resolution

1. Identify input type (file, PR, directory, diff, freeform).
2. PR number → `gh pr diff <number>`.
3. Directory → glob `*.swift` recursively; exclude `*Snapshots.swift` in first pass.
4. No input → `git diff --name-only HEAD~1 HEAD`.
5. **Fallback:** No Swift files → `No Swift files detected. Please provide a file path, PR number, or directory.`

## Phase 1 — Context Detection

Read in priority order (higher overrides lower):

```
CLAUDE.md              ← highest priority — project conventions
.swiftlint.yml         ← lint rule overrides
Package.swift          ← TCA version, Firebase version
Podfile.lock           ← alternative version source
.github/workflows/     ← CI gate awareness
```

**TCA version detection:**

| Pattern | Version | Rules |
|---|---|---|
| `Reducer<State, Action, Environment>` | 0.x | Legacy pullback/scope |
| `struct X: ReducerProtocol` | 1.x | ReducerProtocol |
| `@Reducer struct X` | 1.7+ | Macro-based |
| Undetectable | Unknown | TCA 1.x assumed; noted in output |

**Firebase active if:** any of `FirebaseFirestore`, `FirebaseAuth`, `FirebaseStorage` imported.
**Snapshot active if:** `SnapshotTesting` imported.

## Phase 2 — Analysis Dimensions

Run all active dimensions in parallel.

### 2A. TCA Architecture (always active)

- [ ] **TCA-001** Reducer composed with `Scope` / `ifLet` / `forEach` where required — `HIGH`
- [ ] **TCA-002** No side effects inside `State` or `Action` (no computed properties with network calls) — `CRITICAL`
- [ ] **TCA-003** All `Effect`s return `Effect<Action>` — no silent void fire-and-forget — `HIGH`
- [ ] **TCA-004** `@Dependency` used for all external services; no singleton access — `HIGH`
- [ ] **TCA-005** `TestStore` exists for every new Reducer — `HIGH`
- [ ] **TCA-006** Action names follow `noun.verb` (e.g. `loginButton.tapped`, `userData.loaded`) — `LOW`
- [ ] **TCA-007** `@Reducer` macro used when project is on TCA 1.7+ — `MEDIUM`
- [ ] **TCA-008** No `Store` captured strongly in closures (retain cycle) — `CRITICAL`
- [ ] **TCA-009** `withDependencies` used in tests, not manual `Environment` override — `MEDIUM`
- [ ] **TCA-010** Shared state accessed via `@Shared` / `PersistenceKey`, not passed through deep State trees — `MEDIUM`

### 2B. SwiftUI Performance (always active)

- [ ] **PERF-001** `body` contains no side effects (`print`, `Logger`, mutations) — `HIGH`
- [ ] **PERF-002** Heavy computations in ViewModel or cached `let`; not in `body` — `MEDIUM`
- [ ] **PERF-003** `ForEach` / `List` use stable `id` keypaths — not `.self` on value types — `HIGH`
- [ ] **PERF-004** `@StateObject` vs `@ObservedObject` ownership correct — `HIGH`
- [ ] **PERF-005** `AnyView` not used in tight loops — `MEDIUM`
- [ ] **PERF-006** `.task {}` preferred over `.onAppear` for async work — `LOW`
- [ ] **PERF-007** `NavigationStack` used (not deprecated `NavigationView`) — `MEDIUM`

### 2C. Accessibility (always active)

- [ ] **A11Y-001** All interactive elements have `.accessibilityLabel` — `HIGH`
- [ ] **A11Y-002** Custom controls set `.accessibilityRole` — `HIGH`
- [ ] **A11Y-003** Decorative images have `.accessibilityHidden(true)` — `MEDIUM`
- [ ] **A11Y-004** Color is not the sole state differentiator — `HIGH`
- [ ] **A11Y-005** Dynamic Type respected — no fixed font sizes without scalable alternative — `HIGH`
- [ ] **A11Y-006** VoiceOver order set with `.accessibilitySortPriority` where non-obvious — `LOW`

### 2D. Firebase (active when Firebase imported)

- [ ] **FB-001** Firestore queries have `.limit()` — no unbounded reads — `HIGH`
- [ ] **FB-002** All async Firebase calls in `do-catch`; errors surfaced to user — `HIGH`
- [ ] **FB-003** No hardcoded Firestore document IDs — use constants/enums — `MEDIUM`
- [ ] **FB-004** Auth state via `addStateDidChangeListener`, not polled — `HIGH`
- [ ] **FB-005** `Codable` / `@DocumentID` used for type-safe Firestore decoding — `MEDIUM`
- [ ] **FB-006** `FieldValue.serverTimestamp()` used with offline awareness — `MEDIUM`
- [ ] **FB-007** Fields written match Firestore security rules expectations — `HIGH`

### 2E. Snapshot Testing (active when SnapshotTesting imported)

- [ ] **SNAP-001** Every new screen has a `*SnapshotTests.swift` file — `HIGH`
- [ ] **SNAP-002** Snapshots cover light and dark mode — `HIGH`
- [ ] **SNAP-003** Snapshots cover smallest and largest Dynamic Type sizes — `HIGH`
- [ ] **SNAP-004** Device variants: minimum iPhone SE + iPhone 15 Pro Max — `MEDIUM`
- [ ] **SNAP-005** `assertSnapshot` uses `.image(precision: 0.98)` minimum threshold — `MEDIUM`
- [ ] **SNAP-006** Snapshot PNG files committed under `__Snapshots__/` — `HIGH`

### 2F. Maintainability (always active)

- [ ] **MAINT-001** No function exceeds 40 lines — `MEDIUM`
- [ ] **MAINT-002** No file exceeds 300 lines — `MEDIUM`
- [ ] **MAINT-003** Magic numbers extracted to named constants — `LOW`
- [ ] **MAINT-004** `TODO` / `FIXME` include ticket reference e.g. `[PROJ-123]` — `LOW`
- [ ] **MAINT-005** No force unwrap `!` on non-guaranteed optionals — `HIGH`
- [ ] **MAINT-006** `guard` used for early exits, not deeply nested `if let` — `LOW`

### 2G. Security (always active)

- [ ] **SEC-001** No secrets, API keys, or tokens hardcoded in source — `CRITICAL`
- [ ] **SEC-002** Keychain used for sensitive storage, not `UserDefaults` — `HIGH`
- [ ] **SEC-003** No HTTP where HTTPS is available — `HIGH`
- [ ] **SEC-004** User-facing errors do not expose internal stack details — `MEDIUM`

### 2H. GitHub PR Hygiene (always active)

- [ ] **GH-001** PR diff < 400 lines; suggest splitting if larger — `MEDIUM`
- [ ] **GH-002** Branch name follows `feature/`, `fix/`, `chore/` — `LOW`
- [ ] **GH-003** PR description is non-empty — `MEDIUM`
- [ ] **GH-004** No merge commits in branch history — `LOW`
- [ ] **GH-005** CI references SwiftLint, unit tests, snapshot tests — `LOW`
- [ ] **GH-006** Code comments explain WHY only — flag over-commenting and missing WHY comments — `LOW`

## Phase 3 — Severity & Merge Signal

| Severity | Meaning | Action |
|---|---|---|
| `CRITICAL` | Crash, data loss, security hole | Block merge |
| `HIGH` | Architecture violation, broken pattern | Fix before merge |
| `MEDIUM` | Performance, maintainability concern | Fix if possible |
| `LOW` | Style, naming, minor issue | Fix if easy |
| `SUGGESTION` | Optional improvement | Consider later |

**Merge signal:**
- 🔴 Not ready — any `CRITICAL` OR 3+ `HIGH`
- 🟡 Minor fixes — 1–2 `HIGH` OR 4+ `MEDIUM`
- 🟢 Ready — only `LOW` / `SUGGESTION`

## Output Format

```markdown
# TCA Code Review: <Scope>
**Date:** <ISO-8601>
**TCA Version:** 0.x / 1.x / 1.7+
**Firebase:** Yes / No | **Snapshot Testing:** Yes / No

## Executive Summary
## Critical Issues (Block Merge)
### [CRITICAL] <Title>
- **File:** `path/File.swift:line`
- **Check:** TCA-008
- **Finding:** <description>
- **Impact:** <what breaks>
- **Fix:**
```swift
// Before / After
```

## High Priority
## Medium Priority
## Low Priority / Suggestions
## Accessibility Report       ← tabular
## Snapshot Coverage Report   ← per-screen matrix
## Firebase Patterns Report   ← tabular
## PR Hygiene                 ← checklist

## Metrics Summary
| Dimension | Status | Issues |
**Overall Signal:** 🟢 / 🟡 / 🔴
```

## Posting Findings to GitHub

When input is a PR number, output ready-to-run `gh` commands alongside each finding.
Use the shared **`github-operations`** skill for all command templates and suggestion block format.
→ `../github-operations/SKILL.md`

## Code Comment Policy

Flag a missing comment **only when the WHY is genuinely non-obvious** to a future reader. Do not suggest adding comments that restate what well-named code already says.

**Flag:**
- A hidden constraint, OS-version quirk, or framework workaround with no explanation
- A non-obvious algorithm or performance choice with no justification
- Behaviour that would surprise a reader and is not documented

**Do not suggest adding a comment for:**
- Functions and types whose name communicates intent
- Standard Swift idioms (`guard`, `map`, `forEach`, Combine chains)
- View body layout code — naming should be self-documenting
- Test functions — the test name is the documentation
- Trivial computed vars, getters, and simple transforms

## Guardrails

- **Never modify source files** — reporting only
- **Never delete or rename files**
- **Never run destructive git commands**
- **Never update snapshot baselines** — recommend the command; do not run it
- **Ask before expanding scope** to files outside original input
- **CLAUDE.md overrides all defaults**
- **Preserve TCA + MVVM coexistence** if intentional in the project

## Common Mistakes

| Mistake | Fix |
|---|---|
| Not reading `CLAUDE.md` before applying defaults | Always read project rules first |
| Flagging `@Reducer` as wrong on TCA 0.x project | Detect version before applying version-specific checks |
| Missing snapshot gap because test file exists | Verify `__Snapshots__/` has committed PNGs |
| Marking unreachable code path as `CRITICAL` | Confirm the path is reachable before escalating severity |
