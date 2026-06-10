#!/bin/sh
# Verify traceability footers on behavioral commits across a range.
#
# Mirrors the local .husky/commit-msg gate, but runs over every commit in a
# push/PR range so it cannot be skipped with `git commit --no-verify`.
#
# Doc impact follows the commit TYPE:
#   feat | fix | perf            → behavioral → MUST trace to a REQ / ADR / issue
#   refactor | style | chore     → internal   → exempt
#   test | ci | docs | revert    → no weight  → exempt
#
# Usage: scripts/check-commit-footers.sh <base-ref> <head-ref>
#   e.g. scripts/check-commit-footers.sh origin/main HEAD

set -eu

BASE="${1:-origin/main}"
HEAD="${2:-HEAD}"

RANGE="${BASE}..${HEAD}"
COMMITS=$(git rev-list --no-merges "$RANGE")

if [ -z "$COMMITS" ]; then
  echo "No non-merge commits in ${RANGE} — nothing to check."
  exit 0
fi

FAILED=0

for SHA in $COMMITS; do
  SUBJECT=$(git log -1 --format=%s "$SHA")
  TYPE=$(printf '%s' "$SUBJECT" | sed -n 's/^\([a-z]*\).*/\1/p')

  case "$TYPE" in
    feat|fix|perf) ;;          # behavioral — enforce
    *) continue ;;             # exempt
  esac

  BODY=$(git log -1 --format=%B "$SHA")
  if printf '%s' "$BODY" | grep -qE '^(Implements|See|Closes|Refs):'; then
    continue
  fi

  if [ "$FAILED" -eq 0 ]; then
    echo ""
    echo "┌─────────────────────────────────────────────────────────────────┐"
    echo "│  LOKALAKU: behavioral commits missing traceability footers       │"
    echo "└─────────────────────────────────────────────────────────────────┘"
    echo ""
  fi
  FAILED=$((FAILED + 1))
  echo "  ✖ ${SHA%${SHA#???????}}  ${SUBJECT}"
  echo "      '$TYPE' commit has no Implements:/See:/Closes:/Refs: footer"
done

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "  $FAILED behavioral commit(s) lack traceability."
  echo "  Each feat/fix/perf must include at least one footer:"
  echo ""
  echo "    Implements: REQ-XX-NNN     — product requirement (PRD.md)"
  echo "    Implements: REQ-INFRA-NNN  — infra requirement (docs/infra/REQUIREMENTS.md)"
  echo "    See: ADR-NNN               — architecture decision"
  echo "    Closes: #NNN / Refs: #NNN  — GitHub issue / task"
  echo ""
  echo "  Fix by rewording the commit(s) (git rebase -i) — or run /reconcile to"
  echo "  back-fill the docs that justify the footer."
  echo ""
  exit 1
fi

echo "✓ All behavioral commits in ${RANGE} carry traceability footers."
