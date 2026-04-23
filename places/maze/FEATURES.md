# Maze Place — Feature Manifest
> last-sync: (需运行 sync-and-serve.ps1 填充)
> generated-by: 代码库全量扫描 (2026/04/22)

## 1. Session & Flow（会话与流程）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| maze-session-service | active | MazeSessionService.luau | 迷宫会话核心，管理玩家进出、MazeScene生命周期、怪物生成与销毁、状态广播 |
| camp-maze-session-contract | active | CampMazeSessionContract.luau | 会话数据契约：normalize/applyReturn/markPlayerEntered/buildMazeToRunTeleportData |
| session-phase | active | SessionPhase.luau | 阶段枚举：RunPrep→RunField→MazeActive→Debrief→SessionClosed |
| maze-entry-availability | ⚠️ partial | MazeEntryAvailability.luau | 入场评估模块已实现；真实传送仍受 Library Place ID TODO 影响，direct-boot 内容测试不经过此 gate |
| session-seed-policy | active | SessionSeedPolicy.luau | 会话随机种子策略：issueSessionSeed/ensureAuthoritativeSeed |
| maze-to-run-transition | active | MazeToRunTransition.luau | 返回时跨场景传送至Run私人服务器 |
| maze-run-portal | active | MazeRunPortal.luau | MazeToRunTransition简单包装，外部调用returnPlayers() |
| maze-bootstrap-status | active | MazeBootstrapStatus.luau | 启动阶段追踪，ReplicatedStorage记录Phase/Error/Failed |
| world-build-metadata | active | MazeSessionService.luau | 记录WorldBuildSeed/SessionId/MazeAccessCode/Source，并通过MazeState对客户端可见 |

## 2. World & Navigation（世界与导航）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| maze-world-builder | active | MazeWorldBuilder.luau | live静态世界构建入口：先组装overlay/chunk资产，再扫描并构造MazeScene |
| maze-static-world-assembler | active | MazeStaticWorldAssembler.luau | 运行时组装MazeStaticWorld根：克隆overlay房间与chunk几何到Workspace |
| maze-world-scanner | active | MazeWorldScanner.luau | 运行时扫描MazeStaticWorld，提取房间/门口/战利品/返回点元数据 |
| maze-world-shell-builder | active | MazeWorldShellBuilder.luau | 程序迷宫壳构建：调用MazeBuilder+HexMazeWorldRenderer |
| maze-formal-world-composer | active | MazeFormalWorldComposer.luau | 完整世界构造：生成loot节点/返回点/门节点/巡逻索引 |
| maze-debug-world-composer | active | MazeDebugWorldComposer.luau | 调试模式迷宫构建（跳过ModuleAssets验证） |
| hex-maze-world-renderer | active | HexMazeWorldRenderer.luau | 六边形迷宫几何渲染器：floor/ceiling/walls/doorways/decor |
| maze-scene | active | MazeScene.luau | 迷宫场景聚合根，持有多房间/返回点/战利品/门/生成点 |
| maze-scene-registry | active | MazeSceneRegistry.luau | 场景元素注册表，按ID索引Rooms/LootNodes/Doorways |
| maze-room | active | MazeRoom.luau | 房间数据对象，含RoomType/DifficultyTier/MonsterBudget/LootBudget |
| maze-door | active | MazeDoor.luau | 门的运行时封装：toggle()切换开/关，bind()绑定ProximityPrompt |
| maze-spawn-point | active | MazeSpawnPoint.luau | 生成点（Kind=Spawn/ReturnHold），含CFrame |
| maze-module-asset-contract | active | MazeModuleAssetContract.luau | Studio资产契约：验证WallSegment/DoorFrame/DoorLeaf/FloorPanel |
| maze-lighting-profile | active | MazeLightingProfile.luau | 灯光配置：Future(暗色氛围)/FallbackReadable(高亮度) |
| maze-lighting-service | active | MazeLightingService.luau | 运行时应用MazeLightingProfile到Lighting服务 |

## 3. Items & Tools（物品与工具）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| inventory-service | active | InventoryService.luau | 背包服务：pickup/equip/unequip/deposit/consume/getSummary |
| teleport-inventory-hydrator | active | TeleportInventoryHydrator.luau | 跨场景传送后从teleportData恢复玩家背包 |
| held-item-controller | active | HeldItemController.luau | 客户端手持道具控制器：PointLight附加到头部 |
| held-tool-visual | active | HeldToolVisual.luau | 手持工具视觉同步：WeldConstraint到右手 |
| dropped-pack-recovery | active | MazeSessionService.luau | 玩家死亡后生成可恢复的动态掉落包，支持后续拾回并回写持久状态 |

## 4. Interaction System（交互系统）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| maze-interaction-registry | active | MazeInteractionRegistry.luau | 统一绑定所有场景ProximityPrompt：ReturnHoldPad/Loot/Door |
| maze-loot-node | active | MazeLootNode.luau | 战利品交互节点：bind()绑定拾取ProximityPrompt，markCollected()销毁Part |
| maze-interaction-part-factory | active | MazeInteractionPartFactory.luau | 交互部件工厂：createPart/createPromptPart，HoldDuration=0/MaxDistance=10 |
| client-keyboard-input | active | MazeClient.client.luau | F(工具)/Shift(冲刺)/X(卸下)/1-3(快捷栏)/H-J(调试Studio) |

## 5. Danger Systems（危险系统）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| monster-service | active | MonsterService.luau | 完整怪物服务：spawn/update/destroy/R6动画/AttackMarker/玩家近战反击 |
| enemy-runtime | active | EnemyRuntime.luau | 敌人运行时核心：感知→状态机→移动→攻击决策 |
| enemy-state-machine | active | EnemyStateMachine.luau | 状态机：Idle→Alert/Search，Suspect(预留) |
| enemy-blackboard | active | EnemyBlackboard.luau | 感知黑板：CurrentTarget/TargetPositions/Awareness/LastSeenPosition |
| perception-component | active | PerceptionComponent.luau | 感知：GetPlayers→PickNearestTarget→更新黑板 |
| movement-component | active | MovementComponent.luau | 移动：Alert追击/Search搜索/Patrol循环巡逻 |
| attack-component | active | AttackComponent.luau | 攻击：AttackRange/CooldownSeconds，tryQueueAttack判断是否可攻击 |
| health-component | active | HealthComponent.luau | 生命值：applyDamage/isAlive |
| player-monster-melee | active | PlayerMonsterMelee.luau | 玩家近战反击：距离/弧形/视线三重检测 |

## 6. Monster System（怪物系统）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| monster-runtime | active | MonsterService.luau | 共享runtime，maze已接入 |
| monster-spawn-policy | active | MazeFormalWorldComposer.luau内 | 程序生成时计算初始巡逻索引 |
| monster-spawn-points | active | MazeWorldScanner.luau | 扫描 `MonsterSpawns/SpawnPoint_*` BasePart 作为巡逻点 |
| monster-behavior-catalog | active | MonsterBehaviorCatalog.luau | 行为开关：SenseNearestTarget/Chase/Patrol |

## 7. UI / HUD

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| maze-client-hud | ⚠️ partial | MazeClient.client.luau | 状态标签/目标/物品栏/快捷栏(上限3)/玩家状态/队友列表/返回结算/WorldBuild诊断 |
| maze-watch-hud | ⚠️ partial | MazeClient.client.luau | 右上手表HUD监听TODState；客户端已接线，Maze live path是否持续广播需按内容测试观察 |
| bootstrap-status-hud | active | MazeBootstrapStatus.luau | 启动诊断面板：Phase/Error/Failed |

## 8. Network / Remotes

| 名称 | 作用域 | 方向 | description |
|------|--------|------|-------------|
| MazeAction | Maze | C→S | SprintStart/SprintStop/UseTool/EquipItem/UnequipItem/DebugLightDamage/DebugHeavyDamage |
| MazeState | Maze | S→C | MazeSession快照广播（含玩家状态/背包/怪物状态/round进度/world-build元数据） |
| MazePrivateState | Maze | S→C | 每玩家私有状态（当前为空实现） |
| TODState | Shared | S→C | TOD/手表HUD广播面；客户端已监听，Maze内容测试阶段按观察项处理 |

## 9. Authoring Requirements（创作要求）

```
MazeStaticWorld/
├── SpawnMarker                              # 玩家出生点
├── ReturnHoldPad                            # 返回Run的唯一正式出口（ProximityPrompt）
├── RoomType/<TypeId>                       # 各房间Model标记属性
│   ├── IsCamp
│   ├── DifficultyTier / MonsterBudget / LootBudget
│   └── DetectionRadius
├── Doorway_*                               # 门控制点（BasePart+ProximityPrompt）
├── LootSocket_*                            # 战利品生成位置
├── LootPrompt                              # 战利品拾取提示（ProximityPrompt）
├── MonsterSpawns
│   └── SpawnPoint_*                        # 怪物巡逻点
└── Scenery                                 # 装饰物Folder（扫描时跳过）
```

ProcGen参数（SessionConfig）：RoomCount=20 / ExitMin=2 / ExitMax=4 / MaxGenerationAttempts=240 / RoomSpacing=40 / RoomApothem=20 / RoomSize=28x16x28 / DoorLeafChance=0.6

## 10. State Matrix（状态矩阵）

| 模块 | 状态 | 备注 |
|------|------|------|
| MazeSessionService | ✅ active | |
| MonsterService | ✅ active | maze已接入 |
| InventoryService | ✅ active | |
| MazeWorldScanner | ✅ active | |
| MazeFormalWorldComposer | ✅ active | |
| MazeStaticWorldAssembler | ✅ active | live path默认先组装overlay + chunk |
| MazeEntryAvailability | ⚠️ defined / Library Place ID TODO | 共享gate已实现，但真实传送仍依赖Place ID |
| MazePrivateState | ⚠️ 空实现 | 无私有状态广播需求 |
| TODState手表HUD | ⚠️ 待观察 | 客户端已监听，Maze live path是否持续广播需内容测试确认 |
| 掉包恢复 | ✅ active | 死亡后生成Dropped Pack，可拾回 |
| 快捷栏上限3 | ⚠️ 硬编码 | 无滚动/分页 |
| 玩家死亡重生 | ⚠️ 缺失 | IsDead状态存在但无重生流程 |
| 撤离后物品结算 | defined | applyReturn有WasSettled标记，结算流程未激活 |

## 11. 已知缺失 / 警告项

| 项目 | 严重程度 | 说明 |
|------|---------|------|
| Library Place ID | ⚠️ 中 | `SessionConfig.PlaceIds.Library = 0` 标记TODO，需替换为真实Place ID |
| Studio本地传送阻断 | ⚠️ 低 | MazeEntryAvailability在Studio无placeId时阻断（设计如此） |
| MazePrivateState空实现 | ⚠️ 低 | 当前无私有状态广播需求 |
| TODState在Maze live path的覆盖面 | ⚠️ 低 | 客户端HUD已接线，但内容测试时需确认是否持续广播与是否符合预期 |
| 快捷栏硬编码上限3 | ⚠️ 低 | 无滚动/分页 |
| 图标降级显示 | ⚠️ 低 | 无IconAssetId时显示降级文本 |
| 玩家死亡后无重生 | ⚠️ 中 | MazeSessionService未实现死亡后处理流程 |
| 撤离后物品结算未激活 | ⚠️ 中 | CampMazeSessionContract.applyReturn有WasSettled但流程未激活 |
