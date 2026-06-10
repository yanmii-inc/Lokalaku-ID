# Worktree workflow — per-task worktrees

Summary
- Use one ephemeral git worktree per task/PR instead of creating many worktrees in batch.
- Keep work isolated, easy to clean up, and traceable to TASK IDs in docs/tasks.

When to use
- Create a worktree for any task that:
  - Requires development beyond a trivial one-line fix
  - Needs a dedicated local environment, tests, or a long-running dev server
- For tiny edits (typos, single-file docs tweaks) use an existing branch or the main working tree.

Naming
- Branch: `task/<TASK-ID>-short-description`
  Example: `task/TASK-API-001-add-auth-handler`
- Worktree path: `.worktrees/<TASK-ID>` (or `.worktrees/TASK-API-001`)
  Example: `.worktrees/TASK-API-001`

Create a per-task worktree (recommended)
Replace `BASE` with the base branch (e.g., `main`, `develop`) and `TASK-*` accordingly.

Fetch latest refs:
```
git fetch origin
```

Create a new worktree and branch in one command:
```
git worktree add -b task/TASK-API-001-short-desc .worktrees/TASK-API-001 origin/BASE
```

(Alternatively create the branch first and then add a worktree):
```
git switch -c task/TASK-API-001-short-desc origin/BASE
git worktree add .worktrees/TASK-API-001 task/TASK-API-001-short-desc
```

Work inside the worktree
```
cd .worktrees/TASK-API-001
# run relevant tests/builds (go test ./..., moon run :test, flutter test, pnpm test, etc.)
# make commits using the repo commit convention (docs/COMMIT_CONVENTION.md)
git add .
git commit -m "feat(api): short subject"
```

Push & open a PR
```
git push -u origin task/TASK-API-001-short-desc
# create PR with gh or via web UI
gh pr create --fill --base BASE --head task/TASK-API-001-short-desc
```
Include the TASK-ID in the PR title/body and link to `docs/tasks/TASK-INDEX.md`.

Cleanup (after merge or abandon)
From repo root:
```
git worktree remove .worktrees/TASK-API-001
git branch -d task/TASK-API-001-short-desc
git push origin --delete task/TASK-API-001-short-desc
# remove stale worktrees
git worktree prune
```

Rationale
Batch-creating worktrees for a milestone leads to many stale worktrees, unnecessary disk usage, and cognitive overhead. Per-task worktrees keep the workspace minimal and map work to tasks/PRs for simple cleanup and traceability.

Quick checklist
- [ ] Create `task/<TASK-ID>-...` branch and `.worktrees/<TASK-ID>` worktree
- [ ] Run tests for the affected components (see app/package-specific test commands)
- [ ] Push and open PR; link TASK-ID and any PRD/REQ footers
- [ ] After merge, remove the worktree and delete the branch remotely

See also
- `docs/tasks/TASK-INDEX.md`
- `docs/COMMIT_CONVENTION.md`
