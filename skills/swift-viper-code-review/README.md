# swift-viper-code-review

> Code review skill for iOS UIKit or SwiftUI projects using **VIPER** (View · Interactor · Presenter · Entity · Router).

---

## Layer Responsibilities

| Layer | Owns | Must NOT do |
|---|---|---|
| **View** | UI rendering, delegate user events to Presenter | Business logic, data access, navigation |
| **Interactor** | Business logic, use-case execution | UI imports, navigation, display formatting |
| **Presenter** | Format data for display, coordinate View ↔ Interactor | Direct data access, navigation, UIKit layout |
| **Entity** | Plain data structures | Logic, network calls, persistence |
| **Router** | Navigation, module assembly | Business logic, data fetching, UI layout |

## What It Reviews

| Dimension | Key Checks |
|---|---|
| **View Layer** | Renders only; no direct Interactor access; no navigation calls; holds Presenter via protocol |
| **Interactor Layer** | No UIKit/SwiftUI imports; output via protocol; `weak` output reference; unit testable in isolation |
| **Presenter Layer** | No data access; no UIKit layout; `weak var view`; delegates navigation to Router; unit testable |
| **Entity Layer** | Plain `struct`/`class`; no logic; no layer references; `Codable`/`Equatable` where appropriate |
| **Router Layer** | All navigation here; module assembly; `weak var viewController`; no business logic |
| **Module Assembly** | All 5 layers present; Builder wires protocols; no circular dependencies |
| **Accessibility** | Labels, roles, Dynamic Type, VoiceOver order (WCAG 2.1 AA) |
| **Firebase** | All Firebase calls in Interactor only; injected via protocol (no singleton access) |
| **Snapshot Testing** | Mock Presenter in View tests; light/dark mode; Dynamic Type sizes; device variants |
| **Maintainability** | Function/file length, force unwrap, magic numbers, `TODO` ticket references |
| **Security** | No secrets in source, Keychain for sensitive storage, HTTPS only |
| **PR Hygiene** | PR size limit, branch naming, description, no merge commits, comment quality |

## When to Use

- Before opening a PR that adds or changes a VIPER module
- When a new screen module is added (should have all 5 layers)
- When a PR adds navigation — verify it lives in Router
- When Interactor is suspected of doing UI work (or vice versa)
- When a new Firebase service call is added — confirm it lives in Interactor

**Not this skill:**
- TCA `Reducer` / `@Dependency` codebase → use `swift-tca-code-review`
- MVVM `ObservableObject` / `@Observable` codebase → use `swift-mvvm-code-review`

## Invoke

```
/swift-viper-code-review Sources/Modules/Login/
/swift-viper-code-review PR #89
/swift-viper-code-review Sources/Modules/Profile/ProfilePresenter.swift
"Review the Checkout VIPER module before merge."
```

If no input given, the skill scans `git diff --name-only HEAD~1 HEAD` for changed Swift files.

## VIPER-Specific Checks (Examples)

```swift
// VIEW-003 CRITICAL — View accessing Interactor directly
// ❌ Bad
class LoginViewController: UIViewController {
    var interactor: LoginInteractorProtocol?
    func loginTapped() { interactor?.login() }  // View should NOT know Interactor
}
// ✅ Fix: View → Presenter → Interactor
class LoginViewController: UIViewController {
    var presenter: LoginPresenterProtocol?
    func loginTapped() { presenter?.loginTapped() }
}

// INT-006 CRITICAL — Strong output reference causes retain cycle
// ❌ Bad
class LoginInteractor {
    var output: LoginInteractorOutputProtocol?  // strong
}
// ✅ Fix
class LoginInteractor {
    weak var output: LoginInteractorOutputProtocol?
}

// PRES-001 CRITICAL — Presenter making network/Firebase calls
// ❌ Bad
class LoginPresenter {
    func loginTapped() { Auth.auth().signIn(...) }  // must live in Interactor
}
// ✅ Fix
func loginTapped() { interactor?.login(email: email, password: password) }

// ROUT-003 CRITICAL — Router holds strong ViewController reference
// ❌ Bad
class LoginRouter { var viewController: UIViewController? }
// ✅ Fix
class LoginRouter { weak var viewController: UIViewController? }
```

## Module Completeness Check

The skill automatically verifies all 5 layers exist for each VIPER module in scope:

```
Login/
  LoginViewController.swift    ← View ✅
  LoginInteractor.swift         ← Interactor ✅
  LoginPresenter.swift          ← Presenter ✅
  LoginEntity.swift             ← Entity ✅
  LoginRouter.swift             ← Router ✅
  LoginBuilder.swift            ← Assembly ✅
```

Missing layers are flagged `HIGH` under `MOD-001`.

## Custom Naming Conventions

If your project uses non-standard names, add to `CLAUDE.md`:

```markdown
## VIPER Naming
- Router files are named *Wireframe.swift
- Entity files are named *DataModel.swift
```

The skill reads `CLAUDE.md` first and applies your conventions before flagging anything.

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
Package.swift          ← Firebase, other versions
Podfile.lock           ← alternative version source
.github/workflows/     ← CI gate awareness
```

## Files

```
swift-viper-code-review/
  SKILL.md            ← Agent-readable definition (primary)
  skill-config.yaml   ← Full YAML config with all check IDs
  rules/              ← Rule files (loaded by skill-config.yaml)
  README.md           ← This file
```
