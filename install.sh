#!/usr/bin/env bash
# install.sh — Install skill-book skills to Claude Code on macOS
# Usage:
#   ./install.sh            Install all skills
#   ./install.sh --list     List installed skills
#   ./install.sh --remove   Remove all installed skills
#   ./install.sh <name>     Install a single skill by name

set -euo pipefail

# ── Paths ────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$SCRIPT_DIR/skills"
CLAUDE_SKILLS="$HOME/.claude/skills"

# ── Colors ───────────────────────────────────────────────────────────────────
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
CYAN="\033[0;36m"
BOLD="\033[1m"
RESET="\033[0m"

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()   { echo -e "  ${GREEN}✓${RESET}  $*"; }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
err()  { echo -e "  ${RED}✗${RESET}  $*" >&2; }
info() { echo -e "  ${CYAN}→${RESET}  $*"; }

# ── List installed ────────────────────────────────────────────────────────────
list_installed() {
  echo -e "\n${BOLD}Installed skills${RESET} (${CLAUDE_SKILLS})\n"
  if [ ! -d "$CLAUDE_SKILLS" ] || [ -z "$(ls -A "$CLAUDE_SKILLS" 2>/dev/null)" ]; then
    warn "No skills installed yet."
    return
  fi
  for skill_dir in "$CLAUDE_SKILLS"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    skill_md="$skill_dir/SKILL.md"
    if [ -f "$skill_md" ]; then
      # Extract description from frontmatter
      desc=$(awk '/^description:/{found=1; sub(/^description: /,""); print; exit} found && /^[^ ]/{exit}' "$skill_md" | tr -d '"')
      printf "  ${GREEN}%-35s${RESET} %s\n" "$name" "${desc:0:70}"
    else
      printf "  ${YELLOW}%-35s${RESET} (no SKILL.md)\n" "$name"
    fi
  done
  echo ""
}

# ── Remove all ────────────────────────────────────────────────────────────────
remove_all() {
  echo -e "\n${BOLD}Removing installed skills…${RESET}\n"
  if [ ! -d "$CLAUDE_SKILLS" ]; then
    warn "Skills directory not found — nothing to remove."
    return
  fi
  local removed=0
  for skill_dir in "$CLAUDE_SKILLS"/*/; do
    [ -d "$skill_dir" ] || continue
    name=$(basename "$skill_dir")
    rm -rf "$skill_dir"
    ok "Removed $name"
    removed=$((removed + 1))
  done
  echo -e "\n${removed} skill(s) removed.\n"
}

# ── Install one skill ─────────────────────────────────────────────────────────
install_skill() {
  local src="$1"
  local name
  name=$(basename "$src")
  local target="$CLAUDE_SKILLS/$name"

  if [ ! -f "$src/SKILL.md" ]; then
    warn "$name — no SKILL.md found, skipping"
    return 1
  fi

  local action="Installed"
  if [ -d "$target" ]; then
    action="Updated"
    rm -rf "$target"
  fi

  cp -r "$src" "$target"
  ok "$action  $name"
  return 0
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  echo -e "\n${BOLD}skill-book installer${RESET}\n"

  # Parse flags
  case "${1:-}" in
    --list)
      list_installed
      exit 0
      ;;
    --remove)
      remove_all
      exit 0
      ;;
    --help|-h)
      echo "Usage:"
      echo "  ./install.sh            Install all skills"
      echo "  ./install.sh <name>     Install a single skill"
      echo "  ./install.sh --list     List installed skills"
      echo "  ./install.sh --remove   Remove all installed skills"
      echo ""
      exit 0
      ;;
  esac

  # Ensure source directory exists
  if [ ! -d "$SKILLS_SOURCE" ]; then
    err "Skills directory not found: $SKILLS_SOURCE"
    exit 1
  fi

  # Create Claude skills directory
  if [ ! -d "$CLAUDE_SKILLS" ]; then
    mkdir -p "$CLAUDE_SKILLS"
    info "Created $CLAUDE_SKILLS"
  fi

  local installed=0
  local failed=0

  # Single skill install
  if [ -n "${1:-}" ]; then
    local target_src="$SKILLS_SOURCE/$1"
    if [ ! -d "$target_src" ]; then
      err "Skill not found: $1"
      echo ""
      echo "Available skills:"
      for d in "$SKILLS_SOURCE"/*/; do
        echo "  $(basename "$d")"
      done
      echo ""
      exit 1
    fi
    if install_skill "$target_src"; then
      installed=1
    else
      failed=1
    fi
  else
    # Install all skills
    for skill_dir in "$SKILLS_SOURCE"/*/; do
      [ -d "$skill_dir" ] || continue
      if install_skill "$skill_dir"; then
        installed=$((installed + 1))
      else
        failed=$((failed + 1))
      fi
    done
  fi

  echo ""
  echo -e "${BOLD}${installed}${RESET} skill(s) installed → ${CYAN}${CLAUDE_SKILLS}${RESET}"
  [ "$failed" -gt 0 ] && warn "$failed skill(s) skipped"
  echo ""

  # Show summary
  echo -e "${BOLD}Installed:${RESET}"
  for skill_dir in "$CLAUDE_SKILLS"/*/; do
    [ -d "$skill_dir" ] || continue
    echo "  • $(basename "$skill_dir")"
  done
  echo ""
}

main "$@"
