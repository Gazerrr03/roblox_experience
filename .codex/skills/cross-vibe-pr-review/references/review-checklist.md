# Review Checklist

## Review Setup

1. Read PR metadata with `gh pr view`.
2. Read the changed file list with `gh pr diff --name-only`.
3. Read full diff when needed.
4. Fetch the base branch when freshness matters.
5. Map touched files to vibe domains.

## Code Review Questions

- Did the PR change shared meaning under `contract`?
- If yes, were all producers, consumers, and tests updated together?
- Did the PR alter teleport or join lifecycle behavior?
- Did any new snapshot field get added on the server without a matching client read, or vice versa?
- Is the issue truly cross-vibe, or did the PR sprawl into unrelated owner zones?
- Did validation match the touched area?

## Merge Story Questions

- Does the PR target `main`?
- Is anyone describing it as if it merges into several long-lived branches at once?
- Does the write-up explain that `main` becomes the new integration baseline and other long-lived vibe branches are synced later?

## Output Rules

- Put findings first.
- Order by severity.
- Use file references when possible.
- If there are no blocking findings, say exactly `No blocking findings.`
- Separate code correctness from merge-process notes.

## Plan Mode Note

When plan mode is available, use it to collect context and decide the review surface before forming findings.
