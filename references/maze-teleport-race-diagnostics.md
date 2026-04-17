# Maze Teleport Race Diagnostics

Use this guide to verify whether the Maze server is building the world before it
accepts valid `TeleportData`, and whether formal `run -> maze` teleports are
ever falling back to the direct-boot path.

## What To Look At

- Server output lines prefixed with `[RunMazeDiag]`
- Server output lines prefixed with `[MazeDiag]`
- Maze HUD status text:
  - `Build`
  - `Seed`
  - `Direct`
- Maze world root attributes on the generated world folder:
  - `WorldBuildSeed`
  - `WorldBuildSessionId`
  - `WorldBuildMazeAccessCode`
  - `WorldBuildIsDirectBoot`
  - `WorldBuildSource`

## Result Categories

- `JoinDataMergedBeforeBuild`
  - Expected formal path
  - Maze accepted valid `TeleportData` before the world was built
- `JoinDataMergedAfterBuild`
  - Race confirmed
  - Maze built first, then accepted valid `TeleportData`
- `DirectBootDefault`
  - Direct-boot path built the world
  - This is expected only for intentional local direct boot

## Experiment A — Single Formal Entry

1. Start from the `run` place and trigger one normal maze entry.
2. Record the matching `[RunMazeDiag]` and `[MazeDiag]` lines.
3. Once the player loads into Maze, capture the HUD diagnostics and the world
   root attributes.

Expected formal result:

- `WorldBuildSource = JoinDataMergedBeforeBuild`
- `WorldBuildIsDirectBoot = false`
- `WorldBuildSeed` matches the seed logged by `[RunMazeDiag]`

## Experiment B — Repeat Single Entry

1. Repeat the normal `run -> maze` flow 5-10 times.
2. For each run, record the same logs and diagnostics.
3. Stop as soon as one run produces:
   - `WorldBuildSource = JoinDataMergedAfterBuild`, or
   - `WorldBuildSource = DirectBootDefault`, or
   - a `WorldBuildSeed` that does not match the run-side seed

Any one of those outcomes is enough to treat the timing bug as confirmed.

## Experiment C — Two Players, Same Maze Server

1. Use two players from the same camp session.
2. Have them enter the same shared maze run so they target the same
   `MazeAccessCode`.
3. Capture the first Maze HUD snapshot seen by both players.

Expected shared-world result:

- same `WorldBuildSeed`
- same `WorldBuildSessionId`
- same `WorldBuildMazeAccessCode`
- same `WorldBuildSource`

If these fields differ, the session is not observing one shared world identity.
