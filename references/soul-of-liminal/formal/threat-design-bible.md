# Formal Threat Design Bible

## Purpose

这篇文档把当前的“sound-driven predator”方向正式化成可约束内容与实现的威胁设计规范。
它回答：这个 headline threat 为什么成立、玩家该读到什么、什么算公平、什么绝对不能做。

主要读者：系统设计、敌人设计、内容设计、关卡设计、实现 monster runtime 的人。

## Current Decision

当前 slice 的 headline threat 是：

- 一个以声音为核心感知线索的高压威胁
- 它不需要全知，但会朝玩家制造的动静靠拢
- 玩家越慌、越乱、越连续制造噪音，死亡概率越高
- 玩家并不需要“打赢它”，而是需要更快学会怎么不给它完成猎杀条件

这个 threat 的职责不是展示 AI 复杂度，而是把“知识改变活法”做成最强的情绪体验。

## Slice Rule

### 感知维度

当前 headline threat 至少要满足：

- 优先对声音作出反应
- 不必先看到玩家才开始接近
- 接近后危险显著上升
- 持续噪音会放大追逐压力

### 玩家必须能读到的反馈

至少要有下列一部分被稳定读到：

- 它在听见什么后开始靠近
- 它接近时的声音、节奏或空间压迫变化
- 玩家在继续制造噪音时，风险为何升级
- 玩家短暂克制、转移或停损时，为什么能争取到生机

### 追逐闭环

当前 slice 的正确闭环是：

1. 玩家制造可读噪音
2. threat 被唤起或逼近
3. 玩家意识到自己正在帮助猎杀完成
4. 玩家选择继续慌乱，或者开始克制
5. 结果转成可复盘的生存/死亡因果链

### 公平性下限

当前 headline threat 必须满足：

- 第一次高压接触前，玩家至少接触过一种 warning read
- 死亡不能主要来自完全不可读的瞬间锁定
- 追逐中要存在“做得更对一点就能多活一会儿”的空间
- 玩家复盘时能说出自己下次要少做什么，而不是只想知道怎么反打

### 当前禁止做法

- 用全知全锁定掩盖规则没做清楚
- 让 threat 行为主要靠随机抽风制造不可预测性
- 把伤害、速度、范围堆高到玩家来不及读反馈
- 让它同时承担太多不同规则，导致首局无法形成明确判断

## Long-term Direction

- 长期可以扩展成多 threat ecology，让不同 threat 体现不同感知与压迫逻辑。
- 长期可以让团队沟通、错误信息、特殊工具对 threat 产生更复杂影响。
- 但当前 slice 只需要一个 headline threat 把声音-慌乱-猎杀这条主语言做清楚。

## Examples / Canonical Scenes

### 正例 1：录音先埋怀疑，追逐再完成证实

- 玩家先从 clue 里怀疑“它会听动静”
- 再在 Maze 中因自己的行为把这个怀疑证实

### 正例 2：逼近感先于必死感

- 玩家先感到它在靠近，而不是先被瞬间宣判
- 这样恐怖感来自即将完成的猎杀，而不是黑箱秒杀

### 正例 3：玩家死后知道下次要少做什么

- 少冲刺
- 少连续制造动静
- 少把 panic 当唯一解法

## Anti-goals / Failure Modes

- 玩家把它理解成普通 LOS 巡逻怪，只是跑得快一点。
- 玩家觉得它是脚本杀，知道与不知道规则都一样死。
- 玩家学到的不是“如何少帮它完成猎杀”，而是“只能赌它今天抽不抽风”。
- 为了追求恐怖，放弃了因果可读性。

## Open Questions

- 当前 slice 是否需要把“声音源强度等级”写成更明确的内容层级？
- 是否允许某些轻型威胁使用完全不同感知逻辑，还是先把主 threat 做纯？
- 后续若加入语音/麦克风风险，应如何避免它破坏当前公平底线？

## Repo Hooks

- 来源：`candidate/systems/primary-threat-audio-predator.md`
- Maze 规则来源：`candidate/systems/maze-rule-pillars.md`
- 当前 monster config：`packages/gameplay/src/Config/Monsters.luau`
- 当前 runtime：`packages/shared/src/Runtime/MonsterService.luau`
- 首局蓝图：`formal/first-30-minutes-slice-blueprint.md`
