# <place> Vibe

## Human First

### Gameplay Template

- This place exists to ...
- The player should feel ...
- The place ends or hands off when ...

### Mental Model

- Server authority lives in ...
- Client presentation lives in ...
- This place depends on `contract` for ...

### Key State Flow

1. Players arrive from ...
2. The main loop is ...
3. Exit or handoff happens through ...

## Agent First

### Entry Files

- Server bootstrap: `places/<place>/src/ServerScriptService/Bootstrap.server.luau`
- Main service:
- Main client:
- Place project file: `places/<place>/default.project.json`

### Allowed Change Graph

Owner zone:

- `places/<place>/**`

Direct dependency zone:

- `packages/shared/...`
- `packages/gameplay/...`
- `packages/ui/...`

No-touch zone:

- Other place directories unless the issue is explicitly cross-domain

Boundary interfaces:

- Remotes:
- Session contract:
- Config:
- Tests:

### When To Start In Contract Instead

- If this change alters cross-place agreement, for example ...

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/<place>/default.project.json -o .\\tmp\\<place>.rbxlx`

## Notes

- Keep the stable handbook durable. Put short-lived concerns in `NOW.md`.
