# Deadline Slice

## Routing

- Related: `DESIGN-MAP.md`, `formal/terminology-and-player-facing-language.md`, `formal/first-30-minutes-slice-blueprint.md`
- Superseded by: None. This remains the core framing for the current deadline slice. If other docs conflict, this document takes precedence.
- Feeds into: `formal/` current confirmed documents, `candidate/crew-dynamics-and-information-asymmetry.md`, `candidate/reveal-ladder.md`


Execution companion:
`deadline-sprint.md`

## Framing

This is not an MVP note.

`Liminal` is already past the point where a bare proof-of-concept is useful.
What we need now is a deadline slice: a small but convincing version of the game
that already feels like `Liminal`, already has tension, and already teaches the
player what kind of horror game this is.

This means the goal is not:

- fixing every old mistake
- rescuing every half-built system
- proving architectural elegance
- building the full long-term feature set

The goal is:

- ship one playable `Run -> Maze -> Run` loop that already has identity
- make the player feel fragile, pressured, and information-hungry
- let `Run` produce a real cognitive advantage instead of being empty downtime
- let `Maze` pay off that information with actual danger and loot pressure
- reuse only the parts of the current codebase that help us reach that state faster

## Slice Statement

The deadline slice should let a new player:

1. spawn into camp with a clear mission to retrieve pages from the maze
2. move through wilderness where optional clues can change how they interpret danger
3. enter a visible, authored maze that already feels like a real place
4. face a high-threat chase rule that punishes panic and ignorance
5. grab pages or loot under pressure and decide whether to push deeper or retreat
6. return to camp with gains or die and lose what they carried

If those six beats work, the slice is doing its job.

## What This Slice Must Prove

### 1. The loop is readable

Players should immediately understand that the game is about going out, taking
risk, and bringing something back.

### 2. Knowledge changes behavior

A clue found in `Run` should matter in `Maze`.
The player should be able to say, in plain language, `we survived that better because we learned something before going in`.

### 3. The player is weak by default

The fantasy is not power.
The fantasy is surviving something stronger by reading it correctly.

### 4. The maze is already a place, not a placeholder

The player should not feel like they entered an empty test chamber.
They should feel like they entered a real authored death-space with geometry,
cover, approach lanes, doors, loot points, and threat staging.

### 5. The fiction already colors the loop

Even if the deeper truth is not fully explained, the slice should already feel
like the players are carrying out assigned labor for something larger than
themselves.

## Player-Facing Promise

For the deadline slice, the simplest honest promise is:

`You are sent out to recover pages from a lethal maze. You are fragile. If you
want to come back alive, you must learn faster than the place kills you.`

This is gameplay-first language.
It leaves room for the deeper clone-body and higher-dimensional exploitation
fiction to emerge later without over-explaining it now.

## The Minimum Coherent Experience

The slice does not need the whole game.
It needs one coherent story of play:

- camp gives mission framing, entry point, and tool context
- wilderness gives at least one meaningful optional clue detour
- maze gives at least one memorable lethal rule payoff
- pages serve as the retrieval objective and player-facing economy currency
- retreat, death, and successful return all produce understandable outcomes

If any of those beats are absent, the slice will feel like disconnected systems
instead of a game.

## Reuse-First Reading Of The Existing Codebase

There is already enough structure in the repo to avoid a restart.
The correct move is selective reuse.

### Reuse directly

#### `Run` authored interaction layer

Use the current `Run` authored-world and clue pipeline as the base for deadline
content.

Relevant files:

- `places/run/src/ServerScriptService/Run/RunClueMarker.luau`
- `places/run/src/ServerScriptService/Run/RunInteractionRegistry.luau`
- `places/run/src/ServerScriptService/Run/RunScene.luau`
- `places/run/src/ServerScriptService/Run/RunSessionService.luau`

Why this matters:

- clue markers already exist as authored prompt-driven interactions
- clue text, title, and `ThreatHintId` are already supported
- discovered clues already enter player inventory and private feedback
- this is enough for the first wilderness clue pass without inventing a new system

#### `Maze` authored static world and interaction layer

Use the authored maze world as the content root instead of rebuilding the place
from scratch.

Relevant files:

- `places/maze/src/ServerScriptService/Maze/MazeStaticWorldAssembler.luau`
- `places/maze/src/ServerScriptService/Maze/MazeScene.luau`
- `places/maze/src/ServerScriptService/Maze/MazeInteractionRegistry.luau`
- `packages/shared/src/Runtime/MazeWorldScanner.luau`

Why this matters:

- the maze already has a stable authored contract
- `Scenery` is already treated as non-gameplay geometry and ignored by scanning
- loot nodes, doorways, room affordances, spawn markers, and return pads already exist
- the harness can now function as the visual authoring truth for the slice

#### Session handoff and return loop

Use the existing cross-place session transport instead of redesigning the loop.

Relevant files:

- `packages/shared/src/Session/CampMazeSessionContract.luau`
- `packages/shared/src/Config/SessionConfig.luau`
- `places/run/src/ServerScriptService/Run/RunToMazeTransition.luau`
- `places/maze/src/ServerScriptService/Maze/MazeToRunTransition.luau`

Why this matters:

- the project already knows how to move players across the `Run -> Maze -> Run` boundary
- inventory summaries and return outcomes already have a contract shape
- this is the backbone of the slice and does not need reinvention right now

#### Fragility, stamina, and inventory pressure

Keep the current player weakness layer and build the slice around it.

Relevant files:

- `packages/gameplay/src/PlayerState.luau`
- `packages/gameplay/src/ControlState.luau`
- `packages/shared/src/Runtime/PlayerStateService.luau`
- `packages/shared/src/Runtime/InventoryService.luau`

Why this matters:

- stamina drain, sprint gating, death state, and corpse flags already exist
- inventory already supports clue items, loot, tools, and mission cargo summaries
- this is enough to support the current fantasy that survival depends on restraint and judgment

### Adapt lightly, do not rebuild

#### Monster runtime

Relevant files:

- `packages/shared/src/Runtime/MonsterService.luau`
- `packages/shared/src/Runtime/MonsterRuntime/*`
- `packages/gameplay/src/Monsters/*`

Current reading:

- there is already a chase-and-attack monster runtime foundation
- there is not yet a slice-ready, authored, sound-first predator loop
- therefore the deadline move is not `design the full monster platform`
- the deadline move is `add the thinnest possible sound-driven aggro layer on top of the existing chase runtime`

This means:

- no broad monster architecture rewrite
- no attempt to solve all future monster types first
- one primary predator fantasy first, using the smallest amount of new systemic work

A good deadline version is allowed to be narrow and authored.
It does not need to be a universal AI framework.

#### Objective and economy copy

Camp terminals and mission framing already exist, but the presentation still
needs stronger fiction and clearer player-facing language.

This should be treated as content and UX work, not a new system.

## Must-Ship Mechanics For The Deadline Slice

### 1. Mission framing in camp

The player must know, immediately, that the job is to enter the maze and recover
pages.

Needed outcome:

- no ambiguity about the short-term goal
- enough fiction to feel assigned, not self-motivated
- no long lore dump required

### 2. Optional clue discovery in wilderness

There must be at least one clue path in `Run` that rewards curiosity.

Needed outcome:

- the clue is off the most obvious route, but not impossible to find
- it communicates something actionable about danger
- it changes player interpretation before maze entry

### 3. Authored visible maze geometry

The player must enter a maze that already looks authored and supports placement
of real local assets.

Needed outcome:

- visible floor, walls, and space language in edit mode and play mode
- `Workspace/MazeStaticWorld/Scenery` acts as the main static art container
- no dependency on Roblox's default `Baseplate`

### 4. Primary threat payoff

The slice needs one signature threat, not a full ecology.

Current best candidate:

- a fast hearing-based hunter that turns panic into death pressure

But the deadline interpretation should stay practical:

- one monster type is enough
- one strong chase loop is enough
- full microphone simulation is not required for the slice
- if needed, sound can first be represented through authored triggers and player action proxies
  such as sprinting, door use, alarms, or other explicit noise events

### 5. Retrieval and return pressure

Players must physically go in, collect pages, and make a decision about getting
out.

Needed outcome:

- carrying loot matters
- death costs something real
- successful return feels like progress

### 6. One clear consequence loop

The player should understand:

- what they gained by returning
- what they lost by dying
- why the next round matters

## Systems To Keep Narrow On Purpose

These are important, but the slice should keep them deliberately small.

### Clue system

Keep to a small authored set.
Do not build a giant content taxonomy yet.

### Economy

Pages can already act as player-facing currency and mission objective.
Do not solve the entire future shop meta before the slice works.

### Narrative delivery

Use mission tone, environmental implication, and small fragments.
Do not explain the entire clone-body truth upfront.

### Threat roster

One main predator can carry the slice.
Small enemies, traps, and role variants should only ship if they clearly help the
same loop and do not dilute it.

## Systems To Defer

These are promising, but they are not deadline-critical.

- traitor or infiltrator social play
- robust true-vs-false clue generation systems
- full multi-monster ecology with three equally deep behavior models
- microphone-driven detection as a hard dependency
- broad procgen expansion
- polishing every old generalized system until it becomes elegant
- deeper meta-progression beyond what the current economy needs to communicate

## Explicit Anti-Goals

To protect the slice, we should say no to the following moves.

### Do not run a repo-wide refactor campaign

A clean architecture pass is not the deliverable.
A playable, convincing slice is.

### Do not treat old code as sacred

Reuse code because it accelerates the slice, not because it already exists.
If a system is elaborate but not helping the current game, ignore it.

### Do not let future ambition block present shipping

The eventual game may include betrayal layers, richer clue economies, and many
monster types.
The deadline slice does not need all of that to be real yet.

### Do not over-tutorialize the horror

The player should learn through mission context, spatial cues, clues, and lived
mistakes.
Not through walls of explanation.

## Recommended Build Order

### Stage 1: lock the authored spaces

- keep `Run` readable as camp plus wilderness pathing
- keep `Maze` readable as a visible authored place with real scenery
- place the first local art assets into `MazeStaticWorld/Scenery`

### Stage 2: lock the player loop

- mission framing in camp
- optional wilderness clue pickup
- maze entry
- page pickup
- return or death consequence

### Stage 3: lock the signature danger

- implement the thinnest effective version of the sound-driven predator fantasy
- make sure the player can understand the cause of death after a failure
- make sure the wilderness clue actually helps against that threat

### Stage 4: add only the content that sharpens the same loop

- stronger clue scene dressing
- stronger page placement and risk staging
- better mission copy and camp framing
- one or two supporting hazards only if they reinforce fragility and judgment

## Working Rule For The Team

When deadline pressure creates doubt, use this test:

`Does this help a player feel the Run -> Maze -> Run knowledge-survival loop more clearly in the next playable build?`

If yes, it is probably in scope.
If no, it is probably a later problem.

## Definition Of Success

The deadline slice succeeds if a playtester can say all of the following after a
short session:

- `I understood why I was going into the maze.`
- `I found or heard something outside the maze that changed how I played inside it.`
- `The maze felt like a real place, not a graybox placeholder.`
- `I died because I handled the danger badly, not because the game was unreadable.`
- `When I came back with pages, it felt like I had actually completed a job.`

If those statements become true, `Liminal` has a real slice worth building on.
