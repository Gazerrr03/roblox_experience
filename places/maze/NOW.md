# Maze NOW

## Current Focus

- 让 maze 保持为独立 expedition runtime，而不是继续让 run 吸收更多 maze 逻辑。
- 随着 place 演进，让 maze-to-run return behavior 始终保持显式、可 review。

## Open Questions

- 是否引入 dedicated maze portal adapter module，沿着 `origin/contract` 探索过的方向继续走。
- 何时停止复用 run-flavored remote surface，并命名一个更清晰的 maze transport contract。

## Temporary Exceptions

- maze 仍在使用 `RunAction`、`RunSnapshot`、`PrivateState`。把它视为过渡期耦合，而不是完全解耦后的目标形态。

## Near-Term Cleanup

- 如果 maze 增长出更多独特 UI 或 state，应在当前 run snapshot 变成 catch-all payload 之前，把 expedition-facing transport shape 分离出去。
