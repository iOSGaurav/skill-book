---
name: swift-viper-code-review
description: Use when reviewing iOS UIKit or SwiftUI code that uses VIPER architecture — checks layer boundary purity (View, Interactor, Presenter, Entity, Router), protocol boundaries, module assembly, dependency injection, Firebase patterns, and GitHub PR readiness
---

# Swift VIPER Code Review

## Overview

Focused code review skill for iOS projects using **VIPER** (View · Interactor · Presenter · Entity · Router). Validates that each layer has exactly one responsibility, all inter-layer communication goes through protocols, and no layer bleeds into another — alongside universal checks for accessibility, Firebase, snapshot testing, security, and PR hygiene.

**This skill is read-only. It reports findings — it never modifies files.**

## VIPER Layer Responsibilities (Reference)

| Layer | Owns | Must NOT do |
|---|---|---|
| **View** | UI rendering, delegate user events to Presenter | Business logic, data access, navigation |
| **Interactor** | Business logic, use-case execution | UI imports, navigation, data formatting for display |
| **Presenter** | Format data for display, coordinate View ↔ Interactor | Direct data access, navigation, UI layout |
| **Entity** | Plain data structures | Logic, network calls, persistence |
| **Router** | Navigation, module assembly | Business logic, data fetching, UI layout |

## When to Use

- Before opening a PR that adds or changes a VIPER module
- When a new screen module is added (should have all 5 layers)
- When a PR adds navigation and you need to verify it lives in Router
- When Interactor is suspected of doing UI work (or vice versa)
- When a new Firebase service call is added — to confirm it lives in Interactor

**Not this skill:**
- TCA `Reducer` / `@Dependency` codebase → use `swift-tca-code-review`
- MVVM `ObservableObject` / `@Observable` codebase → use `swift-mvvm-code-review`

## Input

| Type | Example |
|---|---|
| File path | `Sources/Modules/Login/LoginInteractor.swift` |
| PR number | `#89` |
| Directory | `Sources/Modules/Profile/` |
| Git diff | pasted `git diff main...HEAD` |
| Freeform | `"Review the Checkout VIPER module before merge"` |

If no input is given: scan `git diff --name-only HEAD~1 HEAD` for changed Swift files.

## Phase 0 — Scope Resolution

1. Identify input type (file, PR, directory, diff, freeform).
2. PR number → `gh pr diff <number>`.
3. Directory → glob `*.swift` recursively; exclude `*Snapshots.swift` in first pass.
4. No input → `git diff --name-only HEAD~1 HEAD`.
5. **Fallback:** No Swift files → `No Swift files detected. Please provide a file path, PR number, or directory.`
6. **Module completeness check:** For each VIPER module directory found, verify all 5 layer files exist. Flag missing layers immediately.

## Phase 1 — Context Detection

Read in priority order (higher overrides lower):

```
CLAUDE.md              ← highest priority — project conventions
.swiftlint.yml         ← lint rule overrides
Package.swift          ← Firebase, other versions
Podfile.lock           ← alternative version source
.github/workflows/     ← CI gate awareness
```

**VIPER file naming detection** (check for project conventions, else use defaults):

| Layer | Common suffixes |
|---|---|
| View | `*View`, `*ViewController`, `*View.swift` |
| Interactor | `*Interactor`, `*InteractorImpl` |
| Presenter | `*Presenter`, `*PresenterImpl` |
| Entity | `*Entity`, `*Model`, `*DataModel` |
| Router | `*Router`, `*RouterImpl`, `*Wireframe` |
| Builder/Assembly | `*Builder`, `*Module`, `*Configurator` |

If project uses different naming, detect from `CLAUDE.md` or existing file patterns.

**Firebase active if:** any of `FirebaseFirestore`, `FirebaseAuth`, `FirebaseStorage` imported.
**Snapshot active if:** `SnapshotTesting` imported.
**UIKit vs SwiftUI:** detect from `import UIKit` vs `import SwiftUI` in View files.

## Phase 2 — Analysis Dimensions

Run all active dimensions in parallel.

### 2A. VIPER Layer Purity (always active)

#### View Layer
- [ ] **VIEW-001** View only renders data received from Presenter; no data transforms — `HIGH`
- [ ] **VIEW-002** View delegates all user actions to Presenter via protocol — `HIGH`
- [ ] **VIEW-003** View has zero direct Interactor access — `CRITICAL`
- [ ] **VIEW-004** View protocol (`ViewProtocol`) defined; Presenter holds `weak var view: ViewProtocol?` — `HIGH`
- [ ] **VIEW-005** View has no network or database calls — `CRITICAL`
- [ ] **VIEW-006** View has no navigation logic (no `present`, `push`, `dismiss` called directly) — `HIGH`
- [ ] **VIEW-007** View holds Presenter as `var presenter: PresenterProtocol?` — `MEDIUM`

#### Interactor Layer
- [ ] **INT-001** Interactor has zero `UIKit` or `SwiftUI` imports — `HIGH`
- [ ] **INT-002** Interactor communicates results to Presenter via `InteractorOutputProtocol` — `HIGH`
- [ ] **INT-003** Interactor uses Entity objects, not raw dictionaries or `Any` — `MEDIUM`
- [ ] **INT-004** All external dependencies (network, persistence, Firebase) injected via protocol — `HIGH`
- [ ] **INT-005** Interactor has no navigation calls — `CRITICAL`
- [ ] **INT-006** Interactor output protocol is `weak` in Interactor to avoid retain cycle — `CRITICAL`
- [ ] **INT-007** Interactor is unit testable in isolation (no concrete dependencies) — `HIGH`

#### Presenter Layer
- [ ] **PRES-001** Presenter has zero direct data access (no network, no Firestore calls) — `CRITICAL`
- [ ] **PRES-002** Presenter has zero `UIKit` layout code (`frame`, `addSubview`, Auto Layout) — `HIGH`
- [ ] **PRES-003** Presenter formats data into display strings/models before passing to View — `MEDIUM`
- [ ] **PRES-004** Presenter delegates navigation to Router via `RouterProtocol` — `HIGH`
- [ ] **PRES-005** Presenter holds View as `weak var view: ViewProtocol?` — `CRITICAL`
- [ ] **PRES-006** Presenter holds Router as `var router: RouterProtocol?` — `MEDIUM`
- [ ] **PRES-007** Presenter is unit testable: mock View + mock Interactor injected — `HIGH`

#### Entity Layer
- [ ] **ENT-001** Entities are plain `struct` or `class` with no business methods — `MEDIUM`
- [ ] **ENT-002** Entities have no network, Firestore, or persistence logic — `HIGH`
- [ ] **ENT-003** Entities conform to `Codable` / `Equatable` / `Hashable` where appropriate — `LOW`
- [ ] **ENT-004** Entities have no reference to other VIPER layers — `HIGH`

#### Router Layer
- [ ] **ROUT-001** All navigation lives in Router; no `push`/`present` in View or Presenter — `HIGH`
- [ ] **ROUT-002** Router assembles the VIPER module (creates all 5 layers and wires protocols) — `HIGH`
- [ ] **ROUT-003** Router holds `weak var viewController: UIViewController?` (not strong) — `CRITICAL`
- [ ] **ROUT-004** Router has no business logic and no data fetching — `HIGH`
- [ ] **ROUT-005** Router protocol defined so Presenter doesn't depend on concrete Router — `MEDIUM`
- [ ] **ROUT-006** Child module creation goes through Router, not Presenter or View — `HIGH`

#### Module Assembly
- [ ] **MOD-001** All 5 VIPER layers present in the module directory — `HIGH`
- [ ] **MOD-002** Builder/Configurator creates layers in the correct dependency order — `HIGH`
- [ ] **MOD-003** No circular dependencies between layers — `CRITICAL`
- [ ] **MOD-004** Module entry point returns `UIViewController` or `View` — `MEDIUM`

### 2B. Accessibility (always active)

- [ ] **A11Y-001** All interactive elements have accessibility labels — `HIGH`
- [ ] **A11Y-002** Custom controls set accessibility role — `HIGH`
- [ ] **A11Y-003** Decorative images hidden from accessibility tree — `MEDIUM`
- [ ] **A11Y-004** Color is not the sole state differentiator — `HIGH`
- [ ] **A11Y-005** Dynamic Type respected — `HIGH`
- [ ] **A11Y-006** VoiceOver order correct for non-linear layouts — `LOW`

### 2C. Firebase (active when Firebase imported)

- [ ] **FB-001** Firebase calls made only in Interactor — `CRITICAL`
- [ ] **FB-002** Firestore queries have `.limit()` — no unbounded reads — `HIGH`
- [ ] **FB-003** All async Firebase calls in `do-catch`; errors passed to Presenter via protocol — `HIGH`
- [ ] **FB-004** No hardcoded Firestore document IDs — use constants/enums — `MEDIUM`
- [ ] **FB-005** Auth state via `addStateDidChangeListener`, not polled — `HIGH`
- [ ] **FB-006** `Codable` / `@DocumentID` used for type-safe Firestore decoding — `MEDIUM`
- [ ] **FB-007** Firebase service injected into Interactor via protocol, not accessed as singleton — `HIGH`
- [ ] **FB-008** Fields written match Firestore security rules expectations — `HIGH`

### 2D. Snapshot Testing (active when SnapshotTesting imported)

- [ ] **SNAP-001** Every new View/ViewController has a snapshot test — `HIGH`
- [ ] **SNAP-002** Snapshots cover light and dark mode — `HIGH`
- [ ] **SNAP-003** Snapshots cover smallest and largest Dynamic Type sizes — `HIGH`
- [ ] **SNAP-004** Device variants: minimum iPhone SE + iPhone 15 Pro Max — `MEDIUM`
- [ ] **SNAP-005** `assertSnapshot` uses `.image(precision: 0.98)` minimum — `MEDIUM`
- [ ] **SNAP-006** Snapshot PNGs committed under `__Snapshots__/` — `HIGH`
- [ ] **SNAP-007** Mock Presenter injected into View for snapshot tests (no live data) — `HIGH`

### 2E. Maintainability (always active)

- [ ] **MAINT-001** No function exceeds 40 lines — `MEDIUM`
- [ ] **MAINT-002** No file exceeds 300 lines — `MEDIUM`
- [ ] **MAINT-003** Magic numbers extracted to named constants — `LOW`
- [ ] **MAINT-004** `TODO` / `FIXME` include ticket reference e.g. `[PROJ-123]` — `LOW`
- [ ] **MAINT-005** No force unwrap `!` on non-guaranteed optionals — `HIGH`
- [ ] **MAINT-006** `guard` used for early exits — `LOW`

### 2F. Security (always active)

- [ ] **SEC-001** No secrets, API keys, or tokens hardcoded in source — `CRITICAL`
- [ ] **SEC-002** Keychain used for sensitive storage, not `UserDefaults` — `HIGH`
- [ ] **SEC-003** No HTTP where HTTPS is available — `HIGH`
- [ ] **SEC-004** User-facing errors do not expose internal details — `MEDIUM`

### 2G. GitHub PR Hygiene (always active)

- [ ] **GH-001** PR diff < 400 lines; suggest split if larger — `MEDIUM`
- [ ] **GH-002** Branch name follows `feature/`, `fix/`, `chore/` — `LOW`
- [ ] **GH-003** PR description is non-empty — `MEDIUM`
- [ ] **GH-004** No merge commits in branch history — `LOW`
- [ ] **GH-005** CI references SwiftLint, unit tests, snapshot tests — `LOW`
- [ ] **GH-006** Code comments explain WHY only — flag over-commenting and missing WHY comments — `LOW`

## Phase 3 — Severity & Merge Signal

| Severity | Meaning | Action |
|---|---|---|
| `CRITICAL` | Retain cycle, layer bleed, data loss, security hole | Block merge |
| `HIGH` | Protocol boundary missing, wrong layer responsibility | Fix before merge |
| `MEDIUM` | Testability, naming, minor structure concern | Fix if possible |
| `LOW` | Style, naming, optional improvement | Fix if easy |
| `SUGGESTION` | Alternative approach | Consider later |

**Merge signal:**
- 🔴 Not ready — any `CRITICAL` OR 3+ `HIGH`
- 🟡 Minor fixes — 1–2 `HIGH` OR 4+ `MEDIUM`
- 🟢 Ready — only `LOW` / `SUGGESTION`

## Output Format

```markdown
# VIPER Code Review: <Scope>
**Date:** <ISO-8601>
**Module(s) Reviewed:** <list>
**Layers Present:** V ✅ I ✅ P ✅ E ✅ R ✅ (or ❌ for missing)
**Firebase:** Yes / No | **Snapshot Testing:** Yes / No

## Module Completeness
| Module | V | I | P | E | R | Builder |
|---|---|---|---|---|---|---|

## Executive Summary
## Critical Issues (Block Merge)
### [CRITICAL] <Title>
- **File:** `path/File.swift:line`
- **Layer:** Interactor / Presenter / View / Router / Entity
- **Check:** INT-006
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
- **CLAUDE.md overrides all defaults** — especially layer naming conventions
- **Detect naming convention before flagging** — `Wireframe` may be the project's name for Router

## Common Mistakes

| Mistake | Fix |
|---|---|
| Flagging `Wireframe` as non-VIPER | Check CLAUDE.md or existing project patterns for naming convention |
| Missing circular dependency across 3+ layers | Trace full protocol graph, not just direct references |
| Not checking module completeness first | Always run MOD-001 before per-layer checks |
| Flagging Presenter formatting as business logic | Formatting display strings is Presenter's job — not a violation |
| Missing Firebase singleton in Interactor because it's injected via typealiased protocol | Check if the injected type ultimately wraps a singleton |
