# Deadline Sprint Map

## Routing

- Related: `DESIGN-MAP.md`, `formal/round-pacing-and-economy.md`
- Superseded by: 无。它仍然是当前 slice 的 execution companion。
- Feeds into: `formal/* 文档中的 Slice Rule`, `后续内容与实现排期`


Companion to `deadline-slice.md`.

`deadline-slice.md` explains why this slice matters.
This file explains what we should ship, what we should reuse, and what we
should intentionally leave alone while the deadline is close.

## 1. Shipping Thesis

The deadline build should already feel like a real `Liminal` session:
players leave camp with a clear assignment, optionally discover useful
information in the wilderness, enter an authored maze to recover pages, survive
one signature threat by reading it correctly, and either bring pages home or
lose them by dying.

Important framing for this sprint:

- this is not an MVP checklist
- this is not a repo-cleanup campaign
- this is not a broad system unification pass
- pages are the official player-facing target language for the slice
- existing `loot item count` wording in the repo is treated as historical
  implementation language, not design truth

Repo read that supports this direction:

- `run` already owns camp orchestration, wilderness clue discovery, and the
  run-to-maze handoff
- `maze` already owns authored expedition content, scene binding, and the
  return flow
- `contract` already owns the cross-place session and inventory handoff that
  lets clue items, tools, and drops persist across the loop
- recent repo merges already pushed the project toward this shape: the
  5-round mission loop, the authored static-world maze path, and the
  return-only maze exit flow

## 2. Sprint Backlog

### Must Ship

- camp mission framing that clearly tells players to enter the maze and recover
  pages
- at least one wilderness clue detour that rewards curiosity and teaches a
  useful threat rule before maze entry
- an authored maze that is already visible, editable, and spatially legible in
  `MazeStaticWorld`
- one signature sound-driven predator payoff inside the maze
- page pickup, retreat, death loss, and successful return as one readable
  consequence loop
- enough environmental and UI copy cohesion that players can explain the
  session in one sentence after a short playtest

### Should Ship

- stronger camp copy so the mission feels assigned rather than self-directed
- stronger route guidance from ship to wilderness to maze without hard
  corridoring the player
- one or two authored threat-tell moments inside the maze that echo the
  wilderness clue
- better placement of local art assets inside maze scenery to make the place
  feel intentional rather than scaffolded
- lightweight support tools that make the predator rule easier to read, as long
  as they do not require a new progression system

### Defer

- traitor or infiltrator play
- robust true-vs-false clue systems
- multi-monster ecology with equal design depth
- microphone-driven detection as a slice dependency
- broad procgen expansion
- remote surface renaming and shared seam cleanup that is not required by this
  sprint
- generalized architecture cleanup for items, monsters, or world authoring

## 3. Reuse Map

### `run`

Role in this sprint:
camp shell, wilderness clue shell, mission framing shell.

#### Reuse directly

- authored clue pickup flow through `RunClueMarker`, `RunInteractionRegistry`,
  `RunScene`, and `RunSessionService`
- current round/session orchestration and ship-side pacing
- current run-to-maze transition adapter
- current private clue delivery and inventory insertion path

Why:

- this is already the closest thing to the intended wilderness teaching layer
- the repo already supports private clue discovery without inventing new tech

#### Adapt carefully

- camp wording and mission wording that still reads more like loot accounting
  than page recovery fiction
- clue placement, clue dressing, and route guidance through the wilderness
- any surviving UI or status text that weakens the pages-first read of the
  session

#### Do not invest now

- large recovery of older wilderness narrative systems just because they exist
- run-side feature growth that does not sharpen clue discovery or mission
  framing
- turning `RunSessionService` into the home for more one-off scene rules

### `maze`

Role in this sprint:
authored lethal space, page retrieval shell, threat payoff shell.

#### Reuse directly

- `MazeStaticWorldAssembler` plus authored `MazeStaticWorld` as the place root
- `MazeScene`, `MazeInteractionRegistry`, and `MazeWorldScanner` for room,
  loot, doorway, and return binding
- current expedition persistence loop for collected loot, dropped inventory,
  and return flow
- current authored `Scenery` contract, where geometry remains visible but is
  ignored by gameplay scanning

Why:

- the maze already has the correct authored-world shape for a deadline slice
- the current harness work makes the maze visible and editable without
  depending on a Roblox baseplate

#### Adapt carefully

- the sound-driven predator hookup, which should be a thin extension on top of
  existing monster runtime, not a new monster platform
- page placement and threat staging inside authored rooms
- local art asset placement inside `MazeStaticWorld/Scenery`
- authored threat-tell nodes that echo wilderness clues

#### Do not invest now

- procgen-first direction changes
- multi-threat roster expansion
- broad maze-side service cleanup unrelated to the signature danger loop

### `contract`

Role in this sprint:
run/maze handoff shell, persistence shell, shared semantics shell.

#### Reuse directly

- current `CampMazeSessionContract`
- current run-to-maze and maze-to-run teleport shaping
- current clue/tool/inventory persistence behavior across place boundaries
- current returned-summary flow

Why:

- the loop already depends on these semantics working across both places
- this is where the project already preserves clue metadata and carried items

#### Adapt carefully

- only the specific cross-place semantics that become necessary to support the
  page-first slice language or the death/return loop
- any shared wording or snapshot semantics that directly block the slice from
  reading coherently

#### Do not invest now

- remote renaming for cleanliness alone
- broad `run`-flavored naming cleanup
- teleport seam redesign unless a concrete slice blocker appears

Implementation guardrail:

- if later execution requires a real cross-place semantic change, stage it as
  `contract` first, then update `run` and `maze` consumers after that

## 4. Small Parts Placement

This sprint should keep small systems attached to the outer shells instead of
letting them become their own independent delivery lines.

### Monster runtime

- home: `maze`
- use: support one signature sound-driven predator
- rule: consume the existing chase/attack runtime as a base and add the
  thinnest possible sound-response layer
- not now: universal monster framework redesign

### Item and inventory layer

- home: `contract` plus the `run -> maze -> run` loop seam
- use: carry pages, clues, tools, drops, and cross-place persistence
- rule: treat inventory as loop plumbing, not as an architecture beautification
  project
- not now: wide item-system cleanup

### Player fragility and control

- home: `maze` payoff layer
- use: stamina, sprinting cost, fragility, death, and pressure
- rule: keep the player weak so clue knowledge matters
- not now: RPG-like growth or large combat expansion

### Held tools and support interactions

- home: `run` and `maze` as consumers, shared/gameplay modules as primitives
- use: flashlight, crowbar, and similar tools only when they sharpen the same
  survival loop
- rule: reuse current held-item visuals and use requests if they help read the
  space or the threat
- not now: tool proliferation or a deep equipment meta

### Scene and world binding

- home: local to `run` and `maze`
- use: authored objects should keep binding through place-local wrappers and
  registries
- rule: do not chase a unified world framework in shared runtime just because
  both places have scanners and scene objects

### Session handoff

- home: `contract`
- use: keep round continuity, inventory continuity, and return outcomes readable
- rule: only touch this seam if the slice genuinely needs a new shared meaning

## 5. Non-Goals

This sprint is not trying to prove system elegance.
It is trying to prove that one coherent, tense, page-retrieval horror loop is
already real.

Therefore the following are explicit non-goals:

- cleaning every old naming mismatch in the repo
- normalizing every historical design direction into one final architecture
- expanding run content that does not improve mission framing or clue payoff
- expanding maze systems that do not improve threat readability or page
  retrieval tension
- growing small parts into independent projects
- solving long-term social deception now
- rebuilding shared contracts unless the sprint genuinely cannot ship without it

Definition of done for this document:

- a reader can identify what must ship versus what is intentionally deferred
- a reader can say which existing systems should be reused immediately
- a reader can say which systems should only receive thin adaptation
- a reader can say which tempting cleanup paths are not worth the deadline
  budget
