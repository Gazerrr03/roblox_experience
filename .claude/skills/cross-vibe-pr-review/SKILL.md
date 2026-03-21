---
name: cross-vibe-pr-review
description: Review a pull request in this Roblox repo with a cross-vibe mindset. Use when a PR may touch contract plus place-local consumers, or when the merge target and sync story need to be explained clearly.
context: fork
agent: Plan
disable-model-invocation: true
argument-hint: "[pr-number-or-url]"
allowed-tools: Read, Grep, Glob, Bash(gh *), Bash(git *), Bash(rg *)
---

Review PR $ARGUMENTS with findings first.

## Gather context

Collect:

- `gh pr view`
- `gh pr diff --name-only`
- `gh pr diff` when needed
- `git fetch origin` if branch freshness matters

Read the touched vibe's `VIBE.md` first and `NOW.md` second.

## Review focus

Look for:

- contract drift between producers, consumers, and tests
- teleport or join lifecycle regressions
- replicated snapshot mismatches
- run versus maze ownership mistakes
- missing validation for shared gameplay changes
- incorrect statements about landing on multiple long-lived branches at once

## Output

Return:

1. Findings
2. Open Questions / Assumptions
3. Summary

If there are no blocking findings, say exactly `No blocking findings.`

Separate code issues from merge-process notes, and state clearly whether the PR lands on `main` and only later syncs back into the long-lived vibe branches.
