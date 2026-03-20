# Place Parallel Development

This repository uses four long-lived delivery lines for the multi-place
experience:

- `lobby`
- `run`
- `maze`
- `contract`

## Ownership

- `lobby` owns `places/lobby/**` and the local adapter that launches into run.
- `run` owns `places/run/**` and the local adapter that enters maze or accepts
  maze returns.
- `maze` owns `places/maze/**` and the local adapter that returns players to run.
- `contract` owns cross-place handoff definitions under:
  - `packages/shared/src/Session/**`
  - `packages/shared/src/Network/**`
  - `packages/shared/src/Config/SessionConfig.luau`
  - `tests/src/Shared/**`

## Hard Boundaries

- Place branches do not change teleport payload shape, return summary shape, or
  shared remote names.
- Shared handoff changes land in `contract` first, then each place rebases onto
  that baseline.
- Each place uses place-scoped remotes:
  - lobby: `LobbyAction`, `LobbyState`
  - run: `RunAction`, `RunState`, `RunPrivateState`
  - maze: `MazeAction`, `MazeState`, `MazePrivateState`
- Cross-place teleports must go through place-local portal adapters instead of
  being inlined directly inside service orchestration code.

## Recommended Worktree Layout

Create sibling worktrees next to the main repository:

```bash
git worktree add ../roblox_experience-lobby lobby
git worktree add ../roblox_experience-run run
git worktree add ../roblox_experience-maze maze
git worktree add -b contract ../roblox_experience-contract origin/main
```

The main repository worktree can stay on an unrelated feature branch. Use the
dedicated worktree for the line you are changing.

## Merge Order

1. Land the shared `contract` baseline.
2. Rebase `lobby`, `run`, and `maze` onto that baseline.
3. Land place-local PRs independently.
4. For any later handoff change, repeat the same order: contract first, then
   place adapters and consumers.

## Validation

For contract changes:

1. `stylua --check .`
2. `selene .`
3. `rojo build tests/default.project.json -o <output.rbxlx>`
4. `run-in-roblox --place <output.rbxlx> --script tests/run-in-roblox.lua`

For place-local changes, also build the relevant place project:

- `rojo build places/lobby/default.project.json -o <output.rbxlx>`
- `rojo build places/run/default.project.json -o <output.rbxlx>`
- `rojo build places/maze/default.project.json -o <output.rbxlx>`
