# swift-tca-code-review

> Code review skill for iOS SwiftUI projects using **The Composable Architecture (TCA)**.

**Version:** 2.0.0 | **Architecture:** TCA

---

## What It Reviews

| Dimension | Key Checks |
|---|---|
| **TCA Architecture** | Reducer composition, Effect types, @Dependency, Action naming (noun.verb), TestStore, retain cycles |
| **SwiftUI Performance** | body purity, ForEach id stability, @StateObject ownership, NavigationStack |
| **Accessibility** | Labels, roles, Dynamic Type, VoiceOver order (WCAG 2.1 AA) |
| **Firebase** | Query limits, error handling, auth observation, type-safe decoding |
| **Snapshot Testing** | Per-screen coverage, light/dark, device variants, precision thresholds |
| **Maintainability** | Function/file length, force unwrap, magic numbers |
| **Security** | Secrets in source, Keychain vs UserDefaults, HTTPS |
| **PR Hygiene** | PR size, branch naming, description, merge commits |

## Invoke

```
/swift-tca-code-review Sources/Features/Cart/CartFeature.swift
/swift-tca-code-review PR #247
/swift-tca-code-review Sources/Features/Auth/
"Review my TCA changes before I open the PR."
```

## TCA-Specific Checks

```swift
// TCA-002 CRITICAL — No side effects in State
// ❌ Bad: network call inside computed property on State
var displayName: String {
    UserDefaults.standard.string(forKey: "name") ?? ""
}

// TCA-008 CRITICAL — Store captured in closure
// ❌ Bad
DispatchQueue.main.async { store.send(.done) }

// ✅ Fix: use Effect.run
return .run { send in await send(.done) }

// TCA-004 HIGH — @Dependency, not singletons
// ❌ Bad
let user = await NetworkManager.shared.fetchUser()

// ✅ Fix
@Dependency(\.userClient) var userClient
let user = try await userClient.fetch()
```

## Merge Signal

| Signal | Condition |
|---|---|
| 🔴 Not ready | Any CRITICAL or 3+ HIGH |
| 🟡 Minor fixes | 1–2 HIGH or 4+ MEDIUM |
| 🟢 Ready | Only LOW / SUGGESTION |

## Files

```
swift-tca-code-review/
  SKILL.md            ← Agent-readable (primary)
  skill-config.yaml   ← Full YAML config
  README.md           ← This file
```
