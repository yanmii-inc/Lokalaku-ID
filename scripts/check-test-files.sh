#!/bin/sh
# Verify that feat commits in a range include test file changes.
#
# Mirrors section 4 of the local .husky/commit-msg gate so it cannot be
# bypassed with `git commit --no-verify` on push.
#
# Rule (Global Principle 5):
#   feat  → code changes MUST include test file changes (blocked)
#   fix | perf → test presence is recommended; the actual test-run job
#                catches regressions (not blocked here — run tests instead)
#   all others → exempt
#
# Usage: scripts/check-test-files.sh <base-ref> <head-ref>
#   e.g. scripts/check-test-files.sh origin/main HEAD

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

  [ "$TYPE" = "feat" ] || continue   # only enforce on feat

  CODE=$(git diff-tree --no-commit-id -r --name-only "$SHA" \
    | grep -E '^(apps|packages)/' \
    | grep -E '\.(go|dart|ts|tsx|js|jsx)$' \
    | grep -vE '(_test\.(go|dart)|\.test\.(ts|js)|\.spec\.(ts|js))$' || true)

  [ -z "$CODE" ] && continue   # no production code in this commit — skip

  TESTS=$(git diff-tree --no-commit-id -r --name-only "$SHA" \
    | grep -E '(_test\.(go|dart)|\.test\.(ts|js)|\.spec\.(ts|js))$' || true)

  if [ -z "$TESTS" ]; then
    if [ "$FAILED" -eq 0 ]; then
      echo ""
      echo "┌─────────────────────────────────────────────────────────────────┐"
      echo "│  LOKALAKU: 'feat' commits missing test files                     │"
      echo "└─────────────────────────────────────────────────────────────────┘"
      echo ""
    fi
    FAILED=$((FAILED + 1))
    echo "  ✖ ${SHA%${SHA#???????}}  ${SUBJECT}"
    echo "      'feat' commit has code changes but no test files"
  fi
done

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "  $FAILED 'feat' commit(s) ship code with no tests."
  echo "  Every new feature must include tests alongside the implementation."
  echo ""
  echo "  Test file conventions:"
  echo "    Go API:    apps/api/internal/<pkg>/<file>_test.go"
  echo "    Flutter:   apps/<app>/test/<feature>/<name>_test.dart"
  echo "    Packages:  packages/flutter/<pkg>/test/<name>_test.dart"
  echo "    Website:   apps/website/src/**/*.test.ts"
  echo ""
  exit 1
fi

echo "✓ All 'feat' commits in ${RANGE} include test files."
