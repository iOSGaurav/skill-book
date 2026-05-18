---
name: swift-mvvm-code-review
description: Use when reviewing iOS SwiftUI code that uses MVVM architecture with ObservableObject or @Observable — checks ViewModel purity, View/ViewModel separation, threading safety, Firebase patterns, accessibility, snapshot coverage, and GitHub PR readiness
---

# Swift MVVM Code Review

## Overview

Focused code review skill for iOS SwiftUI projects using **MVVM** (`ObservableObject` / `@Published` / `@Observable`). Validates ViewModel purity, View responsibility boundaries, threading safety, protocol testability, and binding patterns — alongside universal checks for accessibility, Firebase, snapshot testing, security, and PR hygiene.

**This skill is read-only. It reports findings — it never modifies files.**

## When to Use

- Before opening a PR that adds or changes a ViewModel
- After adding `@Published` properties or `@Observable` conformance
- When a PR mixes View logic with business logic
- When a ViewModel directly accesses Firebase, network, or persistence
- When a new SwiftUI screen is added without clear MVVM separation

**Not this skill:**
- TCA `Reducer` / `@Dependency` codebase → use `swift-tca-code-review`
- VIPER modules → use `swift-viper-code-review`

## Input

| Type | Example |
|---|---|
| File path | `Sources/Features/Profile/ProfileViewModel.swift` |
| PR number | `#134` |
| Directory | `Sources/Features/Dashboard/` |
| Git diff | pasted `git diff main...HEAD` |
| Freeform | `"Review the LoginViewModel and LoginView before merge"` |

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
Package.swift          ← Firebase, Combine, other versions
Podfile.lock           ← alternative version source
.github/workflows/     ← CI gate awareness
```

**MVVM variant detection:**

| Pattern | Variant | Notes |
|---|---|---|
| `class X: ObservableObject` + `@Published` | Classic MVVM | iOS 13+ |
| `@Observable class X` | Observation framework | iOS 17+ |
| `class X: ObservableObject` + `Combine` | Combine MVVM | Publisher-based |
| Mixed variants | Hybrid | Note in output; check each file by its variant |

**Firebase active if:** any of `FirebaseFirestore`, `FirebaseAuth`, `FirebaseStorage` imported.
**Snapshot active if:** `SnapshotTesting` imported.
**Combine active if:** `import Combine` found in ViewModel files.

## Phase 2 — Analysis Dimensions

Run all active dimensions in parallel.

### 2A. MVVM Architecture (always active)

- [ ] **MVVM-001** ViewModel has zero `SwiftUI` imports (no `View`, `Text`, etc.) — `HIGH`
- [ ] **MVVM-002** ViewModel has zero `UIKit` imports — `HIGH`
- [ ] **MVVM-003** Views contain zero business logic (no network calls, no data transforms) — `HIGH`
- [ ] **MVVM-004** Protocol defined for every ViewModel (enables test doubles) — `MEDIUM`
- [ ] **MVVM-005** `@Published` arrays and objects are only mutated on `@MainActor` / main thread — `CRITICAL`
- [ ] **MVVM-006** Dependencies injected via initializer; no static/singleton access — `HIGH`
- [ ] **MVVM-007** `@Observable` class does not expose `@Published` (they are mutually exclusive) — `HIGH`
- [ ] **MVVM-008** `async/await` methods on ViewModel are marked `@MainActor` or dispatch to main — `HIGH`
- [ ] **MVVM-009** ViewModel does not hold strong reference to View — `CRITICAL`
- [ ] **MVVM-010** `Combine` subscriptions stored in `Set<AnyCancellable>` and cancelled on `deinit` — `HIGH`
- [ ] **MVVM-011** No business logic duplicated between ViewModel and Model layer — `MEDIUM`
- [ ] **MVVM-012** Error states exposed as `@Published var error: Error?`, not printed to console — `MEDIUM`

### 2B. SwiftUI Bindings & Performance (always active)

- [ ] **PERF-001** `@StateObject` used for ViewModel ownership in root View; `@ObservedObject` in child Views — `HIGH`
- [ ] **PERF-002** `@EnvironmentObject` used only when ViewModel is truly shared across deep tree — `MEDIUM`
- [ ] **PERF-003** `body` contains no side effects (`print`, `Logger`, mutations) — `HIGH`
- [ ] **PERF-004** Heavy computations in ViewModel; not recalculated in `body` — `MEDIUM`
- [ ] **PERF-005** `ForEach` / `List` use stable `id` keypaths — not `.self` on value types — `HIGH`
- [ ] **PERF-006** `AnyView` not used in tight loops — `MEDIUM`
- [ ] **PERF-007** `.task {}` preferred over `.onAppear` for async ViewModel calls — `LOW`
- [ ] **PERF-008** `NavigationStack` used (not deprecated `NavigationView`) — `MEDIUM`
- [ ] **PERF-009** `@Observable` views use fine-grained observation (avoid whole-object observation) — `MEDIUM`

### 2C. Accessibility (always active)

- [ ] **A11Y-001** All interactive elements have `.accessibilityLabel` — `HIGH`
- [ ] **A11Y-002** Custom controls set `.accessibilityRole` — `HIGH`
- [ ] **A11Y-003** Decorative images have `.accessibilityHidden(true)` — `MEDIUM`
- [ ] **A11Y-004** Color is not the sole state differentiator — `HIGH`
- [ ] **A11Y-005** Dynamic Type respected — no fixed font sizes without scalable alternative — `HIGH`
- [ ] **A11Y-006** VoiceOver order set with `.accessibilitySortPriority` where non-obvious — `LOW`

### 2D. Firebase (active when Firebase imported)

- [ ] **FB-001** Firestore queries have `.limit()` — no unbounded reads — `HIGH`
- [ ] **FB-002** All async Firebase calls in `do-catch`; errors stored in `@Published var error` — `HIGH`
- [ ] **FB-003** No hardcoded Firestore document IDs — use constants/enums — `MEDIUM`
- [ ] **FB-004** Auth state via `addStateDidChangeListener`, not polled — `HIGH`
- [ ] **FB-005** `Codable` / `@DocumentID` used for type-safe Firestore decoding — `MEDIUM`
- [ ] **FB-006** `FieldValue.serverTimestamp()` used with offline awareness — `MEDIUM`
- [ ] **FB-007** Firebase calls made in ViewModel (not in View body) — `CRITICAL`
- [ ] **FB-008** Fields written match Firestore security rules expectations — `HIGH`

### 2E. Snapshot Testing (active when SnapshotTesting imported)

- [ ] **SNAP-001** Every new screen has a `*SnapshotTests.swift` file — `HIGH`
- [ ] **SNAP-002** Snapshots cover light and dark mode — `HIGH`
- [ ] **SNAP-003** Snapshots cover smallest and largest Dynamic Type sizes — `HIGH`
- [ ] **SNAP-004** Device variants: minimum iPhone SE + iPhone 15 Pro Max — `MEDIUM`
- [ ] **SNAP-005** `assertSnapshot` uses `.image(precision: 0.98)` minimum — `MEDIUM`
- [ ] **SNAP-006** Snapshot PNGs committed under `__Snapshots__/` — `HIGH`
- [ ] **SNAP-007** Snapshots use mock/stub ViewModel, not live network calls — `HIGH`

### 2F. Maintainability (always active)

- [ ] **MAINT-001** No function exceeds 40 lines — `MEDIUM`
- [ ] **MAINT-002** No file exceeds 300 lines — `MEDIUM`
- [ ] **MAINT-003** Magic numbers extracted to named constants — `LOW`
- [ ] **MAINT-004** `TODO` / `FIXME` include ticket reference e.g. `[PROJ-123]` — `LOW`
- [ ] **MAINT-005** No force unwrap `!` on non-guaranteed optionals — `HIGH`
- [ ] **MAINT-006** `guard` used for early exits — `LOW`

### 2G. Security (always active)

- [ ] **SEC-001** No secrets, API keys, or tokens hardcoded in source — `CRITICAL`
- [ ] **SEC-002** Keychain used for sensitive storage, not `UserDefaults` — `HIGH`
- [ ] **SEC-003** No HTTP where HTTPS is available — `HIGH`
- [ ] **SEC-004** User-facing errors do not expose internal details — `MEDIUM`

### 2H. GitHub PR Hygiene (always active)

- [ ] **GH-001** PR diff < 400 lines; suggest split if larger — `MEDIUM`
- [ ] **GH-002** Branch name follows `feature/`, `fix/`, `chore/` — `LOW`
- [ ] **GH-003** PR description is non-empty — `MEDIUM`
- [ ] **GH-004** No merge commits in branch history — `LOW`
- [ ] **GH-005** CI references SwiftLint, unit tests, snapshot tests — `LOW`
- [ ] **GH-006** Code comments explain WHY only — flag over-commenting and missing WHY comments — `LOW`

## Phase 3 — Severity & Merge Signal

| Severity | Meaning | Action |
|---|---|---|
| `CRITICAL` | Crash, data loss, threading issue, security hole | Block merge |
| `HIGH` | Architecture violation, broken MVVM boundary | Fix before merge |
| `MEDIUM` | Performance, testability concern | Fix if possible |
| `LOW` | Style, naming, minor issue | Fix if easy |
| `SUGGESTION` | Optional improvement | Consider later |

**Merge signal:**
- 🔴 Not ready — any `CRITICAL` OR 3+ `HIGH`
- 🟡 Minor fixes — 1–2 `HIGH` OR 4+ `MEDIUM`
- 🟢 Ready — only `LOW` / `SUGGESTION`

## Output Format

```markdown
# MVVM Code Review: <Scope>
**Date:** <ISO-8601>
**MVVM Variant:** Classic ObservableObject / @Observable / Combine
**Firebase:** Yes / No | **Snapshot Testing:** Yes / No

## Executive Summary
## Critical Issues (Block Merge)
### [CRITICAL] <Title>
- **File:** `path/File.swift:line`
- **Check:** MVVM-005
- **Finding:** <description>
- **Impact:** <what breaks>
- **Fix:**
```swift
// Before / After
```

## High Priority
## Medium Priority
## Low Priority / Suggestions
## Accessibility Report
## Snapshot Coverage Report
## Firebase Patterns Report
## PR Hygiene

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
- **Respect ObservableObject vs @Observable distinction** — rules differ between variants

## Common Mistakes

| Mistake | Fix |
|---|---|
| Applying `@Observable` rules to `ObservableObject` class | Detect the variant first; they have different threading models |
| Flagging ViewModel–View binding as a violation | Bindings are expected; flag only when business logic is in the View |
| Missing Firebase-in-View violation because it's in `.onAppear` | `.onAppear` in a View is still View code — flag FB-007 |
| Passing snapshot test because mock ViewModel was not used | Check that snapshot test does not make live network calls |
