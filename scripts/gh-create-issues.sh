#!/usr/bin/env bash
# gh-create-issues.sh
#
# Thin shell wrapper around scripts/gh_create_issues.py.
# Forwards all arguments verbatim to the Python script.
#
# Usage (from repo root):
#   bash scripts/gh-create-issues.sh              # create real issues
#   bash scripts/gh-create-issues.sh --dry-run    # preview only
#   bash scripts/gh-create-issues.sh --repo owner/repo --dry-run
#
# Requirements:
#   - Python 3.9+ available as `python3`
#   - gh CLI installed and authenticated (gh auth login)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_SCRIPT="$SCRIPT_DIR/gh_create_issues.py"

if ! command -v python3 &>/dev/null; then
    echo "ERROR: python3 not found. Install Python 3.9+." >&2
    exit 1
fi

if ! command -v gh &>/dev/null; then
    echo "ERROR: gh CLI not found. Install from https://cli.github.com/ and run 'gh auth login'." >&2
    exit 1
fi

exec python3 "$PYTHON_SCRIPT" "$@"
