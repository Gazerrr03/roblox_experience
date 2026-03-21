# Contract NOW

## Current Focus

- 在三条 place 开发线逐步独立演进时，尽量保持 cross-place handoff surface 稳定。
- 保持 shared contract 足够小，让这里的改动仍然容易 review。

## Open Questions

- 何时正式拆开当前 run-flavored remote surface，使 maze 不再依赖 `RunAction`、`RunSnapshot`、`PrivateState`。
- `origin/contract` 上探索过的 portal-adapter pattern 是否应成为所有 cross-place teleport 的默认 seam。

## Temporary Exceptions

- `packages/shared/VIBE.md` 代表的是 `contract` workstream，但 contract owner zone 只是 `packages/shared` 的一个子集，而不是整个 package。

## Near-Term Cleanup

- 如果某个 handoff 继续变复杂，优先用 tests 和更窄的模块把它记清楚，而不是先扩张 place-local branching。
