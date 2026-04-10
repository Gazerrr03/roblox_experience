# GDD Master Structure (Roblox-Adapted)

20-section Game Design Document structure adapted for Roblox experiences.
Base: game-design-document by ityes22, adapted for roblox_experience vibe framework.

---

## Section Dependency Map

```
[1. Cover Page] -> [2. Executive Summary] -> [3. Game Overview]
       |                                         |
       v                                         v
[4. Core Gameplay Loop] -> [5. Game Mechanics] <-----+
       |                                       |     |
       v                                       |     |
[6. Progression System] <---------------------+     |
       |                                          |
       v                                          |
[7. Content Design] <- informed by -- [8. Narrative]
       |                                       |     |
       v                                       v     |
[9. UX & Interface] <-------------------------+-----+
       |
       v
[10. Art Direction] -> [11. Audio] -> [12. Roblox Multiplayer]
       |
       v
[13. Monetization] -> [14. Economy]
       |
       v
[15. Technical Requirements] <- informs -- [12. Roblox Multiplayer]
       |
       v
[16. Competitive Analysis] -> informs -- [3. Game Overview]
       |
       v
[17. Development Roadmap] <- scope from -- all prior sections
       |
       v
[18. Risk Assessment] <- risks from -- all prior sections
       |
       v
[19. Appendices]
       |
       v
[20. Vibe Framework Integration]
```

---

## Section-by-Section Requirements

### 1. Cover Page
**Required elements:** Title, tagline, version, confidentiality notice, date, lead designer
**Roblox-specific:** Include Roblox experience URL or place ID if applicable

### 2. Executive Summary
**Word count:** 400-600
**Required elements:**
- 2-3 sentence elevator pitch
- Unique Value Proposition (3 bullets)
- At-a-glance table (genre, platform, audience, session length, monetization)
- Comparable titles
- Team overview

### 3. Game Overview
**Word count:** 600-1000
**Required elements:**
- High concept (one sentence)
- Core fantasy (what players feel)
- 3-4 Experience pillars
- Session flow narrative
**Roblox-specific:** Reference vibe places (lobby/run/maze) and their roles

### 4. Core Gameplay Loop
**Word count:** 800-1500
**Required elements:**
- Micro loop (moment-to-moment, 1-5 min)
- Macro loop (session structure, 15-60 min)
- Meta loop (progression across sessions)
- Engagement hooks
- ASCII loop diagrams
**Roblox-specific:** Map loops to existing vibe places

### 5. Game Mechanics
**Word count:** 1500-3000
**Required elements per mechanic:**
- **Input:** Player action
- **System:** Logic (server authority preferred)
- **Feedback:** Client presentation
- **Parameters:** Concrete numbers
- **Rationale:** Why this design decision
**Roblox-specific:**
- Specify RemoteEvent/RemoteFunction names
- State server vs client authority explicitly
- Note DataModel paths (Workspace/Entities/)
- Reference existing Remotes in `packages/shared/src/Network/Remotes.luau`

### 6. Progression System
**Word count:** 800-1500
**Required elements:**
- XP table structure
- Level pacing curves
- 3 archetype timelines (casual/average/hardcore)
- Unlock milestones
**Roblox-specific:** Reference Luau module paths for progression config

### 7. Content Design
**Word count:** 800-1500
**Required elements:**
- Content scope table
- Level/enemy/item creation guidelines
- Launch minimum
- Post-launch content pipeline
**Roblox-specific:** Map content to vibe place ownership

### 8. Narrative & World
**Word count:** 500-1200 (optional if not narrative-driven)
**Required elements:**
- Setting and lore depth
- Story structure
- Key characters
**Roblox-specific:** Note if narrative is client-side or replicated

### 9. UX & Interface
**Word count:** 800-1500
**Required elements:**
- Screen inventory
- FTUE flow (0-1, 1-5, 5-15, 15-30 min marks)
- Accessibility considerations
**Roblox-specific:**
- Reference Roblox GUI system (ScreenGuis, Frame hierarchy)
- Note any custom UI packages from `packages/ui/src`
- Reference input system (UserInputService, ContextActionService)

### 10. Art Direction
**Word count:** 500-800
**Required elements:**
- Visual style description
- Influences and references
- Color palette (specific hex codes)
- Guidelines for characters, environments, UI
**Roblox-specific:** Note any Roblox-native rendering considerations

### 11. Audio Design
**Word count:** 300-500
**Required elements:**
- Music direction per game state
- SFX philosophy
- Voice scope and budget
**Roblox-specific:** Reference Roblox SoundService and AudioId system

### 12. Roblox Multiplayer & Networking
**Word count:** 800-2000
**Required elements:**
- Network model (server authoritative preferred)
- Tick rate and update strategy
- Matchmaking approach
- Latency tolerance thresholds
**Roblox-specific:**
- Reference vibe place architecture (lobby/run/maze/contract)
- Document teleport contracts via `CampMazeSessionContract`
- Reference RemoteEvent/RemoteFunction patterns
- Note DataModel replication behavior
- Document session handoff between places
- Reference `SessionConfig.PlaceIds` routing

### 13. Monetization Strategy
**Word count:** 600-1200
**Required elements:**
- Revenue model (DevEx focus)
- IAP catalog
- Battle pass or subscription if applicable
- Ethical guidelines
- KPIs (DAU, ARPU, conversion rate)
**Roblox-specific:**
- Document Developer Exchange (DevEx) approach
- Reference GamePasses and Developer Products
- Note Roblox COPPA compliance considerations

### 14. Economy Design
**Word count:** 600-1200
**Required elements:**
- Currency types (premium vs soft)
- Faucet/sink balance
- Earn rates per player segment
- Exchange rates if applicable
**Roblox-specific:** Reference Robux as premium currency

### 15. Technical Requirements
**Word count:** 500-1000
**Required elements:**
- Engine and platform targets
- Hardware specifications
- SDKs and middleware
- Performance budget
**Roblox-specific:**
- Engine: Roblox (no external engine)
- Toolchain: Luau, Rojo, Wally, selene, stylua
- Studio version requirement
- Plugin dependencies
- Reference `packages/shared`, `packages/gameplay`, `packages/ui`
- Note any native code (C++ plugins) requirements

### 16. Competitive Analysis
**Word count:** 600-1000
**Required elements:**
- 3-5 competitor experiences
- Feature comparison matrix
- Market gap analysis
- Differentiation strategy

### 17. Development Roadmap
**Word count:** 400-800
**Required elements:**
- Phase milestones: Prototype -> Alpha -> Beta -> Launch
- Success criteria per milestone
- Team capacity assumptions
**Roblox-specific:** Reference vibe place delivery order

### 18. Risk Assessment
**Word count:** 400-600
**Required elements:**
- Risk register table: Risk | Category | Probability | Impact | Mitigation
**Roblox-specific:** Note Roblox platform-specific risks (API changes, policy updates)

### 19. Appendices
**As needed**
- Glossary
- Revision history
- Open questions log
- Data sensitivity citations

### 20. Vibe Framework Integration
**Purpose:** Maps GDD content to the existing roblox_experience vibe framework documentation
**Required elements:**
- Which vibe place(s) this GDD affects
- Existing VIBE.md files that should be updated
- Cross-place dependencies (contract changes required)
- New files to create under `places/<place>/`
- Integration with existing `packages/shared` modules
**Roblox-specific:**
- Reference the 4 vibe places: lobby, run, maze, contract
- Note if contract-first approach is needed before place-local changes
- Reference `packages/shared/src/Session/CampMazeSessionContract.luau` for teleport contracts
- Reference `packages/shared/src/Network/Remotes.luau` for remote definitions

---

## Roblox Vibe Place Reference

| Place | VIBE.md | Owned By | Key Remotes |
|-------|---------|----------|-------------|
| lobby | `places/lobby/VIBE.md` | LobbyService | LobbyAction, LobbyState |
| run | `places/run/VIBE.md` | RunSessionService | RunAction, RunSnapshot, PrivateState |
| maze | `places/maze/VIBE.md` | MazeSessionService | (reuses run remotes) |
| contract | `packages/shared/VIBE.md` | Session/Network/Config | CampMazeSessionContract |

---

## Validation Commands

After updating VIBE.md/NOW.md from GDD content:
```bash
stylua --check places/<place>/**/*.luau
selene places/<place>/**/*.luau
rojo build places/<place>/default.project.json -o tmp/<place>.rbxlx
```
