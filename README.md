# skill-book

A curated collection of production-ready AI skills for Claude Code — built for real iOS engineering teams.

---

## Skills

### iOS Architecture Code Review

| Skill | Architecture | When to Use |
|---|---|---|
| [swift-tca-code-review](skills/swift-tca-code-review/) | The Composable Architecture (TCA) | Reducers, Effects, @Dependency, TCA stores |
| [swift-mvvm-code-review](skills/swift-mvvm-code-review/) | MVVM | ObservableObject, @Observable, Combine ViewModels |
| [swift-viper-code-review](skills/swift-viper-code-review/) | VIPER | View · Interactor · Presenter · Entity · Router modules |

All three skills share common checks for **accessibility**, **Firebase**, **snapshot testing**, **security**, **performance**, and **GitHub PR hygiene** — with architecture-specific checks unique to each.

### Mobile Release

| Skill | When to Use |
|---|---|
| [mobile-release-automation](skills/mobile-release-automation/) | Cutting a release: readiness checks, version bump, changelog, PR, CI, TestFlight, tagging |

### GitHub Operations

| Skill | When to Use |
|---|---|
| [github-operations](skills/github-operations/) | Branch creation, PR management, inline review comments, CI/CD monitoring, releases — all `gh` CLI workflows for mobile development |

---

## How to Install (Claude Code)

Use the included install script — it copies skills into `~/.claude/skills/` where Claude Code picks them up automatically.

```bash
# Install all skills
./install.sh

# Install a single skill
./install.sh swift-tca-code-review

# List what's installed
./install.sh --list

# Remove all installed skills
./install.sh --remove
```

---

## How to Use

After installing, invoke skills by name in Claude Code:

```bash
# TCA code review
/swift-tca-code-review Sources/Features/Cart/CartFeature.swift
/swift-tca-code-review PR #247

# MVVM code review
/swift-mvvm-code-review Sources/Features/Profile/ProfileViewModel.swift
/swift-mvvm-code-review PR #134

# VIPER code review
/swift-viper-code-review Sources/Modules/Login/
/swift-viper-code-review PR #89

# Release automation
/mobile-release-automation 2.1.0

# GitHub operations (branch, PR, CI)
/github-operations
```

Or natural language:
```
"Review my TCA changes before I open the PR."
"Check the Dashboard MVVM module for architecture issues."
"Prepare the 2.1.0 release from develop."
```

---

## Skill Structure

Each skill follows the [agentskills.io specification](https://agentskills.io/specification):

```
skills/
  skill-name/
    SKILL.md            ← Agent-readable definition (primary)
    skill-config.yaml   ← Full YAML configuration with all checks (optional)
    rules/              ← Rule files loaded by skill-config.yaml (optional)
```

---

## Architecture Decision Guide

| Your codebase uses... | Use this skill |
|---|---|
| `@Reducer`, `Store`, `Effect`, `@Dependency` | `swift-tca-code-review` |
| `ObservableObject`, `@Published`, `@Observable` | `swift-mvvm-code-review` |
| `*Interactor`, `*Presenter`, `*Router`, `*Wireframe` | `swift-viper-code-review` |
| Mix of TCA + MVVM | Run both; each checks its own files |

---

## Contributing

1. Fork this repository
2. Create a skill directory under `skills/your-skill-name/`
3. Add `SKILL.md` with valid YAML frontmatter (`name`, `description` starting with `"Use when..."`)
4. Update the Skills table in this README
5. Open a PR

**Requirements for new skills:**
- `description` starts with `"Use when..."` — triggering conditions only, no workflow summary
- Review/analysis skills must be strictly read-only (no file modification)
- All guardrails explicitly stated in the skill

---

## License

MIT — see [LICENSE](LICENSE)
