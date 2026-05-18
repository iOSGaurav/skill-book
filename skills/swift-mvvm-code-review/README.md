# swift-mvvm-code-review

> Code review skill for iOS SwiftUI projects using **MVVM** (`ObservableObject` / `@Observable` / Combine).

---

## What It Reviews

| Dimension | Key Checks |
|---|---|
| **MVVM Architecture** | ViewModel purity, View/ViewModel separation, threading safety, no UI imports in ViewModel, protocol testability |
| **SwiftUI Bindings & Performance** | `@StateObject` vs `@ObservedObject` ownership, `@EnvironmentObject` scope, `body` purity, `ForEach` id stability, `NavigationStack` |
| **Accessibility** | Labels, roles, Dynamic Type, VoiceOver order (WCAG 2.1 AA) |
| **Firebase** | Firebase calls in ViewModel only (not View body); query limits; type-safe decoding; error in `@Published var error` |
| **Snapshot Testing** | Per-screen coverage, mock ViewModel in tests, light/dark mode, Dynamic Type sizes, device variants |
| **Maintainability** | Function/file length, force unwrap, magic numbers, `TODO` ticket references |
| **Security** | No secrets in source, Keychain for sensitive storage, HTTPS only |
| **PR Hygiene** | PR size limit, branch naming, description, no merge commits, comment quality |

## MVVM Variants Supported

| Variant | Detection | Notes |
|---|---|---|
| Classic | `class X: ObservableObject` + `@Published` | iOS 13+ |
| Observation | `@Observable class X` | iOS 17+; `@Published` is redundant — flagged |
| Combine | `ObservableObject` + `Publisher` chains | Different threading model; `AnyCancellable` lifecycle checked |
| Mixed | Both variants in same project | Each file reviewed by its own variant rules |

## When to Use

- Before opening a PR that adds or changes a ViewModel
- After adding `@Published` properties or `@Observable` conformance
- When a PR mixes View logic with business logic
- When a ViewModel directly accesses Firebase, network, or persistence

**Not this skill:**
- TCA `Reducer` / `@Dependency` codebase → use `swift-tca-code-review`
- VIPER modules → use `swift-viper-code-review`

## Invoke

```
/swift-mvvm-code-review Sources/Features/Profile/ProfileViewModel.swift
/swift-mvvm-code-review PR #134
/swift-mvvm-code-review Sources/Features/Dashboard/
"Review the LoginViewModel and LoginView before merge."
```

If no input given, the skill scans `git diff --name-only HEAD~1 HEAD` for changed Swift files.

## MVVM-Specific Checks (Examples)

```swift
// MVVM-005 CRITICAL — @Published mutation on background thread
// ❌ Bad
DispatchQueue.global().async {
    self.users = result  // crash: @Published mutated off main thread
}
// ✅ Fix
@MainActor func loadUsers() async { self.users = await fetch() }

// MVVM-009 CRITICAL — ViewModel holds strong reference to View
// ❌ Bad
class UserViewModel: ObservableObject {
    var view: UserView  // retain cycle
}

// MVVM-007 HIGH — @Observable mixed with @Published
// ❌ Bad
@Observable class ProfileViewModel: ObservableObject {
    @Published var name: String = ""  // redundant — @Published is for ObservableObject only
}
// ✅ Fix
@Observable class ProfileViewModel {
    var name: String = ""
}

// PERF-001 HIGH — @StateObject vs @ObservedObject ownership
// ❌ Bad: @ObservedObject in root View (ViewModel recreated on every re-render)
struct RootView: View {
    @ObservedObject var viewModel = ProfileViewModel()
}
// ✅ Fix: @StateObject owns the instance
struct RootView: View {
    @StateObject var viewModel = ProfileViewModel()
}
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
Package.swift          ← Firebase, Combine, other versions
Podfile.lock           ← alternative version source
.github/workflows/     ← CI gate awareness
```

## Files

```
swift-mvvm-code-review/
  SKILL.md            ← Agent-readable definition (primary)
  skill-config.yaml   ← Full YAML config with all check IDs
  rules/              ← Rule files (loaded by skill-config.yaml)
  README.md           ← This file
```
