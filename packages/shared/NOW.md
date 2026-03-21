# Contract NOW

## Current Focus

- Keep the cross-place handoff surface stable while the three place lines learn
  to evolve more independently.
- Keep the shared contract small enough that changes here remain reviewable.

## Open Questions

- When to formally split the current run-flavored remote surface so maze no
  longer depends on `RunAction`, `RunSnapshot`, and `PrivateState`
- Whether the portal-adapter pattern explored on `origin/contract` should
  become the default seam for all cross-place teleports

## Temporary Exceptions

- `packages/shared/VIBE.md` represents the `contract` workstream, but the
  contract owner zone is only a subset of `packages/shared`, not the whole
  package.

## Near-Term Cleanup

- If a handoff grows more complex, document it through tests and narrower
  modules before expanding place-local branching.
