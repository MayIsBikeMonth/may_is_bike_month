---
name: merge-conflicts
description: >-
  How to bring a branch up to date and resolve git merge conflicts the way this
  repo expects — merge (never rebase or force-push), understand each side's
  intent before choosing, ask when a resolution isn't clear-cut, keep the merge
  commit to just the merge, and audit what merged *cleanly* before committing.
  Trigger whenever you're about to run
  `git merge`/`git pull`, sync a branch with `main`, "update from main", or
  resolve conflict markers left by a merge, cherry-pick, or interrupted pull —
  including bare phrasings like "fix the conflicts", "merge main in", or "this
  branch is behind". Not for merging data/files (PDFs, CSVs) or algorithms
  (merge sort) — this is strictly about git branch integration.
allowed-tools: Bash, Read, Edit, Write, Glob, Grep
---

# Resolving merge conflicts

## Determine the base branch first — don't assume `main`

**Re-read `git branch --show-current` rather than trusting the branch from earlier in the session.** Conductor runs sessions concurrently, so another one can check this worktree out onto a different branch while your conversation is open.

"Update from base", "sync with main", "this branch is behind" all need a base branch to merge *from*. **Don't default to `main`.** A branch is often stacked on another feature branch, and merging `main` instead silently pulls the wrong history. Resolve the base in this order:

1. **A branch the user names** — "update from X" / "base is X" wins outright.
2. **An open PR's base** — `gh pr view <branch> --json baseRefName`. Also check the base of any feature branch you recently merged into this one; a stack's branches usually share the same base.
3. **The upstream tracking ref**, if it names a branch other than this one's own remote mirror (`git rev-parse --abbrev-ref @{u}`).
4. **The Conductor workspace target branch** (from the workspace/system instructions) — a default hint, *not* the last word.

**Re-resolve the base every time — it moves.** When a base branch's PR merges, GitHub retargets the child PR (usually to `main`).

If 1–3 turn up nothing and the branch clearly builds on another feature branch, **ask which branch to update from (offer the likely candidate) rather than merging `main`.**

## Bring a branch up to date

- `git fetch origin`, then `git merge --no-edit origin/<base>`.
- **Read what the merge brought in from the merge itself, not from an earlier ahead/behind count** — `git log --oneline <pre-merge-HEAD>..<merge-commit>^2`. Conductor worktrees share one `.git`, so another session's `git fetch` can advance your base mid-conversation.
- **Merge, never rebase.** Republishing a rebased branch needs a force-push, and we never force-push.
- If uncommitted work blocks the merge, commit that work first (it belongs to the branch anyway), then merge.

### Base already merged? Merge its final commit *before* `main`

This repo squash-merges, so a merged base lands on `main` as one commit sharing no ancestry with the base's real commits. Merge `main` straight into the stacked branch and every file the base *added* comes back as an **add/add** conflict.

Merge the base's tip first, then `main`:

```bash
gh pr view <base-pr> --json headRefOid --jq .headRefOid  # tip survives branch deletion
git fetch origin <sha>                                   # or refs/pull/<base-pr>/head
git merge --no-edit <sha>
git merge --no-edit origin/main
```

That makes your side byte-identical to what the squash put on `main`, so the add/add conflicts collapse.

### Part of this branch already shipped as its own PR

Same cause the other way round: `main`'s side is the reviewed version of your own change — take it, then check that `git diff origin/main` lists only the work that PR left out.

## Keep the merge commit to *just* the merge

A merge commit should contain **only** the reconciliation of the two histories. Don't fold in lint fixes, refactors, or "while I'm here" cleanups; land them as separate commits *after* the merge.

## Resolving conflicts

- **Understand each side before choosing.** Read enough of both to know what each is trying to do — don't mechanically keep "ours" or "theirs." The correct resolution is often a combination.
- **Consider the branch's purpose.** A resolution that quietly drops the branch's intent (or reverts something `main` deliberately changed) is a bug, even if it compiles.
- **Ask when it isn't clear-cut.** A wrong silent resolution is worse than a question.
- **Both sides added at the same spot? Order matters** when either block has side effects.
- **Taking one side resolves the marked blocks, not the file.** `git checkout --ours`/`--theirs` replaces the whole file, discarding the other side's cleanly merged hunks. Delete the unwanted half of each `<<<<<<<` block instead; `git checkout -m -- <file>` restores the markers.
- **Don't blanket-replace a renamed string** — two call sites that shared a string can have legitimately diverged.
- **A conflicted `db/schema.rb` version takes the newer one.** Keep both sides' table changes, then `bin/rails db:migrate` to re-dump. Never hand-merge the schema beyond that.
- After resolving, verify the result reflects both intents, not just parses. Run the relevant tests.

## The dangerous part is what merged *cleanly*

A three-way merge keeps *your* side of any line it can't attribute to a common ancestor. A base that arrived as a **squash-merge** has history unrelated to yours, so git will resurrect code that base deliberately deleted, in files it reports as auto-merged.

After every merge, before committing:

```bash
git diff origin/<base> -- app/ lib/ config/   # then account for every file listed
```

Every differing file must be explainable as *this branch's work*. Anything else is a resurrection or a stray — for a file that's mostly wrong, `git checkout origin/<base> -- <file>` and re-apply your change on top.

**Reverting a file to the base's version *before* you've merged that base takes whatever the base has gained since.** `git checkout $(git merge-base origin/main HEAD) -- <file>` is the version your branch actually forked from.

**Resolving two files to opposite sides breaks the interface between them.** Whenever you reset a file that has callers, grep the arguments you dropped: `git grep -n '<kwarg>' -- app` should come back empty.

Watch for:

- **Deleted code coming back** — a constant, method, or callback the base removed reappears.
- **Another branch's change riding along** from a sibling merge. Reset it.
- **Committed churn in generated files** — VCR cassettes, lockfiles. A diff that's only timestamps should be reset to the base.
- **Your side calling an API the base deleted.** Nothing conflicts; it's a `NoMethodError` at runtime. Fix it in the commit after the merge.

## Extracting a slice of another branch: `git checkout <branch> -- <file>` overwrites, it doesn't merge

For anything `main` has moved since that branch last merged, you silently revert the newer work. List the overlap first, and hand-apply those hunks:

```bash
MB=$(git merge-base origin/main origin/<branch>)
comm -12 <(git diff --name-only $MB origin/main | sort) <(git diff --name-only $MB origin/<branch> | sort)
```

## After the merge

- **A merged `Gemfile.lock` needs `bundle install`** before anything else runs — otherwise every `bin/` script dies with `Bundler::GemNotFound`. It should leave the lockfile untouched (if it rewrites it, the merge resolved it wrong). A running `bin/dev` needs `bin/rails restart`.
- **`bin/lint`** — a bad auto-merge that duplicates a method parses fine and passes its specs; `Lint/DuplicateMethods` catches it.
- **Run specs for the merged area, including the browser ones.** A rename on the base produces no conflict marker; it only surfaces at runtime.
- **`bin/rails db:migrate`** when the merge brought migrations.
- **`bin/rails tailwindcss:build`** when the merge brought `app/assets/tailwind/**` or new classes, before the browser specs.

## Never force-push

No exceptions, even on a personal branch. If history has diverged from the remote, merge `origin/<branch>` back in, then push normally.
