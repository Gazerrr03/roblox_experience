# Run Place — Feature Manifest

> last-sync: dcc8aaa (2026-04-16)

---

## 1. Session & Flow（会话与流程）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| session-phases | active | SessionPhase.luau | 会话阶段：RunPrep→RunField→MazeActive→Debrief→SessionClosed |
| run-tracker | ⚠️ missing | (需新建) | Expedition状态机：Camp→Expedition→Extraction→Settlement，Ship门首次打开后激活 |
| ship-doors | active | ShipDoors.luau | 6门动画（4铰链+2滑动），首次打开触发Expedition |
| book-of-sand | active | RunSessionService.luau | 团队目标：收集120 Pages |

---

## 2. World & Navigation（世界与导航）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| area-resolution | active | RunAreaResolver.luau | Z>=OutdoorThresholdZ为Wilderness，否则为Ship内区域 |
| spawn-points | active | RunSpawnPoint.luau | Spawn/Return/MazeReturn三种出生点 |
| run→maze-transition | active | RunToMazeTransition.luau | ReserveServer+TeleportAsync跨place传送 |
| maze-portal | active | RunPortal.luau | E键交互，Ship门打开后可用 |

---

## 3. Items & Tools（物品与工具）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| inventory | active | Inventory.luau | 重量容量制，支持add/equip/unequip/consume/sell |
| flashlight | active | ItemFunctionality.luau | SpotLight照明，Battery 100次 |
| rope | active | ItemFunctionality.luau | 攀爬/横渡/系怪物，Durability 5次 |
| crowbar | active | ItemFunctionality.luau | 撬锁+挖掘，70°弧度攻击，Durability 10次 |
| potion | active | ItemFunctionality.luau | 治愈1 pip，Charges 3次 |
| shop | active | RunSessionService.luau | Pages购买temple_lantern/sand_relic/scribe_compass |
| salvage | active | RunSessionService.luau | 出售物品获得Team Pages |

---

## 4. Interaction System（交互系统）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| terminals | active | RunTerminal.luau | Shop/Salvage/Objective/Loadout/UgcLabConsole五类Terminal |
| interaction-registry | active | RunInteractionRegistry.luau | ProximityPrompt→handler统一绑定 |
| proximity-prompts | active | RunStaticWorldValidator.luau | Studio编辑的Prompt对象（ShopTerminal/SalvageTerminal等） |

---

## 5. Danger Systems（危险系统）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| ocean-drowning | active | RunOceanTrigger.luau | 三阶段溺水：None→Touching(1s延迟)→Immersed(10s,1pip/5s) |
| ship-doors | active | ShipDoors.luau | Press E触发，TweenService驱动6门动画 |

---

## 6. Monster System（怪物系统）

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| monster-runtime | defined | MonsterService.luau | 共享runtime，run尚未接入 |
| monster-spawn-policy | ⚠️ missing | (需新建) | RunMonsterSpawnPolicy.luau，扫描SpawnPoint_* |
| monster-spawn-points | ⚠️ missing | (需Studio摆放) | RunStaticWorld下需摆放SpawnPoint_* BasePart |
| run-tracker | ⚠️ missing | (需新建) | Expedition状态机，首次Ship门打开时激活monster |
| monster-world-scanner | ⚠️ missing | (需新建) | RunWorldScanner.luau，扫描patrol points + canTraverse |

---

## 7. UI / HUD

| 名称 | 状态 | 文件 | description |
|------|------|------|-------------|
| start-menu | active | RunClient.client.luau | "Enter the Temple"全屏菜单 |
| camp-panel | active | RunClient.client.luau | C键切换，440x620状态面板 |
| shop/sell/objective-modals | active | RunClient.client.luau | 三个Modal面板 |
| ocean-overlay | active | RunClient.client.luau | Splash闪屏+Slowdown蓝色滤镜 |
| held-item-controller | active | HeldItemController.luau | 头顶武器视觉效果 |

---

## 8. Network / Remotes

| 名称 | 作用域 | 方向 | description |
|------|--------|------|-------------|
| RunAction | Run | C→S | Sprint/Equip/Unequip/EnterMaze/Purchase/Sell |
| RunState | Run | S→C | 全量快照(IsLaunched/Area/GateOpen/SessionPhase/Book/Roster) |
| RunPrivateState | Run | S→C | 私有事件(OpenShop/Sell/Objective/GoalReached/OceanSplash) |

---

## 9. Authoring Requirements（创作要求）

```
RunStaticWorld/
├── SpawnMarker, ReturnMarker, MazeReturnMarker   # 出生点
├── Ship/*                                       # Sci-Fi飞船模型
├── ShopTerminal, SalvageTerminal                 # Terminals
├── ObjectiveBoard, LoadoutBench, UgcLabConsole  # Terminals
├── ShipDoorsTrigger                              # 门触发ProximityPrompt
├── MazeGateMarker                                # 传送门
├── Triggers/Ocean/                              # 溺水trigger
├── Collision/Scene/, Collision/Ship/            # 碰撞体
└── SpawnPoint_*                                 # ⚠️ 需人工摆放怪物生成点
```

---

## 10. State Matrix（状态矩阵）

| 模块 | 状态 | 最后验证 | 备注 |
|------|------|----------|------|
| ShipDoors | ✅ active | e10d75f | 首次打开触发Expedition |
| Ocean Drowning | ✅ active | e10d75f | |
| Tool Flashlight | ✅ active | d326bc7 | |
| Tool Rope | ✅ active | d326bc7 | |
| Tool Crowbar | ✅ active | d326bc7 | |
| Tool Potion | ✅ active | d326bc7 | |
| Book of Sand | ✅ active | e10d75f | |
| Monster Spawn | ⚠️ missing | — | 需Studio摆放SpawnPoint_* |
| Monster Runtime | ⚠️ not-wired | — | 需接入RunSessionService |
| RunTracker | ⚠️ missing | — | 需新建Expedition状态机 |

---

## 11. Recent Commits（近期交付）

- dcc8aaa feat(gameplay): InventoryComponent与道具权威存储解耦
- d326bc7 feat(gameplay,run): 消除ItemService双轨，ItemFields单源
- e10d75f feat(run): ShipDoors+死代码UI移除+地形碰撞
- 1749bab ⚡ Bolt: HexMazeWorldRenderer优化
- 0d81c19 ⚡ Bolt: spatial lookups优化
