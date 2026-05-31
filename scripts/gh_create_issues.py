#!/usr/bin/env python3
"""
gh_create_issues.py

Scans docs/tasks/ for TASK-*.md files whose frontmatter has `github_issue: null`
and creates GitHub Issues via the `gh` CLI.  After creation, the task file's
frontmatter is updated in-place with the new issue URL.

Requirements:
    - gh CLI installed and authenticated  (`gh auth login`)
    - Run from the project root directory

Usage:
    python3 scripts/gh_create_issues.py [--dry-run] [--repo owner/repo] [--tasks-dir docs/tasks]

Options:
    --dry-run           Print what would be created without making any API calls.
    --repo owner/repo   Override the GitHub repository (default: inferred by gh CLI from git remote).
    --tasks-dir PATH    Directory to scan for TASK-*.md files (default: docs/tasks).
"""

import argparse
import os
import re
import subprocess
import sys
from pathlib import Path

# ─── Constants ────────────────────────────────────────────────────────────────

DEFAULT_TASKS_DIR = "docs/tasks"
FRONTMATTER_RE = re.compile(r"^---\n(.*?)\n---\n", re.DOTALL)
FIELD_RE = re.compile(r"^(?P<key>\w[\w_-]*):\s*(?P<value>.+)$")

DOMAIN_TO_LABEL = {
    "api": "app:api",
    "merchant_app": "app:merchant",
    "courier_app": "app:courier",
    "consumer_app": "app:consumer",
    "wholesaler_app": "app:wholesaler",
    "backoffice_web": "app:backoffice",
    "website": "app:website",
    "pkg": "shared-packages",
    "infra": "infrastructure",
}

PRIORITY_TO_LABEL = {
    "high": "priority:high",
    "medium": "priority:medium",
    "low": "priority:low",
}

COMPLEXITY_TO_LABEL = {
    "S": "size:S",
    "M": "size:M",
    "L": "size:L",
    "XL": "size:XL",
}


# ─── Frontmatter Parsing ──────────────────────────────────────────────────────


def parse_frontmatter(content: str) -> dict[str, str]:
    """Return a flat dict of the YAML frontmatter key/value pairs."""
    match = FRONTMATTER_RE.match(content)
    if not match:
        return {}
    result: dict[str, str] = {}
    for line in match.group(1).splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = FIELD_RE.match(line)
        if m:
            key = m.group("key")
            value = m.group("value").strip().strip('"').strip("'")
            result[key] = value
    return result


def update_frontmatter_field(content: str, field: str, new_value: str) -> str:
    """Replace `field: <anything>` inside the YAML frontmatter block."""

    # Only replace inside the first --- ... --- block.
    def replacer(m: re.Match) -> str:
        block = m.group(0)
        block = re.sub(
            rf"^({re.escape(field)}:\s*)(.+)$",
            rf"\g<1>{new_value}",
            block,
            count=1,
            flags=re.MULTILINE,
        )
        return block

    return FRONTMATTER_RE.sub(replacer, content, count=1)


# ─── File Discovery ───────────────────────────────────────────────────────────


SKIP_FILENAMES = {"TASK-TEMPLATE.md"}


def find_task_files(root: str) -> list[Path]:
    """Recursively find all TASK-*.md files under `root`, excluding templates."""
    paths: list[Path] = []
    for dirpath, _dirs, filenames in os.walk(root):
        for name in sorted(filenames):
            if (
                name.startswith("TASK-")
                and name.endswith(".md")
                and name not in SKIP_FILENAMES
            ):
                paths.append(Path(dirpath) / name)
    return sorted(paths)


# ─── Issue Building ───────────────────────────────────────────────────────────


def build_body(fm: dict[str, str], content: str) -> str:
    """Compose the GitHub issue body from frontmatter metadata + markdown body."""
    # Strip frontmatter from the content.
    body = FRONTMATTER_RE.sub("", content).strip()

    meta_lines: list[str] = []
    if fm.get("prd_ref") and fm["prd_ref"] not in ("—", "-", ""):
        meta_lines.append(f"**PRD Reference:** `{fm['prd_ref']}`")
    if fm.get("milestone"):
        meta_lines.append(f"**Milestone:** `{fm['milestone']}`")
    if fm.get("complexity"):
        meta_lines.append(f"**Complexity:** `{fm['complexity']}`")
    if fm.get("dependencies") and fm["dependencies"] not in ("[]", ""):
        meta_lines.append(f"**Dependencies:** `{fm['dependencies']}`")
    if fm.get("app"):
        meta_lines.append(f"**App / Scope:** `{fm['app']}`")

    if meta_lines:
        return "\n".join(meta_lines) + "\n\n---\n\n" + body
    return body


def derive_labels(fm: dict[str, str]) -> list[str]:
    labels: list[str] = []
    app = fm.get("app", "").lower()
    if app in DOMAIN_TO_LABEL:
        labels.append(DOMAIN_TO_LABEL[app])
    priority = fm.get("priority", "").lower()
    if priority in PRIORITY_TO_LABEL:
        labels.append(PRIORITY_TO_LABEL[priority])
    complexity = fm.get("complexity", "")
    if complexity in COMPLEXITY_TO_LABEL:
        labels.append(COMPLEXITY_TO_LABEL[complexity])
    milestone = fm.get("milestone", "")
    if milestone:
        labels.append(milestone.lower())
    return labels


# ─── GitHub Issue Creation ────────────────────────────────────────────────────


def create_issue(
    title: str,
    body: str,
    labels: list[str],
    repo: str | None,
    dry_run: bool,
) -> str | None:
    """Create a GitHub issue and return its URL, or None on failure."""
    cmd: list[str] = ["gh", "issue", "create", "--title", title, "--body", body]
    if labels:
        cmd += ["--label", ",".join(labels)]
    if repo:
        cmd += ["--repo", repo]

    if dry_run:
        short_cmd = " ".join(cmd[:6]) + " ..."
        print(f"    [DRY RUN] {short_cmd}")
        return "https://github.com/example/repo/issues/0"

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except FileNotFoundError:
        print(
            "  ERROR: `gh` CLI not found. Install it from https://cli.github.com/ "
            "and run `gh auth login`.",
            file=sys.stderr,
        )
        return None
    except subprocess.CalledProcessError as exc:
        print(f"  ERROR: {exc.stderr.strip()}", file=sys.stderr)
        return None


# ─── Main ─────────────────────────────────────────────────────────────────────


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Create GitHub Issues from TASK-*.md files with github_issue: null",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--dry-run", action="store_true", help="Print without creating")
    parser.add_argument("--repo", default=None, help="GitHub repo (owner/repo)")
    parser.add_argument(
        "--tasks-dir", default=DEFAULT_TASKS_DIR, help="Tasks directory"
    )
    args = parser.parse_args()

    tasks_dir = Path(args.tasks_dir)
    if not tasks_dir.exists():
        print(f"ERROR: tasks directory not found: {tasks_dir}", file=sys.stderr)
        sys.exit(1)

    task_files = find_task_files(str(tasks_dir))
    if not task_files:
        print(f"No TASK-*.md files found in {tasks_dir}")
        return

    created = skipped = errors = 0

    for path in task_files:
        content = path.read_text(encoding="utf-8")
        fm = parse_frontmatter(content)

        if not fm:
            print(f"⚠️  No frontmatter:  {path}")
            skipped += 1
            continue

        task_id = fm.get("id", "")
        title = fm.get("title", "").strip('"').strip("'")
        github_issue = fm.get("github_issue", "null")

        if not task_id or not title:
            print(f"⚠️  Missing id/title: {path}")
            skipped += 1
            continue

        if github_issue and github_issue.lower() not in ("null", ""):
            print(f"✅ Already linked   [{task_id}]: {github_issue}")
            skipped += 1
            continue

        print(f"📋 Creating issue   [{task_id}]: {title}")
        body = build_body(fm, content)
        labels = derive_labels(fm)
        issue_url = create_issue(
            title=f"[{task_id}] {title}",
            body=body,
            labels=labels,
            repo=args.repo,
            dry_run=args.dry_run,
        )

        if issue_url:
            print(f"   → {issue_url}")
            if not args.dry_run:
                updated = update_frontmatter_field(
                    content, "github_issue", f'"{issue_url}"'
                )
                path.write_text(updated, encoding="utf-8")
            created += 1
        else:
            errors += 1

    print(
        f"\n{'DRY RUN — ' if args.dry_run else ''}Done: {created} created, {skipped} skipped, {errors} errors."
    )


if __name__ == "__main__":
    main()
