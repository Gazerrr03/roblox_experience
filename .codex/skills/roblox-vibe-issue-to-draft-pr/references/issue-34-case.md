# Issue 34 To PR 95 Case

## Issue

- Issue: `#34`
- Title: `[Items] Glow orb pilot for held light and visibility`

## Final Delivery

- PR: `#95`
- Base: `main`
- Head: `feat/issue-34-glow-orb-handoff`

## Why This Was A Good Baseline

It exercised the full vibe workflow:

1. route the issue correctly
2. detect that it is not just maze-local
3. update the shared handoff contract
4. wire both `run` and `maze` consumers
5. validate with shared tests and place builds
6. open a draft PR to `main`

## The Core Insight

The feature was not "just a glow orb."

It forced a decision about whether inventory is:

- local to one place, or
- a player-centric cross-place state

Once the second interpretation was chosen, the implementation had to include:

- contract handoff changes
- `run` inventory snapshot and equip support
- `maze` return behavior that preserves inventory

## Teaching Value

Use this case when onboarding teammates on:

- how to detect a cross-vibe issue
- why `main` is the integration landing branch
- how one feature can touch `contract`, `run`, and `maze` without changing the routing model
