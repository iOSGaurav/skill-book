# swift-tca-code-review

> Code review skill for iOS SwiftUI projects using **The Composable Architecture (TCA)**.

---

## What It Reviews

| Dimension | Key Checks |
|---|---|
| **TCA Architecture** | Reducer composition, Effect types, `@Dependency` injection, Action naming (`noun.verb`), `TestStore` usage, retain cycles in closures |
| **SwiftUI Performance** | `body` purity, `ForEach` id stability, `@StateObject` ownership, `NavigationStack` over `NavigationView`, `AnyView` avoidance |
| **Accessibility** | Labels, roles, Dynamic Type, VoiceOver order (WCAG 2.1 AA) |
| **Firebase** | All calls in Effect/Interactor; query limits; type-safe decoding; error propagation to Reducer |
| **Snapshot Testing** | Per-screen coverage, light/dark mode, Dynamic Type sizes, device variants, mock Store |
| **Maintainability** | Function/file length, force unwrap, magic numbers, `TODO` ticket references |
| **Security** | No secrets in source, Keychain for sensitive storage, HTTPS only |
| **PR Hygiene** | PR size limit, branch naming, description, no merge commits, comment quality |

## When to Use

- Before opening a PR that adds or changes a `Reducer`, `Store`, `Effect`, or `@Dependency`
- When a new feature screen is added using TCA
- When a PR mixes side effects with state mutations
- When `@Dependency` injection is new or refactored

**Not this skill:**
- MVVM `ObservableObject` / `@Observable` codebase → use `swift-mvvm-code-review`
- VIPER modules → use `swift-viper-code-review`

## Invoke

```
/swift-tca-code-review Sources/Features/Cart/CartFeature.swift
/swift-tca-code-review PR #247
/swift-tca-code-review Sources/Features/Auth/
"Review my TCA changes before I open the PR."
```

If no input given, the skill scans `git diff --name-only HEAD~1 HEAD` for changed Swift files.

## TCA-Specific Checks (Examples)

```swift
// TCA-002 CRITICAL — Side effects inside State
// ❌ Bad: network call inside computed property on State
var displayName: String {
    UserDefaults.standard.string(forKey: "name") ?? ""
}

// TCA-008 CRITICAL — Store captured in closure (retain cycle)
// ❌ Bad
DispatchQueue.main.async { store.send(.done) }
// ✅ Fix: use Effect.run
return .run { send in await send(.done) }

// TCA-004 HIGH — Singleton instead of @Dependency
// ❌ Bad
let user = await NetworkManager.shared.fetchUser()
// ✅ Fix
@Dependency(\.userClient) var userClient
let user = try await userClient.fetch()

// TCA-006 HIGH — Action naming (noun.verb)
// ❌ Bad: verbNoun
case fetchUserCompleted
// ✅ Good: noun.verb
case user(.fetchCompleted)
```

## Merge Signal

| Signal | Condition |
|---|---|
| 🔴 Not ready | Any `CRITICAL` or 3+ `HIGH` |
| 🟡 Minor fixes | 1–2 `HIGH` or 4+ `MEDIUM` |
| 🟢 Ready | Only `LOW` / `SUGGESTION` |

## Context Files Read

The skill reads these in priority order before reviewing:

```
CLAUDE.md              ← project conventions (highest priority)
.swiftlint.yml         ← lint rule overrides
Package.swift          ← TCA version, Firebase, other deps
Podfile.lock           ← alternative version source
.github/workflows/     ← CI gate awareness
```

## Files

```
swift-tca-code-review/
  SKILL.md            ← Agent-readable definition (primary)
  skill-config.yaml   ← Full YAML config with all check IDs
  rules/              ← Rule files (loaded by skill-config.yaml)
  README.md           ← This file
```
