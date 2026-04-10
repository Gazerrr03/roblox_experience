# Example GDD Output: "run" Place

> This is a condensed example showing what the GDD generator might produce for the `run` vibe place.

---

## 2. Executive Summary

**Elevator Pitch:** A camp-and-expedition hub where players prepare for maze runs, receive returning explorers, and manage resources between expeditions.

**Unique Value Proposition:**
- Seamless lobby-to-run-to-maze session flow
- Server-authoritative expedition state
- Shared progression across all place transitions

**At-a-Glance:**
| Field | Value |
|-------|-------|
| Genre | Co-op Adventure / Extraction |
| Platform | Roblox |
| Audience | Teens, casual to mid-core |
| Session Length | 10-30 min |
| Monetization | DevEx, Game Passes |

---

## 3. Game Overview

**High Concept:** A base camp hub where players coordinate before entering procedurally-generated mazes and return with loot to upgrade their camp.

**Core Fantasy:** "We're a crew of explorers preparing for the unknown — together we venture in, and together we return richer."

**Experience Pillars:**
1. **Preparation** — Time in camp feels meaningful; upgrades are visible
2. **Expedition** — Maze runs are tense but fair; server authority ensures fairness
3. **Return** — Coming back with loot is satisfying; handoff to settlement is smooth

**Session Flow:**
```
lobby -> [teleport] -> run (camp) -> [teleport gate] -> maze -> [teleport return] -> run (settlement) -> lobby
```

---

## 4. Core Gameplay Loop

**Micro Loop (1-5 min):**
```
Explore Camp UI -> Start Expedition -> Enter Maze Gate -> Complete Maze Objective -> Trigger Extraction
```

**Macro Loop (15-30 min):**
```
Arrive at Camp -> Check Loadout -> Enter Maze -> Navigate/Combat/Puzzle -> Loot Collection -> Extract -> Camp Upgrade -> Repeat
```

**Meta Loop (multiple sessions):**
```
Earn XP/Currency -> Upgrade Camp -> Unlock New Maze Areas -> Repeat with harder content
```

---

## 5. Game Mechanics (Key Mechanic: Maze Gate Entry)

**Input:** Player presses "Enter Maze" button on camp UI
**System:**
- Client sends `RunAction:RequestMazeEntry` via RemoteEvent
- Server validates `MazeEntryAvailability.canEnter(player)` via `CampMazeSessionContract`
- If valid, server calls `TeleportService:TeleportAsync()` with `CampMazeSessionContract.buildLobbyToCampTeleportData()`
**Feedback:** Client shows loading screen, then maze spawns
**Parameters:**
- Cooldown: None (gated by session state)
- Max party size: 4 (config: `SessionConfig.MaxPartySize`)
**Rationale:** Server authority prevents client-side cheats; teleport data is built in contract to keep place logic thin

---

## 12. Roblox Multiplayer & Networking

**Model:** Server-authoritative. All game logic runs on server; clients send intent only.

**Vibe Place Architecture:**
- `lobby`: Crew assembly, ready state → teleports to `run`
- `run`: Camp orchestration, maze gate → teleports to `maze`
- `maze`: Expedition runtime → teleports back to `run`
- `contract`: Shared session/teleport contracts live in `packages/shared/src/Session/`

**Teleport Contract:**
```lua
-- packages/shared/src/Session/CampMazeSessionContract.luau
CampMazeSessionContract.buildLobbyToCampTeleportData(session, players)
CampMazeSessionContract.buildMazeToCampTeleportData(session, players)
CampMazeSessionContract.reconcileIncomingCampSession(teleportData)
```

**Remote Events:**
| Remote | Direction | Purpose |
|--------|-----------|---------|
| `LobbyAction` | Client -> Server | Ready toggle, start request |
| `LobbyState` | Server -> Client | Roster broadcast |
| `RunAction` | Client -> Server | Maze entry request, camp interaction |
| `RunSnapshot` | Server -> Client | Camp state, expedition status |
| `PrivateState` | Server -> Client | Per-player private data |

---

## 15. Technical Requirements

**Toolchain:**
- Luau (Roblox's Lua dialect)
- Rojo 8.x for project serialization
- Wally for package management
- selene + stylua for code quality

**Key Packages:**
- `packages/shared/` — Session contracts, remotes, config
- `packages/gameplay/` — Pure gameplay logic
- `packages/ui/` — Shared UI components

**Studio Version:** 2024.3+ recommended

---

## 20. Vibe Framework Integration

**This GDD affects:** `places/run/VIBE.md`, `places/run/NOW.md`

**Existing files to update after GDD approval:**
- `places/run/VIBE.md` — Update "Mental Model" and "Key State Flow" sections
- `places/run/NOW.md` — Update "Next Actions" based on development roadmap

**Cross-place dependencies:**
- `packages/shared/src/Session/CampMazeSessionContract.luau` — May need new fields for run-side camp state
- `packages/shared/src/Network/Remotes.luau` — No changes expected for this GDD

**Contract-first requirement:** No contract changes needed for initial run camp scope.
