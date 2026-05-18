# github-operations

> Shared `gh` CLI reference skill for all GitHub workflows in mobile development.

Used by `swift-tca-code-review`, `swift-mvvm-code-review`, `swift-viper-code-review`, and other skills as the single source of truth for GitHub command templates.

---

## What It Covers

| Section | Capabilities |
|---|---|
| **Branch Management** | Interactive branch type selection (feature / bugfix / hotfix / release / chore), naming conventions, base branch rules |
| **Pull Requests** | Create, inspect, update, merge, list, filter |
| **Code Review** | Inline line comments, suggestion blocks (one-click apply), batch reviews with verdict, approve, re-request, dismiss |
| **CI/CD** | Check PR status checks, list/inspect runs, re-run failures, trigger workflows, download artifacts, cancel runs |
| **Issues** | Create, inspect, update, close |
| **Releases & Tags** | Create annotated tags, upload IPA/dSYM artifacts, inspect and manage releases |
| **Labels & Milestones** | Create labels, assign to PRs/issues, create and close milestones |

---

## Invoke

```
/github-operations
"Create a feature branch for the login screen redesign."
"Post a review comment on PR #89 at line 42 with a fix suggestion."
"Watch the CI run on PR #134."
"Create a GitHub release for v2.1.0 with the IPA attached."
```

---

## Branch Management — Interactive Flow

When asked to create a branch, this skill **always asks two questions first**:

1. **What type of branch do you need?**
   - `feature` — new functionality → bases from `develop`
   - `bugfix` — non-critical fix → bases from `develop`
   - `hotfix` — critical production fix → **always bases from `main`**
   - `release` — release preparation → bases from `develop`
   - `chore` — refactor, dependency update, housekeeping → bases from `develop`

2. **Do you have a ticket / issue number?**

Branch naming follows:

| Type | Pattern | Example |
|---|---|---|
| feature | `feature/<TICKET>-<description>` | `feature/AUTH-42-biometric-login` |
| bugfix | `bugfix/<TICKET>-<description>` | `bugfix/PROJ-18-crash-on-logout` |
| hotfix | `hotfix/<version>` or `hotfix/<TICKET>` | `hotfix/2.1.1` |
| release | `release/<version>` | `release/2.2.0` |
| chore | `chore/<description>` | `chore/update-firebase-sdk` |

> **Hotfix note:** Always bases from `main`. After merge to `main`, a back-merge to `develop` is included automatically.

---

## Inline Code Review Comments

Post a comment on a specific line of a PR diff:

```bash
gh api repos/{OWNER}/{REPO}/pulls/{PR}/comments \
  --method POST \
  --field body="**Finding:** MVVM-005 — `@Published` mutated off main thread.

\`\`\`suggestion
@MainActor func loadUsers() async {
    self.users = await fetch()
}
\`\`\`" \
  --field commit_id="$(gh pr view {PR} --json headRefOid -q .headRefOid)" \
  --field path="Sources/Features/Login/LoginViewModel.swift" \
  --field line=42 \
  --field side="RIGHT"
```

Suggestion blocks let reviewers apply the fix directly from the GitHub UI with one click.

---

## Batch Review with Verdict

Submit multiple findings in one review and set the merge verdict:

```bash
gh api repos/{OWNER}/{REPO}/pulls/{PR}/reviews \
  --method POST \
  --field event="REQUEST_CHANGES" \
  --field body="Code review complete — 1 CRITICAL finding." \
  --field "comments[][path]"="Sources/Features/Login/LoginViewModel.swift" \
  --field "comments[][line]"=42 \
  --field "comments[][body]"="MVVM-005 CRITICAL: see suggestion above."
```

`event` values: `APPROVE` · `REQUEST_CHANGES` · `COMMENT`

---

## CI/CD Quick Reference

```bash
# Watch all checks on a PR (blocks until complete)
gh pr checks {PR} --watch

# View logs from a failing job
gh run view {RUN_ID} --job "unit-tests" --log | tail -100

# Re-run only failed jobs
gh run rerun {RUN_ID} --failed

# Trigger a workflow manually
gh workflow run release-build.yml -f version="2.1.0" -f environment="production"

# Download build artifacts (IPA, dSYM, snapshots)
gh run download {RUN_ID} --name "MyApp-Release.ipa" --dir ./artifacts
```

---

## GitHub Release with Artifacts

```bash
gh release create "v2.1.0" \
  --title "Version 2.1.0" \
  --notes-file CHANGELOG.md \
  --target main \
  ./artifacts/MyApp-Release.ipa \
  ./artifacts/MyApp.dSYM.zip
```

---

## Guardrails

- **Never force-push to `main`** without explicit user confirmation
- **Never merge a PR with failing required checks**
- **Confirm before any tag push** — tags are permanent
- **Hotfix base branch is always `main`** — never `develop`

---

## Files

```
github-operations/
  SKILL.md    ← Agent-readable definition (primary)
  README.md   ← This file
```
