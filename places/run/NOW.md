# Run NOW

## Current Focus

- 让 `run` 继续作为 orchestration place，同时避免它吸收 maze-only logic 或 contract-only shape decision。
- 保留本地 debug maze fallback 作为调试工具，而不是把它变成主架构叙事。

## Open Questions

- run-to-maze seam 是否应被正式化为 dedicated local portal adapter module，
  与 `origin/contract` 的探索方向一致。
- 当前共享的 `RunAction`、`RunSnapshot`、`PrivateState` remote surface 何时拆成更清晰的 run-vs-maze contract。

## Temporary Exceptions

- maze 当前仍复用 run 的 remote set。把它视为需要通过 `contract` 偿还的主动耦合，而不是被认可的长期设计。

## Near-Term Cleanup

- 未来任何 seam cleanup，都应优先从缩小 `RunSessionService` 职责开始，而不是继续往里面加 cross-place branching。
