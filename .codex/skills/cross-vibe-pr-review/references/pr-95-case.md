# PR 95 Case

## What Was Reviewed

- PR: `#95`
- Base: `main`
- Purpose: deliver issue `#34` as a cross-vibe integration PR

## Why This Case Matters

PR `#95` is the baseline example for review because it combines:

- shared contract changes
- `run` consumer changes
- `maze` consumer changes
- updated shared tests

That means reviewers have to check both:

- code correctness
- merge-story correctness

## Expected Review Conclusion

The correct explanation is:

- the PR lands on `main`
- it affects the `contract`, `run`, and `maze` code domains
- after merge, `main` is synced back into the long-lived vibe branches

The incorrect explanation is:

- "this PR merges into `main`, `contract`, `run`, and `maze` together"

## Teaching Value

Use this case to show teammates how cross-vibe review differs from place-local review:

- the code diff spans several vibes
- the branch target still stays singular
- review must cover both handoff semantics and place-local consumers
