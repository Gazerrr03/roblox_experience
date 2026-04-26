# Deadline Slice Kickoff

## Purpose

This kickoff turns `Soul of Liminal` into the smallest two-day playable slice plan.
It is not a new design bible. It is the current execution gate for making one
`Run -> Maze -> Run` loop prove that knowledge changes survival behavior.

## Playable Gate

The slice is ready to demo when a fresh player can say all four things after one
loop:

1. `I was sent from camp/the ship into the maze to recover Pages and bring them back alive.`
2. `I found at least one clue in Run that made me suspect how the maze threat works.`
3. `The maze threat reacted to something I did; it did not feel like a pure script kill.`
4. `I know one thing I should do differently next time, or why leaving with fewer Pages was smart.`

## First Playable Chain

Lock the first chain to this order:

1. Camp assignment text frames Pages as the visible mission target.
2. A side-path corpse clue in Run hints that sound and panic feed the predator.
3. Maze entry gives a short warning read before hard pressure.
4. The player grabs Pages from one authored risk node.
5. Sprinting or other loud actions can pull the predator harder; stopping or
   playing carefully can buy time.
6. The player either returns with Pages or dies and receives a readable lesson.
7. Run return feedback reinforces both the Pages outcome and the learned behavior.

## Parallel Lanes

- Language: player-facing copy says `Pages`, not loot/quota/cargo, while internal
  compatibility fields may stay unchanged.
- Clue: reuse `RunClueMarker` with `ReadableTitle`, `ReadableText`, and
  `ThreatHintId`; do not add a clue schema for this slice.
- Maze: use the authored world/harness path and mark one encounter chain: entry
  buffer, warning, Pages temptation, chase trigger, and return decision.
- Threat: add only a thin sound-pressure layer on top of the current monster
  runtime; no new monster platform, no microphone input.
- Economy: make Pages, death, and return feedback readable before adding deeper
  shop or progression systems.

## First Issue Seeds

### [Kickoff] Define deadline slice playable gate

- Product: this kickoff page plus a short playtest debrief.
- Done when each gate maps to an observable player statement or action.

### [Language] Unify player-facing Pages terminology

- Product: Run HUD, objective, return, and summary copy use Pages language.
- Done when the same visible target is no longer mixed as Pages, loot, quota,
  or cargo.

### [Content] Author first corpse clue and payoff mapping

- Product: one corpse clue with title, body, `ThreatHintId`, and Maze payoff.
- Done when the clue states what it teaches, what it does not teach, and which
  player behavior should change.

### [Run] Place first teaching clue in authored Run path

- Product: one `ClueMarker_*` on a reachable side path, not a forced tutorial.
- Done when a player can naturally discover it before entering Maze.

### [Maze] Mark one playable encounter chain

- Product: authored Maze metadata identifies the first warning/payoff chain.
- Done when a level designer can point to each node role in the current world.

### [Threat] Add minimal sound-pressure behavior

- Product: loud player actions can briefly become monster targets or stronger
  chase pressure.
- Done when quieter play can visibly buy time.

### [Loop] Make return/death feedback reinforce learning

- Product: return and death messages mention both Pages and the behavior lesson.
- Done when feedback is not only a numeric settlement.

## Current Non-Goals

- Traitor or hard private-information gameplay.
- Full reveal of clones, higher systems, or the true nature of Pages.
- Full economy or shop progression.
- Multi-threat ecology.
- Monster platform rewrite.
- Internal contract field renames whose only value is terminology cleanup.

## Playtest Debrief

Ask these after the loop:

1. What did you think the assignment was?
2. Which clue or scene changed how you moved in the maze?
3. Why do you think the monster came closer or killed you?
4. When did you consider leaving with the Pages you had?
5. What would you do less of next time?
