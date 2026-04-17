# {place_name} Vibe

## Human First

### Gameplay Template

- This place is ...
- The player should feel ...
- The place ends or hands off when ...

### Mental Model

- Server authority lives in ...
- Client presentation lives in ...
- This place owns ...
- This place depends on `contract` for ...

### Key State Flow

1. Players arrive from ...
2. The main loop is ...
3. Exit or handoff happens through ...

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

- `places/{other_places}/**` unless the issue is explicitly cross-domain
- `packages/shared/src/Session/` and `packages/shared/src/Network/` when changing contract/remote shapes

Boundary interfaces:

- Remotes:
- Shared handoff:
- Shared config:
- Deterministic tests:

### When To Start In Contract Instead

- If this change alters cross-place agreement
- If remote names or payload shapes need to change
- If session handoff semantics need to evolve

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/{place_name}/default.project.json -o .\\tmp\\{place_name}.rbxlx`

## Notes

- Keep the stable handbook durable. Put short-lived concerns in `NOW.md`.
