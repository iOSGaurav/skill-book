# swift-viper-code-review

> Code review skill for iOS projects using **VIPER** (View · Interactor · Presenter · Entity · Router).

**Version:** 1.0.0 | **Architecture:** VIPER

---

## Layer Responsibilities (Quick Reference)

| Layer | Owns | Must NOT do |
|---|---|---|
| **View** | UI rendering, delegate events | Business logic, data access, navigation |
| **Interactor** | Business logic, use-case execution | UI imports, navigation, display formatting |
| **Presenter** | Format data for display, coordinate flow | Direct data access, navigation, UI layout |
| **Entity** | Plain data structures | Logic, network, persistence |
| **Router** | Navigation, module assembly | Business logic, data fetching |

## What It Reviews

| Dimension | Key Checks |
|---|---|
| **View Layer** | View renders only; no direct Interactor access; no navigation calls |
| **Interactor Layer** | No UIKit/SwiftUI; output via protocol; unit testable in isolation |
| **Presenter Layer** | No data access; no UIKit layout; weak View reference; unit testable |
| **Entity Layer** | Plain structs/classes; no logic; no layer references |
| **Router Layer** | All navigation; module assembly; weak ViewController reference |
| **Module Assembly** | All 5 layers present; no circular dependencies; correct wiring |
| **Accessibility** | Labels, roles, Dynamic Type, VoiceOver (WCAG 2.1 AA) |
| **Firebase** | Firebase only in Interactor; injected via protocol (no singleton) |
| **Snapshot Testing** | Mock Presenter in View tests; light/dark; device variants |
| **Maintainability** | Function/file length, force unwrap, magic numbers |
| **Security** | Secrets in source, Keychain vs UserDefaults, HTTPS |
| **PR Hygiene** | PR size, branch naming, description, merge commits |

## Invoke

```
/swift-viper-code-review Sources/Modules/Login/
/swift-viper-code-review PR #89
/swift-viper-code-review Sources/Modules/Profile/ProfilePresenter.swift
"Review the Checkout VIPER module before merge."
```

## VIPER-Specific Checks

```swift
// VIEW-003 CRITICAL — View accessing Interactor directly
// ❌ Bad
class LoginViewController: UIViewController {
    var interactor: LoginInteractorProtocol?  // View should NOT know Interactor
    func loginTapped() { interactor?.login() }
}
// ✅ Fix: View → Presenter → Interactor
class LoginViewController: UIViewController {
    var presenter: LoginPresenterProtocol?
    func loginTapped() { presenter?.loginTapped() }
}

// INT-006 CRITICAL — Strong output reference (retain cycle)
// ❌ Bad
class LoginInteractor: LoginInteractorProtocol {
    var output: LoginInteractorOutputProtocol?  // strong — retain cycle
}
// ✅ Fix
class LoginInteractor: LoginInteractorProtocol {
    weak var output: LoginInteractorOutputProtocol?
}

// PRES-001 CRITICAL — Presenter making data calls
// ❌ Bad
class LoginPresenter {
    func loginTapped() {
        Auth.auth().signIn(...)  // Presenter should NOT touch Firebase
    }
}
// ✅ Fix: delegate to Interactor
func loginTapped() { interactor?.login(email: email, password: password) }

// FB-001 CRITICAL — Firebase in View (not Interactor)
// ❌ Bad: Firestore call in ViewController
Firestore.firestore().collection("users").getDocuments { ... }
// ✅ Fix: all Firebase calls live in Interactor only
```

## Module Completeness Check

The skill automatically checks that all 5 layers exist for every VIPER module in scope:

```
Checkout/
  CheckoutViewController.swift   ← View ✅
  CheckoutInteractor.swift        ← Interactor ✅
  CheckoutPresenter.swift         ← Presenter ✅
  CheckoutEntity.swift            ← Entity ✅
  CheckoutRouter.swift            ← Router ✅
  CheckoutBuilder.swift           ← Assembly ✅
```

Missing layers are flagged as `HIGH` under `MOD-001`.

## Naming Convention Support

If your project uses non-standard names, add to `CLAUDE.md`:
```markdown
## VIPER Naming
- Router files are named *Wireframe.swift
- Entity files are named *DataModel.swift
```
The skill reads `CLAUDE.md` first and applies your conventions.

## Merge Signal

| Signal | Condition |
|---|---|
| 🔴 Not ready | Any CRITICAL or 3+ HIGH |
| 🟡 Minor fixes | 1–2 HIGH or 4+ MEDIUM |
| 🟢 Ready | Only LOW / SUGGESTION |

## Files

```
swift-viper-code-review/
  SKILL.md            ← Agent-readable (primary)
  skill-config.yaml   ← Full YAML config
  README.md           ← This file
```
