# Lobby NOW

## Current Focus

- 在其余多 place 流程持续收敛时，保持 lobby 有意地“薄”。
- 把 lobby 视为进入 run 的 launch adapter，而不是承接 run 或 maze 状态所有权的地方。

## Open Questions

- lobby 是否最终也要拥有一个 dedicated local portal adapter module，
  与 `origin/contract` 上探索过的方向保持一致。
- 队伍信息或 session 预览应该在 lobby 保留多少，多少应延后到 run 展示。

## Temporary Exceptions

- 当前无。

## Near-Term Cleanup

- 如果 lobby-to-run handoff 继续增长，优先把 teleport boundary 抽到本地 adapter，
  而不是无限膨胀 `LobbyService`。
