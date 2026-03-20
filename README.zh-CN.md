# roblox_experience

[English](./README.md) | [简体中文](./README.zh-CN.md)

这是一个多 place 的 Roblox 体验骨架：

- `places/lobby`: 组队、准备状态和启动 run
- `places/run`: 营地、野外、迷宫入口和结算承接
- `places/maze`: 迷宫探索、拾取、撤离和返回 Run
- `packages/shared`: 共享枚举、网络定义、schema 辅助和通用工具
- `packages/gameplay`: 纯玩法数据和有状态的领域模块
- `packages/ui`: 首个垂直切片使用的轻量 UI 辅助
- `DevPackages`: 由 Wally 生成的第三方依赖，与仓库自有源码分离

## Place 开发线

多 place 并行开发固定使用 4 条长期线：

- `lobby`
- `run`
- `maze`
- `contract`

建议每条线使用一个独立 worktree，这样关卡内容和跨 place handoff 契约可以分开演进。
具体 ownership、worktree 命令、合并顺序和验证规则见
`references/place-parallel-development.md`。

## 本地启动与开发

### Windows 一键启动

如果你在 Windows 上想最快启动本地开发环境，直接在仓库根目录运行：

```powershell
.\start-run.cmd
```

这个入口会：

- 如果本地缺少仓库需要的 Rojo/Wally 工具，就先执行 `aftman install`
- 如果 `DevPackages/` 缺失或为空，就执行 `wally install`
- 为 `run` place 在 `34872` 端口启动 `rojo serve`

在使用这个入口前，你仍然需要先在机器上安装：

- Roblox Studio
- Rojo Studio 插件
- `aftman`

如果你想切换 place 或端口，直接用 PowerShell 启动脚本：

```powershell
.\scripts\dev.ps1 -Place lobby
.\scripts\dev.ps1 -Place maze -Port 34873
.\scripts\dev.ps1 -Place run -RefreshDeps
```

### 前置依赖

- 安装 Roblox Studio
- 安装 Rojo Studio 插件
- 在本机安装 `aftman`

### 首次工具链配置

在仓库根目录运行：

```powershell
aftman self-install
```

执行完 `aftman self-install` 后，重开终端，让 `~/.aftman/bin` 被加入 `PATH`。

然后安装仓库管理的工具与依赖：

```powershell
aftman install
wally install
```

你可以用这些命令确认本地工具链是否可用：

```powershell
rojo --version
wally --version
stylua --version
selene --version
```

### 本地启动指定 place

在仓库根目录按需运行下面任一命令：

```powershell
rojo serve
```

服务根目录项目；当前根项目映射到 `run` place。

```powershell
rojo serve places/lobby/default.project.json
```

服务 `lobby` place。

```powershell
rojo serve places/run/default.project.json
```

直接服务 `run` place。

```powershell
rojo serve places/maze/default.project.json
```

直接服务 `maze` place。

如果你要同时启动多个 Rojo 服务，给它们不同端口即可，例如：

```powershell
rojo serve places/lobby/default.project.json --port 34873
```

### 连接 Roblox Studio

1. 先启动你需要的 `rojo serve`，并保持终端窗口打开
2. 打开 Roblox Studio
3. 打开 Rojo 插件
4. 连接到 `localhost` 和 Rojo 打印出来的端口，通常是 `34872`
5. 在插件里把项目同步进 Studio

### 本地启动 vs 已发布 Teleport

- `start-run.cmd`、`scripts/dev.ps1` 和 `rojo serve` 只负责本地源码同步和 place 组合启动
- 它们不会把本地 `.rbxl` 或 Studio 会话变成一个“已发布”的 Roblox place
- 在本地 Studio 会话里，`game.PlaceId` 和 `game.GameId` 仍然可能是 `0`，所以即使 Rojo 已连接，跨 place 的迷宫 teleport 仍可能不可用
- 如果你要验证真实迷宫 teleport，请使用已经发布的 `Lobby` / `Run` / `Maze` place ids
- 如果你只想在本地 Studio 内完整调试，请启用 `SessionDebugLocalMazeHandoff`，这样 run 会进入同 place 的本地 debug 迷宫，而不是跨 place teleport

### 本地验证命令

需要做本地验证时，在仓库根目录运行：

```powershell
stylua --check .
selene .
```

在 Windows 上跑逻辑测试时，把构建产物写到本地 `tmp`，不要写到 `/tmp`：

```powershell
New-Item -ItemType Directory -Force .\tmp | Out-Null
rojo build tests/default.project.json -o .\tmp\roblox_experience-tests.rbxlx
run-in-roblox --place .\tmp\roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua
```

## 源码目录与依赖目录

- `packages/` 是当前运行时真正使用的项目源码，应作为权威目录提交
- `DevPackages/` 是 Wally 生成目录，应保持未跟踪
- 执行 `wally install` 后，生成的依赖树应只存在于 `DevPackages/` 下，不应覆盖 `packages/`

## 开发规则

项目特有的架构边界、网络契约、验证要求和集成规范，默认都以 `AGENTS.md` 为准。
贡献者面向的环境搭建、验证流程和 CI / 平台说明见 `CONTRIBUTING.md`。

所有 PR 都应遵循仓库 PR 模板，确保 Roblox 相关的集成检查不会丢失。

## Place 流程与运行时路由

### 已发布环境下的正式路径

- `Lobby -> Run -> Maze -> Run`
- `LobbyService` 会预留一个私有 `Run` 服务器，并把准备完成的队伍传送进去
- `RunSessionService` 持有营地会话状态，负责开启野外区域，并在玩家使用迷宫入口时把他们传送到共享的 `Maze` 服务器
- `MazeSessionService` 持有迷宫侧的 expedition 状态，在玩家提前返回或结算完成后再把他们传送回 `Run`

### 本地 Studio 路径

- `rojo serve` 只负责同步源码，不会给本地 place 分配真实的 Roblox `PlaceId` 或 `GameId`
- 当本地 Studio 会话里的 `PlaceId == 0` 或 `GameId == 0` 时，正式的迷宫 teleport 会被视为不可用
- 当 `SessionDebugLocalMazeHandoff = true` 时，`Run` 会走本地 debug maze fallback，把玩家留在同一个 place 里继续调试
- 如果这个开关没有开启，迷宫入口会维持 blocked，并把原因回传到 run 的 HUD / 状态文本

## 运行时假设

- 正式 teleport 流程需要真实的 `Lobby`、`Run`、`Maze` place ids
- 你可以通过以下任一方式配置这些 place ids：
  - 在 `packages/shared/src/Config/SessionConfig.luau` 中配置源码默认值
  - 在 Studio 的 `game` 或 `ReplicatedStorage` 上设置属性：`SessionPlaceIdLobby`、`SessionPlaceIdRun`、`SessionPlaceIdMaze`
- 你也可以在 `game` 或 `ReplicatedStorage` 上设置 `SessionDebugLocalMazeHandoff`，启用本地同 place 的迷宫调试路径
- 当前 run 主循环仍保持简单：营地、探索、拾取、撤离、结算、重置
- 隐藏身份玩法暂未启用，但可见性与权限边界接口已经预留

## 测试

纯逻辑测试主要覆盖：

- 状态机转换
- 迷宫生成结构
- 背包容量与结算数学
- 私有身份数据的可见性过滤

`tests/src/Shared` 是纯逻辑覆盖的权威位置。任何对 shared/gameplay 行为的非平凡修改，都应同步更新或新增这里的 deterministic 测试。

CI 始终会 gate 格式和 lint。若仓库配置了 `ROBLOSECURITY`，`roblox-tests` job 还会构建 `tests/default.project.json` 对应的数据模型，并通过 `run-in-roblox` 执行 Studio 侧逻辑测试。

### Roblox Studio CI 启用条件

- `roblox-tests` job 依赖仓库 secret `ROBLOSECURITY`
- 没有这个 secret 时，workflow 仍然会保持绿色，但会跳过所有 Studio-backed 步骤
- 配好这个 secret 后，workflow 路径为：安装 Aftman -> 安装 Roblox Studio -> 构建 `tests/default.project.json` -> 运行 `tests/run-in-roblox.lua`

### Roblox Studio CI 排障

- `ROBLOSECURITY` 缺失：
  workflow summary 会把它归类为配置问题；在真正把 `roblox-tests` 当成端到端信号之前，先补上 secret
- `Install Roblox Studio` 失败：
  优先按 Studio 安装或认证问题排查，不要先怀疑玩法代码
- `Build test place` 失败：
  优先按 Rojo 映射或源码构建问题排查；如有条件，本地重跑 `rojo build tests/default.project.json -o /tmp/roblox_experience-tests.rbxlx`
- `Run Roblox logic tests` 失败：
  优先看该步骤本身；如果 Studio 没启动起来，按 runner / Studio 启动问题排查；如果 Studio 启动了但测试失败，则按逻辑或测试问题排查

### 本地近似 CI 路径

- 如果你的机器可以本地运行 Roblox Studio，最接近 CI 的路径是：
  `aftman install`
  `rojo build tests/default.project.json -o /tmp/roblox_experience-tests.rbxlx`
  `run-in-roblox --place /tmp/roblox_experience-tests.rbxlx --script tests/run-in-roblox.lua`
- 如果你的机器本地无法跑 Studio，就把 `stylua --check .`、`selene .` 和 GitHub Actions 里的 `roblox-tests` 日志当作权威信号
