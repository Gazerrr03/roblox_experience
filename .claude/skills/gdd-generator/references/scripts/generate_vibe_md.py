"""
generate_vibe_md.py
-------------------
Generates draft VIBE.md and NOW.md files from GDD JSON content.

Usage:
    python scripts/generate_vibe_md.py --config gdd_content.json --place run --output references/gdd-output/run-VIBE.draft.md

Requirements:
    pip install -r requirements.txt
"""

import argparse
import json
import os
import sys
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, SCRIPT_DIR)


VIBE_TEMPLATE = """# {place_name} Vibe

## Human First

### Gameplay Template

- This place is {gameplay_template}
- The player should feel {player_feel}
- The place ends or hands off when {handoff}

### Mental Model

- Server authority lives in {server_authority}
- Client presentation lives in {client_presentation}
- This place owns {place_owns}
- This place depends on `contract` for {contract_dep}

### Key State Flow

1. Players arrive from {arrival}
2. The main loop is {main_loop}
3. Exit or handoff happens through {exit_handoff}

## Agent First

### Entry Files

- Server bootstrap: `places/{place_name}/src/ServerScriptService/Bootstrap.server.luau`
- Main service: `places/{place_name}/src/ServerScriptService/{PlaceName}/{PlaceName}Service.luau`
- Main client: `places/{place_name}/src/StarterPlayer/StarterPlayerScripts/{PlaceName}Client.client.luau`
- Place project file: `places/{place_name}/default.project.json`

### Allowed Change Graph

Owner zone:

- `places/{place_name}/**`

Direct dependency zone:

- `packages/shared/src/Config/SessionConfig.luau`
- `packages/shared/src/Network/Remotes.luau`
- `packages/shared/src/Session/CampMazeSessionContract.luau`
- `packages/shared/src/Util/TeleportDiagnostics.luau`

No-touch zone:

- `places/{{other_places}}/**` unless the issue is explicitly cross-domain
- `packages/shared/src/Session/` and `packages/shared/src/Network/` when changing contract/remote shapes

Boundary interfaces:

- Remotes: {remotes}
- Shared handoff: {shared_handoff}
- Shared config: {shared_config}
- Deterministic tests: {tests}

### When To Start In Contract Instead

- If this change alters cross-place agreement
- If remote names or payload shapes need to change
- If session handoff semantics need to evolve

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/{place_name}/default.project.json -o .\\\\tmp\\\\{place_name}.rbxlx`

## Notes

- Keep the stable handbook durable. Put short-lived concerns in `NOW.md`.
"""

NOW_TEMPLATE = """# {place_name} NOW

## Current Pressure Points

<!-- What is blocking progress or creating risk right now? -->

- {pressure_points}

## In-Flight Work

<!-- What work is actively being done? -->

- {in_flight}

## Next Actions

<!-- What should happen next? Who should do it? -->

- {next_actions}

---

_Last updated: {date}_
"""


def parse_gdd_config(config: dict, place: str) -> dict:
    """Extract relevant fields from GDD JSON config for VIBE.md/NOW.md generation."""

    sections = config.get("sections", {})

    # Game Overview
    game_overview = sections.get("game_overview", {})
    high_concept = game_overview.get("high_concept", "...")
    core_fantasy = game_overview.get("core_fantasy", "...")
    experience_pillars = game_overview.get("experience_pillars", [])

    # Session Flow
    session_flow = game_overview.get("session_flow", "")

    # Core Gameplay Loop
    loop_section = sections.get("core_gameplay_loop", {})
    micro_loop = loop_section.get("micro_loop", "...")
    macro_loop = loop_section.get("macro_loop", "...")
    meta_loop = loop_section.get("meta_loop", "...")

    # Roblox Multiplayer
    multiplayer = sections.get("roblox_multiplayer", {})
    remotes = multiplayer.get("remotes", [])
    teleport_contract = multiplayer.get("teleport_contract", "")

    # Game Mechanics
    mechanics = sections.get("game_mechanics", {})
    key_mechanics = list(mechanics.keys())[:3] if mechanics else []

    # Development Roadmap
    roadmap = sections.get("development_roadmap", {})
    milestones = roadmap.get("milestones", [])

    # Parse vibes integration
    vibes_integration = sections.get("vibe_framework_integration", {})
    vibe_affected = vibes_integration.get("affected_places", [])
    vibe_next_actions = vibes_integration.get("next_actions", [])

    return {
        "place_name": place,
        "PlaceName": place.capitalize(),
        "gameplay_template": high_concept,
        "player_feel": core_fantasy,
        "handoff": "completion or player quit",
        "server_authority": f"{place.capitalize()}Service",
        "client_presentation": f"{place.capitalize()}Client",
        "place_owns": ", ".join(key_mechanics) if key_mechanics else "core gameplay",
        "contract_dep": "session handoff, remotes, place routing config",
        "arrival": "lobby (for new session)" if "lobby" in vibe_affected else "other places",
        "main_loop": f"{micro_loop[:100]}... (see GDD Section 4)",
        "exit_handoff": teleport_contract if teleport_contract else "maze gate or player quit",
        "remotes": ", ".join(remotes) if remotes else "RunAction, RunSnapshot, PrivateState",
        "shared_handoff": "CampMazeSessionContract",
        "shared_config": "SessionConfig.PlaceIds, SessionConfig.MaxPartySize",
        "tests": "tests/src/Shared/CampMazeSessionContract.spec.luau",
        "pressure_points": "\n- ".join(vibe_next_actions[:3]) if vibe_next_actions else "TBD",
        "in_flight": "GDD documentation in progress",
        "next_actions": "\n- ".join(vibe_next_actions) if vibe_next_actions else "Review GDD outline\n- Approve scope\n- Start contract-first if needed",
        "date": datetime.now().strftime("%Y-%m-%d"),
    }


def generate_vibe_md(data: dict) -> str:
    """Generate VIBE.md content from parsed data."""
    return VIBE_TEMPLATE.format(**data)


def generate_now_md(data: dict) -> str:
    """Generate NOW.md content from parsed data."""
    return NOW_TEMPLATE.format(**data)


def main():
    parser = argparse.ArgumentParser(
        description="Generate VIBE.md and NOW.md drafts from GDD JSON content"
    )
    parser.add_argument(
        "--config",
        required=True,
        help="Path to GDD JSON config file",
    )
    parser.add_argument(
        "--place",
        required=True,
        help="Place name (lobby, run, maze, or new place)",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Output path for VIBE.md draft",
    )
    parser.add_argument(
        "--now-output",
        help="Output path for NOW.md draft (optional, defaults to replacing VIBE with NOW in output path)",
    )

    args = parser.parse_args()

    # Load config
    with open(args.config, "r", encoding="utf-8") as f:
        config = json.load(f)

    # Parse
    data = parse_gdd_config(config, args.place)

    # Generate VIBE.md
    vibe_content = generate_vibe_md(data)

    # Write VIBE.md draft
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    with open(args.output, "w", encoding="utf-8") as f:
        f.write(vibe_content)

    print(f"VIBE.md draft written to: {args.output}")

    # Generate NOW.md if output specified
    now_output = args.now_output
    if not now_output:
        # Replace VIBE with NOW in path
        now_output = args.output.replace("-VIBE.draft.md", "-NOW.draft.md")

    now_content = generate_now_md(data)
    with open(now_output, "w", encoding="utf-8") as f:
        f.write(now_content)

    print(f"NOW.md draft written to: {now_output}")


if __name__ == "__main__":
    main()
