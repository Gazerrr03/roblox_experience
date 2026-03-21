# Review Checklist

## Setup

1. Read PR metadata.
2. Read changed files.
3. Read diff when needed.
4. Fetch base branch if freshness matters.
5. Map files to vibe domains.

## Review Questions

- Did contract meaning change?
- Were producers, consumers, and tests updated together?
- Did the PR change teleport or join lifecycle behavior?
- Did validation match the touched area?
- Does the write-up correctly say the PR lands on `main` first?

## Output Rules

- Findings first
- Severity ordered
- Separate code issues from merge-process notes
- Say `No blocking findings.` when appropriate

## Plan Mode Note

Use the planning agent first to align the review surface.
