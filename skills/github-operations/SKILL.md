---
name: github-operations
description: Use when any mobile development task needs GitHub via gh CLI — creating or merging PRs, posting inline review comments with suggestion blocks, checking CI status, downloading build artifacts (IPA/dSYM/snapshots), triggering workflows, managing releases, issues, branches, labels, and required status checks
---

# GitHub Operations

Reference skill for all `gh` CLI operations in mobile development workflows.
Import this skill whenever a task produces GitHub output or needs to query/mutate GitHub state.

---

## 1. Setup & Session Variables

```bash
# Authenticate (once per machine)
gh auth login

# Resolve repo and current PR commit — set at the start of every session
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
# → "acme/ios-app"

COMMIT=$(gh pr view {PR} --json headRefOid -q .headRefOid)
```

---

## 2. Pull Request — Create & Manage

### Create

```bash
# Interactive (uses PULL_REQUEST_TEMPLATE.md if present)
gh pr create

# Non-interactive
gh pr create \
  --title "feat: Add cart checkout [PROJ-123]" \
  --body "$(cat .github/PULL_REQUEST_TEMPLATE.md)" \
  --base main \
  --label "feature,ios" \
  --reviewer teammate1,teammate2 \
  --draft
```

### Inspect

```bash
# Summary view
gh pr view {PR}

# Full diff
gh pr diff {PR}

# Changed file list only
gh pr diff {PR} --name-only

# Metadata as JSON (title, body, labels, reviewers, CI status)
gh pr view {PR} --json title,body,headRefName,labels,reviewRequests,statusCheckRollup

# Check mergeability
gh pr view {PR} --json mergeable,mergeStateStatus
```

### Update

```bash
# Add / remove reviewers
gh pr edit {PR} --add-reviewer teammate1,teammate2
gh pr edit {PR} --remove-reviewer teammate1

# Add / remove labels
gh pr edit {PR} --add-label "ready-for-review,ios"
gh pr edit {PR} --remove-label "work-in-progress"

# Set milestone
gh pr edit {PR} --milestone "v2.1.0"

# Convert draft → ready
gh pr ready {PR}

# Mark ready → draft
gh pr edit {PR} --draft
```

### Merge

```bash
# Squash merge (preferred for feature branches)
gh pr merge {PR} --squash --delete-branch

# Rebase merge
gh pr merge {PR} --rebase --delete-branch

# Enable auto-merge (merges when all checks pass)
gh pr merge {PR} --squash --auto --delete-branch
```

### List & Filter

```bash
# Open PRs assigned to you
gh pr list --assignee "@me"

# PRs ready for review with a specific label
gh pr list --state open --label "ready-for-review"

# PRs touching a specific file
gh pr list --search "path:Sources/Features/Cart"
```

---

## 3. Code Review — Inline Comments & Verdicts

### Single inline comment

```bash
gh api repos/$REPO/pulls/{PR}/comments --method POST \
  -f commit_id="$COMMIT" \
  -f path="Sources/Features/HomeFeature.swift" \
  -F line=42 \
  -f body="**[CHECK-ID] SEVERITY** One-line finding description."
```

For a line range (e.g. lines 40–42): add `-F start_line=40`.

### Suggestion block — one-click apply

Place a `suggestion` fence in `body`. GitHub renders an **Apply suggestion** button;
the author applies the fix without opening an editor.

```bash
gh api repos/$REPO/pulls/{PR}/comments --method POST \
  -f commit_id="$COMMIT" \
  -f path="Sources/Features/HomeFeature.swift" \
  -F line=42 \
  -f body='**[CHECK-ID] SEVERITY** Short description.

```suggestion
// exact replacement for the flagged line(s)
let result = try await service.fetch()
```'
```

**Suggestion rules:**
- Replacement must cover exactly the line(s) in `line` / `start_line`
- Skip suggestion if the fix spans non-contiguous lines
- Skip suggestion if the fix touches a different file

### Batch review — multiple findings + verdict

```bash
gh api repos/$REPO/pulls/{PR}/reviews --method POST \
  -f commit_id="$COMMIT" \
  -f event="REQUEST_CHANGES" \
  -f body="## Code Review

🔴 Not ready to merge — see inline comments." \
  -f 'comments[][path]=Sources/HomeFeature.swift' \
  -F 'comments[][line]=87' \
  -f 'comments[][body]=**[TCA-002] CRITICAL** Side effect in Action.' \
  -f 'comments[][path]=Sources/CartFeature.swift' \
  -F 'comments[][line]=34' \
  -f 'comments[][body]=**[SEC-001] HIGH** Hardcoded API key.'
```

`event` values:

| Value | When to use |
|---|---|
| `REQUEST_CHANGES` | Any CRITICAL or HIGH finding |
| `COMMENT` | MEDIUM / LOW only — informational, does not block |
| `APPROVE` | No findings, ready to merge |

### Approve

```bash
gh pr review {PR} --approve --body "🟢 Ready to merge — no issues found."
```

### Re-request review after author updates

```bash
gh api repos/$REPO/pulls/{PR}/requested_reviewers --method POST \
  -f 'reviewers[]=teammate1'
```

### Resolve / dismiss stale review

```bash
gh api repos/$REPO/pulls/{PR}/reviews/{REVIEW_ID}/dismissals \
  --method PUT \
  -f message="Superseded by latest commit."
```

### Comment body format (for review skills)

```
**[CHECK-ID] SEVERITY** One-line summary.

<1–2 sentences on impact — omit if obvious>

```suggestion
// fix, if directly applicable
```
```

---

## 4. CI/CD — Workflows, Status & Artifacts

### Check PR status checks

```bash
# Summary of all checks on the PR
gh pr checks {PR}

# Watch checks update live
gh pr checks {PR} --watch
```

### List and inspect workflow runs

```bash
# Recent runs for a workflow
gh run list --workflow=pr-checks.yml --limit 10

# Runs on a specific branch
gh run list --branch feature/PROJ-123-cart --workflow=pr-checks.yml

# View run summary + job list
gh run view {RUN_ID}

# Stream logs for a specific job
gh run view {RUN_ID} --job "snapshot-tests" --log
```

### Re-run failures

```bash
# Re-run only failed jobs (saves CI minutes)
gh run rerun {RUN_ID} --failed

# Re-run entire workflow
gh run rerun {RUN_ID}
```

### Trigger workflow manually

```bash
# Trigger release build
gh workflow run release.yml \
  -f version="2.1.0" \
  -f environment="production"

# Trigger TestFlight upload
gh workflow run upload-testflight.yml \
  -f build_number="$(date +%s)"

# Trigger snapshot baseline update
gh workflow run update-snapshots.yml \
  -f branch="$(git branch --show-current)"
```

### Download artifacts

```bash
# List available artifacts for a run
gh run download {RUN_ID} --dry-run

# Download specific artifact (snapshot failures, IPA, dSYM, test results)
gh run download {RUN_ID} --name "snapshot-failures" --dir ./failures
gh run download {RUN_ID} --name "MyApp.ipa"         --dir ./build
gh run download {RUN_ID} --name "dSYMs"             --dir ./dsyms
gh run download {RUN_ID} --name "test-results"      --dir ./test-results

# Download all artifacts from latest run of a workflow
gh run download \
  $(gh run list --workflow=pr-checks.yml --limit 1 --json databaseId -q '.[0].databaseId')
```

### Cancel a running workflow

```bash
gh run cancel {RUN_ID}
```

---

## 5. Issues

### Create

```bash
# Bug from failing test
gh issue create \
  --title "Snapshot failure: HomeScreen dark mode [PROJ-456]" \
  --body "Snapshot diverged after NavigationStack update." \
  --label "bug,snapshot,ios" \
  --assignee "@me"

# Improvement from review finding
gh issue create \
  --title "Refactor: Extract CartViewModel [PROJ-457]" \
  --label "refactor,ios"
```

### Inspect & update

```bash
# View issue
gh issue view {ISSUE}

# Add comment
gh issue comment {ISSUE} --body "Reproduced on iOS 17.2 simulator."

# Add label
gh issue edit {ISSUE} --add-label "confirmed"

# Assign
gh issue edit {ISSUE} --add-assignee teammate1
```

### Close

```bash
# Close with comment
gh issue close {ISSUE} --comment "Fixed in PR #247."

# Close as not-planned
gh issue close {ISSUE} --reason "not planned"
```

> To auto-close via PR: include `Closes #ISSUE` in the PR body — GitHub links and closes on merge.

---

## 6. Releases & Tags

### Create release

```bash
# Production release with changelog
gh release create v2.1.0 \
  --title "Version 2.1.0" \
  --notes-file CHANGELOG.md \
  --target main

# Pre-release (e.g., beta / TestFlight cut)
gh release create v2.1.0-beta.1 \
  --title "Beta 2.1.0 Build 1" \
  --prerelease \
  --notes "Internal TestFlight build."
```

### Upload mobile artifacts to release

```bash
gh release upload v2.1.0 \
  ./build/MyApp.ipa \
  ./build/MyApp.dSYM.zip \
  ./build/MyApp.xcarchive.zip
```

### Inspect releases

```bash
gh release list
gh release view v2.1.0
```

### Delete pre-release after promoting

```bash
gh release delete v2.1.0-beta.1 --yes
```

---

## 7. Branch Management

When a branch creation is requested, **always ask the user these two questions first**
before generating any command:

```
1. What type of branch do you need?
   [1] feature   — new functionality
   [2] bugfix    — non-critical bug fix (ships in next release)
   [3] hotfix    — critical production fix (ships immediately)
   [4] release   — release preparation branch
   [5] chore     — refactor, dependency update, or housekeeping

2. Do you have a ticket / issue number?  (e.g. PROJ-123 or GitHub issue #45)
   If yes → include in branch name.
   If no  → use a short descriptive slug.
```

Then generate the commands for the chosen type below.

---

### Feature Branch

Use when: adding new functionality or a complete new screen/module.
Base: `develop` (GitFlow) or `main` (trunk-based).

```bash
# Naming: feature/TICKET-short-description
BRANCH="feature/PROJ-123-cart-checkout"
BASE="develop"   # or main

# From a GitHub issue (links branch to issue automatically)
gh issue develop {ISSUE} --name "$BRANCH" --base $BASE

# OR from HEAD of base branch
git checkout $BASE && git pull origin $BASE
git checkout -b "$BRANCH"
git push -u origin "$BRANCH"

# Open draft PR immediately (good practice — visible to team)
gh pr create \
  --title "feat: [PROJ-123] Cart checkout flow" \
  --body "Closes #ISSUE" \
  --base $BASE \
  --head "$BRANCH" \
  --label "feature,ios" \
  --draft
```

**Naming pattern:** `feature/<TICKET>-<short-description>`
**PR label:** `feature`
**Merges into:** `develop` or `main`

---

### Bugfix Branch

Use when: fixing a non-critical bug that ships in the next planned release.
Base: `develop` (GitFlow) or `main` (trunk-based).

```bash
# Naming: bugfix/TICKET-short-description
BRANCH="bugfix/PROJ-456-login-crash-empty-email"
BASE="develop"

git checkout $BASE && git pull origin $BASE
git checkout -b "$BRANCH"
git push -u origin "$BRANCH"

# From a GitHub issue
gh issue develop {ISSUE} --name "$BRANCH" --base $BASE

# Create PR and link to bug issue
gh pr create \
  --title "fix: [PROJ-456] Crash on login with empty email" \
  --body "Fixes #ISSUE" \
  --base $BASE \
  --head "$BRANCH" \
  --label "bug,ios"
```

**Naming pattern:** `bugfix/<TICKET>-<short-description>`
**PR label:** `bug`
**Merges into:** `develop` or `main`

---

### Hotfix Branch

Use when: a critical bug is live in production and needs an immediate out-of-cycle fix.
Base: **always `main`** — never develop.

```bash
# Naming: hotfix/x.y.z  OR  hotfix/TICKET-description
BRANCH="hotfix/2.0.1"          # version bump hotfix
# or
BRANCH="hotfix/PROJ-789-payment-timeout"   # issue-linked hotfix
BASE="main"

git checkout main && git pull origin main
git checkout -b "$BRANCH"
git push -u origin "$BRANCH"

# Create PR targeting main — mark as high priority
gh pr create \
  --title "hotfix: [PROJ-789] Payment timeout on slow network" \
  --body "$(cat <<'EOF'
## Hotfix — CRITICAL

**Issue:** #ISSUE
**Impact:** Payment flow fails for users on connections < 10 Mbps.
**Fix:** Increased URLSession timeout from 10s to 30s.

## Test Plan
- [ ] Tested on device with network throttling (10 Mbps, 5 Mbps)
- [ ] Verified no regression on normal connections
EOF
)" \
  --base main \
  --head "$BRANCH" \
  --label "hotfix,critical,ios" \
  --reviewer release-manager

# After merge to main — also merge back to develop (GitFlow)
git checkout develop && git pull origin develop
git merge --no-ff main -m "chore: sync hotfix back to develop"
git push origin develop
```

**Naming pattern:** `hotfix/<version>` or `hotfix/<TICKET>-<description>`
**PR label:** `hotfix`, `critical`
**Merges into:** `main` (and back-merged to `develop` in GitFlow)
**⚠️ Always bump the patch version** in the same commit (e.g. 2.0.0 → 2.0.1).

---

### Release Branch

Use when: cutting a release candidate from develop or main.
See `mobile-release-automation` skill for the full release workflow.

```bash
# Naming: release/x.y.z
BRANCH="release/2.1.0"
BASE="develop"   # or main

git checkout $BASE && git pull origin $BASE
git checkout -b "$BRANCH"
git push -u origin "$BRANCH"

gh pr create \
  --title "Release 2.1.0" \
  --base main \
  --head "$BRANCH" \
  --label "release" \
  --reviewer release-manager1,release-manager2
```

**Naming pattern:** `release/<version>`
**PR label:** `release`
**Merges into:** `main`

---

### Chore Branch

Use when: refactoring, dependency updates, CI changes, or housekeeping with no user-facing change.

```bash
# Naming: chore/short-description  or  chore/TICKET-description
BRANCH="chore/update-firebase-sdk-11"
BASE="develop"   # or main

git checkout $BASE && git pull origin $BASE
git checkout -b "$BRANCH"
git push -u origin "$BRANCH"

gh pr create \
  --title "chore: Update Firebase SDK to v11" \
  --base $BASE \
  --head "$BRANCH" \
  --label "chore,dependencies"
```

**Naming pattern:** `chore/<description>`
**PR label:** `chore`
**Merges into:** `develop` or `main`

---

### List, Inspect & Clean Up

```bash
# List all remote branches
gh api repos/$REPO/branches --jq '.[].name'

# List only feature/bugfix/hotfix/release branches
git branch -r | grep -E "feature/|bugfix/|hotfix/|release/|chore/"

# Check branch protection rules
gh api repos/$REPO/branches/main/protection

# Delete remote branch after PR is merged
gh api repos/$REPO/git/refs/heads/{BRANCH_NAME} --method DELETE

# Delete local branch + remote together
git branch -d {BRANCH_NAME}
git push origin --delete {BRANCH_NAME}

# Prune stale remote-tracking refs
git fetch --prune
```

---

### Branch Naming Quick Reference

| Type    | Pattern                              | Base      | Label              |
|---------|--------------------------------------|-----------|--------------------|
| feature | `feature/<TICKET>-<description>`     | develop   | `feature`          |
| bugfix  | `bugfix/<TICKET>-<description>`      | develop   | `bug`              |
| hotfix  | `hotfix/<version>` or `hotfix/<TICKET>-<desc>` | main | `hotfix,critical` |
| release | `release/<version>`                  | develop   | `release`          |
| chore   | `chore/<description>`                | develop   | `chore`            |

---

## 8. Labels & Milestones

### Manage labels

```bash
# List all labels
gh label list

# Create a new label
gh label create "snapshot-failure" --color "d93f0b" --description "Snapshot test diverged"

# Add label to PR or issue
gh pr    edit {PR}    --add-label "snapshot-failure"
gh issue edit {ISSUE} --add-label "snapshot-failure"
```

### Manage milestones

```bash
# List milestones
gh api repos/$REPO/milestones --jq '.[] | {number, title, open_issues}'

# Create milestone
gh api repos/$REPO/milestones --method POST \
  -f title="v2.1.0" \
  -f due_on="2025-06-01T00:00:00Z"

# Assign PR to milestone
gh pr edit {PR} --milestone "v2.1.0"
```

---

## 9. Mobile-Specific Workflows

### Snapshot test failures

```bash
# Download failure diffs from CI artifact
gh run download {RUN_ID} --name "snapshot-failures" --dir ./snapshot-failures

# View which snapshot tests failed
gh run view {RUN_ID} --job "snapshot-tests" --log | grep "failed\|❌"

# Trigger baseline update (never run locally — let CI regenerate)
gh workflow run update-snapshots.yml -f branch="$(git branch --show-current)"
```

### Build artifact inspection

```bash
# Download IPA for local device install
gh run download {RUN_ID} --name "MyApp-Debug.ipa" --dir ./build

# Download dSYM for crash symbolication
gh run download {RUN_ID} --name "dSYMs" --dir ./dsyms
xcrun dsymutil ./dsyms/MyApp.dSYM
```

### SwiftLint results

```bash
# View lint job output
gh run view {RUN_ID} --job "swiftlint" --log

# Check if lint is a required status check
gh api repos/$REPO/branches/main/protection \
  --jq '.required_status_checks.contexts[]'
```

### Code coverage

```bash
# Download coverage report artifact
gh run download {RUN_ID} --name "coverage-report" --dir ./coverage

# Post coverage summary as PR comment
gh pr comment {PR} --body "$(cat ./coverage/summary.md)"
```

### Required status checks (gate verification)

```bash
# List required checks on main
gh api repos/$REPO/branches/main/protection \
  --jq '.required_status_checks.contexts[]'

# Check if all required checks passed on a PR
gh pr checks {PR} --required
```
