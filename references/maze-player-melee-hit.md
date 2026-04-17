# Maze player melee (`MonsterService:tryApplyPlayerMeleeHit`)

Paste the table below into PR descriptions when changing melee rules.

| Stage | Rule | Failure reason string |
| --- | --- | --- |
| Session | Expedition must be active (`IsExpeditionActive`). | `ExpeditionInactive` |
| Monster | Main maze monster instance must exist (`MonsterRoot`). | `NoMonster` |
| Player | Valid `Player` with `Character` and `HumanoidRootPart`. | `InvalidPlayer`, `NoCharacter`, `MissingHumanoidRoot` |
| Geometry | Horizontal distance from player root to monster logical position ≤ `SwingRange` (default `6`). | `OutOfRange` |
| Geometry | Monster lies inside horizontal swing cone: half-angle = `SwingArcDegrees / 2` (default `70°`) around player look. | `OutOfSwingArc`, `InvalidFacing`, … |
| Path | `CanTraverse(playerPosition, monsterPosition)` must be true (same callback used for monster movement / maze grid). | `PathBlocked` |
| LOS | Ray from player root toward monster: first hit must be on `MonsterRoot` (or clear ray). Player character excluded. | `BlockedLineOfSight` |
| Damage | Subtracts `DamagePips` (default `1`) from `Humanoid.Health` or internal fallback HP. | `MonsterCombatStateMissing` |
| Kill | At ≤ 0 HP, calls `destroy()` on the service. | _(success payload `Killed = true`)_ |

Tool stats come from inventory item entry: `SwingRange`, `SwingArcDegrees` (from `ToolItems` config), passed through `MazeSessionService` after a successful `consumeHeldItemState` for the crowbar.
