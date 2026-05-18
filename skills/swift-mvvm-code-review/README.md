# swift-mvvm-code-review

> Code review skill for iOS SwiftUI projects using **MVVM** (`ObservableObject` / `@Observable` / Combine).

**Version:** 1.0.0 | **Architecture:** MVVM

---

## What It Reviews

| Dimension | Key Checks |
|---|---|
| **MVVM Architecture** | ViewModel purity, View/ViewModel separation, threading safety, protocol testability |
| **SwiftUI Bindings** | @StateObject vs @ObservedObject ownership, @EnvironmentObject scope, @Observable fine-grained observation |
| **Accessibility** | Labels, roles, Dynamic Type, VoiceOver order (WCAG 2.1 AA) |
| **Firebase** | Firebase calls in ViewModel (not View body), query limits, error handling |
| **Snapshot Testing** | Per-screen coverage, mock ViewModel in tests, light/dark, device variants |
| **Maintainability** | Function/file length, force unwrap, magic numbers |
| **Security** | Secrets in source, Keychain vs UserDefaults, HTTPS |
| **PR Hygiene** | PR size, branch naming, description, merge commits |

## MVVM Variants Supported

| Variant | Detection | Notes |
|---|---|---|
| Classic | `class X: ObservableObject` + `@Published` | iOS 13+ |
| Observation | `@Observable class X` | iOS 17+ |
| Combine | `ObservableObject` + `Publisher` chains | Different threading model |

## Invoke

```
/swift-mvvm-code-review Sources/Features/Profile/ProfileViewModel.swift
/swift-mvvm-code-review PR #134
/swift-mvvm-code-review Sources/Features/Dashboard/
"Review the LoginViewModel and LoginView before merge."
```

## MVVM-Specific Checks

```swift
// MVVM-005 CRITICAL — @Published mutation on background thread
// ❌ Bad
DispatchQueue.global().async {
    self.users = result  // crashes: @Published mutation off main thread
}

// ✅ Fix: mark method @MainActor
@MainActor
func loadUsers() async { self.users = await fetch() }

// MVVM-009 CRITICAL — ViewModel holds strong View reference
// ❌ Bad
class UserViewModel: ObservableObject {
    var view: UserView  // retain cycle
}

// MVVM-007 HIGH — @Observable vs @Published confusion
// ❌ Bad
@Observable class ProfileViewModel: ObservableObject {
    @Published var name: String = ""  // @Published is redundant with @Observable
}

// ✅ Fix
@Observable class ProfileViewModel {
    var name: String = ""
}
```

## Merge Signal

| Signal | Condition |
|---|---|
| 🔴 Not ready | Any CRITICAL or 3+ HIGH |
| 🟡 Minor fixes | 1–2 HIGH or 4+ MEDIUM |
| 🟢 Ready | Only LOW / SUGGESTION |

## Files

```
swift-mvvm-code-review/
  SKILL.md            ← Agent-readable (primary)
  skill-config.yaml   ← Full YAML config
  README.md           ← This file
```
