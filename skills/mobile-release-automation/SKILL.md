---
name: mobile-release-automation
description: Use when preparing, executing, or auditing a mobile app release — covers pre-release readiness checks, release branch creation, version and build number bumping, dependency audit, changelog and README updates, release PR creation, CI/CD monitoring, TestFlight distribution, GitHub release tagging, and post-release branch cleanup
---

# Mobile Release Automation

## Overview

End-to-end release orchestration for iOS (and cross-platform) mobile projects.
Runs pre-release gates, creates the release branch, bumps versions, audits dependencies,
updates documentation, posts the release PR, monitors CI, tags, and cleans up — in order.

**This skill orchestrates and reports. It proposes shell commands and `gh` operations
but confirms with the user before any destructive step (tag push, merge, upload).**

Reference: `../github-operations/SKILL.md` for all `gh` CLI command templates.

## When to Use

- When cutting a new production or beta release
- When auditing a release branch before it merges
- When onboarding the release process to a new project
- When a hotfix needs to be released outside the normal cycle

**Not this skill:**
- Code quality review → use `swift-tca-code-review` / `swift-mvvm-code-review` / `swift-viper-code-review`
- Snapshot baseline regeneration → use `gh workflow run update-snapshots.yml`

## Input

| Type | Example |
|---|---|
| Target version | `2.1.0` |
| Release type | `major` / `minor` / `patch` / `hotfix` |
| Source branch | `main` (default) or `develop` |
| PR number | `#312` (if release PR already exists) |
| Freeform | `"Prepare the 2.1.0 release from develop"` |

---

## Phase 0 — Pre-Release Readiness

Run all checks before creating the release branch. Abort and report failures if any
`CRITICAL` check fails.

- [ ] **REL-PRE-001** All PRs in the release milestone are merged — `CRITICAL`
- [ ] **REL-PRE-002** CI is green on the source branch — `CRITICAL`
- [ ] **REL-PRE-003** No open CRITICAL or HIGH bugs in the release milestone — `HIGH`
- [ ] **REL-PRE-004** Snapshot baselines are committed and up to date — `HIGH`
- [ ] **REL-PRE-005** No uncommitted or untracked changes on source branch — `HIGH`
- [ ] **REL-PRE-006** Source is `main` or `develop` — not a feature branch — `HIGH`
- [ ] **REL-PRE-007** Previous release branch fully merged (no orphaned `release/*` branches) — `MEDIUM`
- [ ] **REL-PRE-008** No concurrent App Store submission in review state — `MEDIUM`

```bash
# Readiness checks
gh pr list --state open --milestone "v{VERSION}"          # should return empty
gh run list --branch main --workflow=ci.yml --limit 1     # confirm latest = success
gh issue list --milestone "v{VERSION}" --label "bug" --state open
git status --porcelain                                     # should return empty
git branch -r | grep "release/"                           # should return empty
```

---

## Phase 1 — Release Branch

```bash
# Create from source branch
git checkout main && git pull origin main
git checkout -b release/{VERSION}
git push -u origin release/{VERSION}
```

Branch naming convention: `release/x.y.z` for production, `hotfix/x.y.z` for hotfixes.

---

## Phase 2 — Version & Build Number

### Detect current version locations

```bash
# Find all version declarations in the project
grep -r "MARKETING_VERSION\|CFBundleShortVersionString\|CFBundleVersion" \
  --include="*.plist" --include="*.xcconfig" --include="*.pbxproj" \
  --include="*.podspec" --include="Package.swift" .
```

### iOS — xcconfig / project settings (Xcode 13+)

```bash
# Bump marketing version in xcconfig
sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = {VERSION}/" \
  Configurations/Release.xcconfig

# Bump build number (use CI build number or timestamp)
BUILD=$(date +%Y%m%d%H%M)
sed -i '' "s/CURRENT_PROJECT_VERSION = .*/CURRENT_PROJECT_VERSION = $BUILD/" \
  Configurations/Release.xcconfig
```

### iOS — agvtool (legacy projects with Info.plist)

```bash
xcrun agvtool new-marketing-version {VERSION}
xcrun agvtool new-version -all {BUILD_NUMBER}
```

### iOS — direct Info.plist edit

```bash
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString {VERSION}" \
  {TARGET}/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion {BUILD_NUMBER}" \
  {TARGET}/Info.plist
```

### Swift Package (library releases)

```bash
# Update version in Package.swift or .podspec
sed -i '' 's/let version = ".*"/let version = "{VERSION}"/' Package.swift
sed -i '' "s/s.version.*=.*/s.version = '{VERSION}'/" MyLib.podspec
```

### Commit version bump

```bash
git add -A
git commit -m "chore: bump version to {VERSION} (build {BUILD_NUMBER})"
```

---

## Phase 3 — Dependency Audit

### Swift Package Manager

```bash
# List all pinned dependencies and their versions
cat Package.resolved | jq '.pins[] | {identity: .identity, version: .state.version}'

# Check for packages without pinned version (floating)
cat Package.resolved | jq '.pins[] | select(.state.version == null)'

# Check for local/development overrides (must be absent in release)
grep -r "path:" Package.swift
```

### CocoaPods

```bash
# List outdated pods (compare against Podfile.lock)
bundle exec pod outdated

# Verify Podfile.lock is committed
git status Podfile.lock    # must be clean

# Check for prerelease pod versions
grep -E "^\s+- .+: .+alpha|beta|rc" Podfile.lock
```

### Dependency rules summary

- [ ] **REL-DEP-001** No known CVE in pinned dependencies — `CRITICAL`
- [ ] **REL-DEP-002** No prerelease / beta / alpha dependency versions in production — `HIGH`
- [ ] **REL-DEP-003** No local `file://` or `path:` overrides in SPM — `CRITICAL`
- [ ] **REL-DEP-004** `Package.resolved` / `Podfile.lock` committed — `HIGH`
- [ ] **REL-DEP-005** No major-version-behind critical dependencies — `MEDIUM`
- [ ] **REL-DEP-006** All dependency licenses compatible with App Store distribution — `HIGH`
- [ ] **REL-DEP-007** No unused dependencies added in this release — `LOW`

---

## Phase 4 — Documentation Updates

### CHANGELOG.md

Add entry at the top following Keep a Changelog format:

```markdown
## [2.1.0] — 2025-05-17

### Added
- <feature description> (#PR_NUMBER)

### Changed
- <change description> (#PR_NUMBER)

### Fixed
- <bug description> (#PR_NUMBER, closes #ISSUE_NUMBER)

### Security
- <security fix description>
```

```bash
# Generate candidate entries from git log since last tag
git log $(git describe --tags --abbrev=0)..HEAD \
  --pretty=format:"- %s (%h)" \
  --no-merges | grep -v "^- chore\|^- ci\|^- test"
```

### README.md

```bash
# Find version references in README
grep -n "badge\|version\|install\|pod '\|\.package(" README.md

# Update SPM install snippet
sed -i '' 's/.exact(".*")/.exact("{VERSION}")/' README.md

# Update CocoaPods install snippet
sed -i '' "s/pod '.*', '~> .*/pod 'MyLib', '~> {VERSION}'/" README.md

# Update badge URL if using shields.io version badge
sed -i '' "s/badge\/version-.*-blue/badge\/version-{VERSION}-blue/" README.md
```

### Commit documentation changes

```bash
git add CHANGELOG.md README.md
git commit -m "docs: update CHANGELOG and README for {VERSION}"
```

### Documentation rules summary

- [ ] **REL-DOC-001** CHANGELOG.md has entry for new version with date — `HIGH`
- [ ] **REL-DOC-002** CHANGELOG entry includes all user-facing changes — `HIGH`
- [ ] **REL-DOC-003** Breaking changes explicitly marked — `CRITICAL`
- [ ] **REL-DOC-004** README install snippets match new version — `MEDIUM`
- [ ] **REL-DOC-005** No internal architecture details in release notes — `MEDIUM`
- [ ] **REL-DOC-006** CHANGELOG links to PRs/issues — `LOW`

---

## Phase 5 — Release PR

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)

gh pr create \
  --base main \
  --head release/{VERSION} \
  --title "Release {VERSION}" \
  --body "$(cat <<'EOF'
## Release {VERSION}

### Checklist
- [ ] Version bumped in all locations
- [ ] CHANGELOG updated
- [ ] README updated
- [ ] Dependencies audited
- [ ] CI green
- [ ] Snapshot baselines current

### Release Notes
<!-- paste from CHANGELOG -->

### Testing
- [ ] Smoke test on physical device (iPhone SE + iPhone 15 Pro)
- [ ] Dark mode verified
- [ ] Accessibility audit passed
- [ ] TestFlight beta tested by QA

Closes milestone: v{VERSION}
EOF
)" \
  --label "release" \
  --reviewer release-manager1,release-manager2 \
  --milestone "v{VERSION}"
```

```bash
# Monitor PR checks
gh pr checks {PR} --watch
```

---

## Phase 6 — CI/CD & Distribution

### Monitor and fix

```bash
# Watch CI in real time
gh pr checks {PR} --watch

# View failing job logs
gh run view {RUN_ID} --job "unit-tests" --log | tail -100
gh run view {RUN_ID} --job "snapshot-tests" --log | tail -100

# Re-run only failed jobs
gh run rerun {RUN_ID} --failed
```

### Trigger release build / TestFlight upload

```bash
# Trigger release archive workflow
gh workflow run release-build.yml \
  -f version="{VERSION}" \
  -f build_number="{BUILD_NUMBER}" \
  -f environment="production"

# Trigger TestFlight beta upload
gh workflow run upload-testflight.yml \
  -f version="{VERSION}" \
  -f build_number="{BUILD_NUMBER}" \
  -f release_notes="$(git log --oneline -10)"

# Monitor distribution
gh run list --workflow=upload-testflight.yml --limit 3
gh run view {RUN_ID} --log | grep -E "success|error|uploaded"
```

### Download and verify artifacts

```bash
# Download release IPA and dSYM
gh run download {RUN_ID} --name "MyApp-Release.ipa" --dir ./release-artifacts
gh run download {RUN_ID} --name "dSYMs"             --dir ./release-artifacts

# Verify IPA is signed correctly
xcrun codesign -vvv ./release-artifacts/MyApp.ipa

# Verify dSYM UUID matches IPA
dwarfdump --uuid ./release-artifacts/MyApp.dSYM
```

---

## Phase 7 — Tag & GitHub Release

### Merge the release PR (confirm with user first)

```bash
gh pr merge {PR} --squash --delete-branch
```

### Create annotated tag

```bash
git checkout main && git pull origin main
git tag -a "v{VERSION}" -m "Release {VERSION}

$(git log $(git describe --tags --abbrev=0)..HEAD \
  --pretty=format:"- %s" --no-merges)"
git push origin "v{VERSION}"
```

### Create GitHub release

```bash
gh release create "v{VERSION}" \
  --title "Version {VERSION}" \
  --notes-file <(sed -n '/## \[{VERSION}\]/,/## \[/p' CHANGELOG.md | head -n -1) \
  --target main \
  ./release-artifacts/MyApp-Release.ipa \
  ./release-artifacts/MyApp.dSYM.zip
```

---

## Phase 8 — Post-Release

### Merge release back to develop (GitFlow only)

```bash
git checkout develop && git pull origin develop
git merge --no-ff main -m "chore: sync release {VERSION} back to develop"
git push origin develop
```

### Bump to next development version

```bash
# e.g. after 2.1.0 → bump to 2.2.0-dev
NEXT_VERSION="2.2.0"
sed -i '' "s/MARKETING_VERSION = .*/MARKETING_VERSION = $NEXT_VERSION-dev/" \
  Configurations/Release.xcconfig
git add Configurations/Release.xcconfig
git commit -m "chore: start development of {NEXT_VERSION}"
git push origin develop
```

### Close milestone

```bash
MILESTONE_NUMBER=$(gh api repos/$REPO/milestones \
  --jq ".[] | select(.title==\"v{VERSION}\") | .number")
gh api repos/$REPO/milestones/$MILESTONE_NUMBER \
  --method PATCH -f state="closed"
```

### Verify release hygiene

- [ ] **REL-HYG-001** Release branch deleted after merge — `MEDIUM`
- [ ] **REL-HYG-002** Git tag is annotated (not lightweight) — `HIGH`
- [ ] **REL-HYG-003** GitHub release created with artifact uploads — `HIGH`
- [ ] **REL-HYG-004** dSYM uploaded to crash reporting (Crashlytics / Sentry) — `HIGH`
- [ ] **REL-HYG-005** Milestone closed — `MEDIUM`
- [ ] **REL-HYG-006** Develop branch updated to next snapshot version — `MEDIUM`
- [ ] **REL-HYG-007** All release PR review comments resolved — `HIGH`

---

## Output Format

```markdown
# Mobile Release: {VERSION}
**Date:** <ISO-8601>
**Type:** minor / patch / hotfix
**Source Branch:** main / develop

## Pre-Release Gate
| Check | Status | Notes |
|---|---|---|
| All milestone PRs merged | ✅ / ❌ | ... |

## Version Locations
| File | Old | New |
|---|---|---|

## Dependency Audit
| Package | Current | Latest | Risk |
|---|---|---|---|

## Documentation Changes
- CHANGELOG.md: ✅ updated
- README.md: ✅ updated

## Release Checklist
- [ ] Phase 0: Pre-release checks
- [ ] Phase 1: Branch created
- [ ] Phase 2: Versions bumped
- [ ] Phase 3: Dependencies audited
- [ ] Phase 4: Docs updated
- [ ] Phase 5: Release PR open
- [ ] Phase 6: CI green / TestFlight uploaded
- [ ] Phase 7: Tagged and GitHub release created
- [ ] Phase 8: Post-release cleanup done

**Release Signal:** 🟢 Ready / 🟡 Needs work / 🔴 Blocked
```

---

## Guardrails

- **Confirm before any push to `main`** — release merge is irreversible without a revert commit
- **Confirm before tag push** — tags are permanent; a wrong tag requires forced deletion
- **Confirm before App Store / TestFlight upload** — submissions cannot be recalled instantly
- **Never auto-merge without CI green** — wait for all required checks
- **Never bump version on `main` directly** — always use the release branch
- **CLAUDE.md overrides all defaults** — check for project-specific release steps first
- **Check `../github-operations/SKILL.md`** for all `gh` CLI command templates
