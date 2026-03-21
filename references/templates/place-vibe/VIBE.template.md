# <place> Vibe

## Human First

### Gameplay Template

- 这个 place 的职责是 ...
- 玩家在这里应该感受到 ...
- 这个 place 何时结束或 handoff ...

### Mental Model

- Server authority 在 ...
- Client presentation 在 ...
- 这个 place 依赖 `contract` 的部分是 ...

### Key State Flow

1. 玩家从哪里进入 ...
2. 主循环是什么 ...
3. 从哪里退出或 handoff ...

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

- 如果这次改动会改变跨 place 共识，例如 ...

### Validation

- `stylua --check .`
- `selene .`
- `rojo build places/<place>/default.project.json -o .\\tmp\\<place>.rbxlx`

## Notes

- 稳定层只保留长期有效的信息。短期问题放进 `NOW.md`。
