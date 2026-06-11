# Worktree workflow — per-task worktrees

Summary
- Use one ephemeral git worktree per task/PR instead of creating many worktrees in batch.
- Keep work isolated, easy to clean up, and traceable to TASK IDs in docs/tasks.
- PR-first task updates: make all task-file and TASK-INDEX edits in a topic branch and include them in a PR. Merge the PR before the task is considered 'done' on main. Do not change task status directly on main.

When to use
- Create a worktree for any task that:
  - Requires development beyond a trivial one-line fix
  - Needs a dedicated local environment, tests, or a long-running dev server
- For tiny edits (typos, single-file docs tweaks) use an existing branch or the main working tree.

Naming
- Branch: `<type>/<TASK-ID>-short-description` where `<type>` is one of `feat`, `fix`, `chore`, `docs`, `devops`, `test`, etc.
  Example: `docs/TASK-API-001-mark-done` or `feat/TASK-API-002-add-auth-handler`
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

Push & open a PR (update task docs in-branch)
```
git push -u origin task/TASK-API-001-short-desc
# create PR with gh or via web UI
gh pr create --base BASE --head task/TASK-API-001-short-desc --title "<TASK-ID>: short title" --body "Include TASK-ID, links to TASK file and TASK-INDEX.md, and PRD/REQ footers."
```
Before creating the PR, ensure any edits to the task frontmatter `status` and to `docs/tasks/TASK-INDEX.md` are made in this branch so they are part of the PR (e.g., set `status: in-progress` when starting; update to `status: done` in the same branch/PR). Do not edit these files directly on main.

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
- [ ] Update the task file frontmatter `status` (e.g., to `in-progress`) and the TASK-INDEX row in this branch — do not edit these on main
- [ ] Run tests for the affected components (see app/package-specific test commands)
- [ ] Push and open PR; include TASK-ID, link to the task file and TASK-INDEX, and include PRD/REQ footers as needed
- [ ] After the PR is merged, close the related GitHub issue (if linked) and confirm `status: done` is on main
- [ ] Remove the worktree and delete the branch remotely

See also
- `docs/tasks/TASK-INDEX.md`
- `docs/COMMIT_CONVENTION.md`
