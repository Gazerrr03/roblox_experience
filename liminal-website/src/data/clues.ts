import type { Clue } from "./types";

export const clues: Clue[] = [
  // ═══════════════════════════════════════════
  // 教学线索 — 初始地图
  // ═══════════════════════════════════════════
  {
    id: "CL-0001",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "第一具尸体", en: "The First Corpse" },
    excerpt: {
      zh: "一具穿着类似玩家旧制服的尸体，身边有一个录音设备。背景里能听到声音——不是脚步声，只是……靠近。",
      en: "A corpse wearing an old uniform similar to the player's, with a recording device nearby. You can hear it in the background — not footsteps, just... approach.",
    },
    fullText: {
      zh: "在营地外围不远处发现了一具尸体。衣物与当前行动者制服相似，但款式更旧——可能是前几批被派遣的队伍成员。尸体旁边有一台仍在运转的便携式录音设备。回放录音时，可以听到背景中有一个不属于任何脚步声的声响：一种持续的、逐渐靠近的低频存在感。录音中的人声充满恐慌，他们在跑——每一次脚步声之后，那个声音都更近了一步。这可能是行动者第一次意识到：捕食者靠声音狩猎。跑得越多，它找得越准。",
      en: "A corpse was discovered not far from camp perimeter. The clothing resembles current operative uniforms but in an older style — likely a member of an earlier dispatched crew. Beside the body, a portable recording device was still running. On playback, a sound can be heard in the background that does not belong to any footstep: a persistent, gradually approaching low-frequency presence. The voices on the recording are panicked. They ran — and after every footfall, the sound drew closer. This may be the operative's first realization: the predator hunts by sound. The more you run, the more precisely it finds you.",
    },
    location: {
      zh: "营地外围，主路径外一小段距离。选择性探索奖励——不在必经之路上。",
      en: "Outside camp perimeter, a short distance off the main path. Optional exploration reward — not on the critical route.",
    },
    sceneDescription: {
      zh: "营地边缘的灌木丛被压出了一条小径——不是走出来的，是拖拽出来的。空气中残留着陈旧的血腥味和电子设备的嗡鸣。尸体靠在树干上，姿势像是在聆听什么。录音设备上的红灯仍在闪烁，在一明一暗中，你能看到尸体脸上的表情——不是恐惧，是后悔。",
      en: "The brush at camp perimeter is flattened into a trail — not walked, but dragged. The air holds stale copper and the hum of dying electronics. The corpse leans against a tree in a posture of listening. The recording device's red light still blinks; in its pulse, you catch the expression on the face — not fear, but regret.",
    },
    relatedEntityIds: ["phantom-whisperer"],
  },

  // ═══════════════════════════════════════════
  // AT 区叙事碎片 — 废弃神庙（实验守望设施）
  // ═══════════════════════════════════════════
  {
    id: "AT-01",
    type: "world",
    credibility: "emotionally-distorted",
    title: { zh: "熄灭的守望者", en: "Extinguished Watchers" },
    excerpt: {
      zh: "它们曾守望精神实验，如今只剩骨架。点燃时，你窥见实验反噬的微光。",
      en: "They once watched over the spiritual experiments. Now only skeletons remain. When lit, you glimpse the afterglow of the experiment's backlash.",
    },
    fullText: {
      zh: "废弃神庙区的三座灯塔曾是精神实验的守望设施。每一座灯塔内部都残留着守望者的精神能量——微弱、但仍在燃烧。用引火石重新点燃灯塔时，你能在火焰中看到短暂的幻象：实验失控的瞬间，精神能量如潮水般涌出，守望者们试图控制，却被反噬化为骨架。灯塔是守望者的遗言。点燃它们，不是致敬——是让它们的记忆再燃烧一次。情报碎片：图书馆对称结构藏书页房间，勿乱探，看对称。",
      en: "The three lighthouses in the Abandoned Temple zone were once observation posts for the spiritual experiments. Each lighthouse retains residual spiritual energy from the Watchers — faint, but still burning. When rekindled with a Fire Stone, brief visions appear in the flames: the moment the experiment spiraled, spiritual energy surging like a tide, the Watchers trying to contain it, consumed and reduced to skeletons. The lighthouses are their last words. Lighting them is not a tribute — it is making their memories burn once more. Intelligence fragment: The Library's structure is symmetrical — page rooms follow symmetry. Don't wander blindly.",
    },
    location: {
      zh: "AT 区 — 三座灯塔基座旁，拾取引火石后触发",
      en: "AT Zone — beside the three lighthouse bases, triggered after picking up Fire Stone",
    },
    sceneDescription: {
      zh: "三座灯塔呈三角形矗立在神庙废墟中，每一座都熄灭了不知多少年。靠近时，你能感觉到微弱的热量从石基中渗出——不是火的热，是某种更古老的能量。灯塔的玻璃罩全都碎了，碎片在脚下发出细碎的声响。空气中弥漫着烧焦的石头和旧日的虔诚。",
      en: "Three lighthouses stand in a triangle among the temple ruins, each extinguished for untold years. Drawing near, you feel faint heat seeping from the stone foundations — not the heat of fire, but something older. The lighthouse glass lies shattered, crunching softly underfoot. The air smells of scorched stone and old devotion.",
    },
    relatedEntityIds: [],
  },
  {
    id: "AT-02",
    type: "world",
    credibility: "partial-true",
    title: { zh: "墙上的最后一行", en: "The Last Line on the Wall" },
    excerpt: {
      zh: "刻痕只剩一句：被写下之前，我们就已在此等待。等待灾难的救赎者。",
      en: "Only one line remains in the etching: Before we were written, we were already here waiting. Waiting for disaster's redeemer.",
    },
    fullText: {
      zh: "在废弃神庙的一面墙壁上，密密麻麻的刻痕几乎被岁月磨平。长按辨认后，只能识别出最后一行文字：'被写下之前，我们就已在此等待。等待灾难的救赎者。'这句话暗示了一个令人不安的可能性——守望者们并非实验后才存在，他们在实验之前就已经在等待某种灾难的发生。精神实验或许不是事故，而是必然？情报碎片：稀有书页在地图边缘，勿只走主路。",
      en: "On a wall in the Abandoned Temple, dense etchings have been nearly worn smooth by time. After extended examination, only the final line can be deciphered: 'Before we were written, we were already here waiting. Waiting for disaster's redeemer.' This suggests an unsettling possibility — the Watchers existed before the experiment, already waiting for some catastrophe. Was the spiritual experiment not an accident, but an inevitability? Intelligence fragment: Rare pages are at map edges. Don't stick only to main paths.",
    },
    location: {
      zh: "AT 区 — 刻痕墙壁前，长按 3 秒辨认",
      en: "AT Zone — before the etched wall, hold 3 seconds to decipher",
    },
    sceneDescription: {
      zh: "这面墙在神庙最深处的角落里，你需要侧身才能挤进这条被遗忘的通道。墙壁上的刻痕层层叠叠——有的深如刀劈，有的浅如指甲划过。最上层的字迹已经模糊不清，只有凑到极近处，才能看到最底下那行几乎被磨平的文字。墙壁本身散发着一股潮湿的石灰味，混着铁锈的气息。",
      en: "This wall sits in the temple's deepest corner — you have to squeeze sideways into a forgotten passage to reach it. The etchings layer upon each other — some deep as blade cuts, others faint as fingernail scratches. The top layers are illegible; only pressed inches away can you make out the bottommost line, nearly worn smooth. The wall exudes damp limestone and the tang of rust.",
    },
    relatedEntityIds: [],
  },
  {
    id: "AT-03",
    type: "world",
    credibility: "emotionally-distorted",
    title: { zh: "碎裂的回声", en: "Shattered Echoes" },
    excerpt: {
      zh: "共鸣敲出石头记住的崩塌声，精神能量失控的震颤从未消散。",
      en: "The resonance draws out the collapse sounds the stones remember. The tremors of失控 spiritual energy have never truly faded.",
    },
    fullText: {
      zh: "废弃神庙中散落着四堆碎石——它们是实验失控时崩裂的建筑残骸。用共鸣锤敲击时，石头内部的矿物会发出共振，重放它们'记住'的崩塌声。每一锤下去，你都能听到建筑倒塌的轰鸣、守望者的呼喊、以及精神能量失控时那种超越物理的震颤。这些声音从未真正消散——它们被封存在石头里，等待被再次唤醒。情报碎片：高难度墙壁可破坏，勿盲信视觉。",
      en: "Four rubble piles are scattered through the Abandoned Temple — debris from structures that shattered when the experiment失控. Striking them with the Resonance Hammer causes the minerals within to resonate, replaying the collapse sounds they 'remember.' Each strike brings the roar of crumbling architecture, the Watchers' cries, and the trans-physical tremor of失控 spiritual energy. These sounds have never truly faded — sealed in stone, waiting to be awakened again. Intelligence fragment: High-difficulty walls can be destroyed. Don't trust vision blindly.",
    },
    location: {
      zh: "AT 区 — 四处碎石堆，持共鸣锤敲击",
      en: "AT Zone — four rubble piles, strike with Resonance Hammer",
    },
    sceneDescription: {
      zh: "碎石散落在神庙大殿的四个角落，每一堆都像是被某种力量从内部炸开的。石块的断面不是正常的碎裂纹理——而是像被什么东西'抹'过一样光滑。站在碎石堆旁，你能感到一种奇怪的振动从脚下传来，不规律、但持续。空气中有细小的石粉在悬浮，在光线中缓缓飘落。",
      en: "The rubble lies in four corners of the temple hall, each pile blasted outward from within. The stone fractures aren't normal — they're smooth, as if 'erased.' Standing beside a pile, you feel a strange vibration through the floor, irregular but persistent. Fine stone dust hangs in the air, drifting slowly through the light.",
    },
    relatedEntityIds: [],
  },

  // ═══════════════════════════════════════════
  // AR 区叙事碎片 — 古代遗迹（实验记录遗存）
  // ═══════════════════════════════════════════
  {
    id: "AR-01",
    type: "mechanic",
    credibility: "teaching-true",
    title: { zh: "石碑的无字面", en: "The Stele's Blank Face" },
    excerpt: {
      zh: "石碑反复渗出：谁在看？—— 窥密者必被精神能量锁定。",
      en: "The stele seeps the message repeatedly: Who is watching? — those who pry will be locked by spiritual energy.",
    },
    fullText: {
      zh: "古代遗迹中矗立着数块石碑。有些刻满无法解读的符文，但有一块表面光滑——看似空白。用观测透镜透过表面观察，碑面会渗出文字：'谁在看？'这三个字不断渗出、流淌、消失、再渗出。这是勿看法则的直接警告：当你注视不该注视的东西时，精神能量会锁定你的注视。无瞳猎手没有眼睛，但它通过你的注视找到你。观测透镜是唯一安全的'看'——因为它将你的注视过滤为间接的观测。破解勿看法则的核心道具。情报碎片：谜题藏在细节，勿粗看。",
      en: "Several steles stand in the Ancient Ruins. Some are covered in undecipherable runes, but one surface is smooth — seemingly blank. Viewed through the Observation Lens, words seep through the surface: 'Who is watching?' These three words constantly seep, flow, vanish, and seep again. This is the direct warning of the Don't Look prohibition: when you gaze upon what should not be seen, spiritual energy locks onto your gaze. The Eyeless Hunter has no eyes, yet it finds you through your looking. The Observation Lens is the only safe way to 'see' — it filters your gaze into indirect observation. Essential tool for bypassing the Don't Look rule. Intelligence fragment: Puzzles hide in details. Don't glance carelessly.",
    },
    location: {
      zh: "AR 区 — 无字石碑前，持观测透镜观察",
      en: "AR Zone — before the blank stele, observe with Observation Lens",
    },
    sceneDescription: {
      zh: "这块石碑比其他石碑都要光滑——光滑得不自然，像是被什么东西舔过一样。周围空气中弥漫着一种压迫性的静默，昆虫不鸣、风不停——但声音像是被什么东西吸走了。石碑的表面在你肉眼中确实空无一物，但你的直觉拼命告诉你：上面写满了东西。",
      en: "This stele is smoother than the others — unnaturally smooth, as if something licked it clean. The surrounding air holds an oppressive silence — no insects, no wind — yet sound feels drained, absorbed. To your naked eye, the surface is truly blank, but every instinct screams: it is covered in writing.",
    },
    relatedEntityIds: ["eyeless-hunter"],
  },
  {
    id: "AR-02",
    type: "world",
    credibility: "emotionally-distorted",
    title: { zh: "失衡的天平", en: "The Unbalanced Scale" },
    excerpt: {
      zh: "天平衡量「被记录」与「被遗忘」，这是灾难的根源。",
      en: "The scale weighs 'the recorded' against 'the forgotten.' This is the root of the disaster.",
    },
    fullText: {
      zh: "古代遗迹中央摆放着一台巨大的古代天平。一侧托盘上放着一卷展开的沙之书，另一侧是空的——却诡异地向下倾斜。触碰天平时，脑海中浮现片段的记忆：人类试图用精神能量记录一切——思想、情感、灵魂——但记录本身是一种选择。被记录的成为永恒，被遗忘的化为虚无。天平失衡，因为'被记录'太沉重了。精神实验的灾难，根源就在于人类对'记录'的执念无法平衡。情报碎片：撤离有假出口，勿急冲。",
      en: "A massive ancient scale stands at the center of the Ancient Ruins. One tray holds an unfurled Sand Book; the other is empty — yet impossibly tilts downward. Touching the scale floods the mind with memory fragments: humanity tried to record everything with spiritual energy — thoughts, emotions, souls — but recording is itself a choice. What is recorded becomes eternal; what is forgotten turns to nothing. The scale is unbalanced because 'the recorded' is too heavy. The disaster's root lies in humanity's obsession with recording, unable to find balance. Intelligence fragment: Some evacuation points are decoys. Don't rush blindly.",
    },
    location: {
      zh: "AR 区 — 古代天平前，触碰交互",
      en: "AR Zone — before the ancient scale, touch to interact",
    },
    sceneDescription: {
      zh: "古代天平立在遗迹正中央，周围的一切建筑残骸都像在向它倾斜——柱子歪向它、碎石滚向它、连光线都弯曲着落在它的托盘上。空的那一侧托盘向下倾斜的弧度让人胃部不适，因为它违反了一切物理直觉。沙之书在另一侧托盘上缓缓翻动，但没有风。",
      en: "The ancient scale stands at the ruin's center. Everything around it leans inward — columns tilt toward it, rubble rolls its way, even light bends to fall upon its trays. The empty tray's downward tilt defies physics, making your stomach knot. The Sand Book on the other tray turns its own pages — there is no wind.",
    },
    relatedEntityIds: [],
  },
  {
    id: "AR-03",
    type: "world",
    credibility: "emotionally-distorted",
    title: { zh: "共鸣石的频率", en: "Resonance Stone Frequency" },
    excerpt: {
      zh: "石头共振出实验频率，精神旋律早已注定。",
      en: "The stones resonate with the experiment's frequency. The spiritual melody was preordained.",
    },
    fullText: {
      zh: "古代遗迹中分布着三块共鸣石，表面刻有相同的频率图案。逐一激活后，三块石头会开始共振——整个遗迹回荡着一种单一的、纯净的频率。这不是随机的声音：它是精神实验的核心频率，是实验之初就被设定的'旋律'。共振意味着一切——包括灾难——都已被这个频率所预设。自由意志可能只是频率中的一个变奏。情报碎片：机关顺序藏在环境，勿乱试。",
      en: "Three resonance stones are distributed through the Ancient Ruins, each etched with identical frequency patterns. When activated in sequence, all three begin to resonate — a single, pure frequency echoes through the ruins. This is no random sound: it is the core frequency of the spiritual experiment, the 'melody' set at the experiment's inception. The resonance implies that everything — including the disaster — was preordained by this frequency. Free will may be nothing more than a variation within the melody. Intelligence fragment: Mechanism sequence is hidden in the environment. Don't guess randomly.",
    },
    location: {
      zh: "AR 区 — 三块共鸣石旁，逐一激活",
      en: "AR Zone — beside three resonance stones, activate in sequence",
    },
    sceneDescription: {
      zh: "三块共鸣石散落在遗迹的不同角落，如果你不仔细看，它们只是三块普通的灰色石头。但当你靠近其中一块时，你的牙齿会开始微微发麻——那是频率穿透骨骼的反应。石头表面刻着同样的波纹图案，每一道刻痕的深度、间距都精确到不像是人工所为。",
      en: "Three resonance stones lie scattered across the ruins. At a glance, they're just grey rocks. But draw near one, and your teeth begin to tingle — the frequency passing through bone. Each stone bears identical ripple patterns; every groove's depth and spacing is too precise to be man-made.",
    },
    relatedEntityIds: [],
  },

  // ═══════════════════════════════════════════
  // WF 区叙事碎片 — 荒野森林（精神畸变生命）
  // ═══════════════════════════════════════════
  {
    id: "WF-01",
    type: "world",
    credibility: "partial-true",
    title: { zh: "树洞里的眼睛", en: "Eyes in the Tree Hollow" },
    excerpt: {
      zh: "光照惊醒畸变存在，它畏光，更畏被看见。",
      en: "The light startles the aberration. It fears light, and fears being seen even more.",
    },
    fullText: {
      zh: "荒野森林深处的一棵古树，树干上有一个漆黑的树洞。靠近时，你能感觉到有什么东西在树洞里——在看着你。采集灌木丛中的光源种子，投入树洞后，金色光芒会瞬间充满整个树洞。光芒中，你能看到一只畸变生物的影子——蜷缩、颤抖、然后消失。它畏光。但它更畏惧的是：在光芒中，它被看见了。在噩梦难度下，伪装威胁会模拟普通环境生物，只有光源种子能迫使它们显形。情报碎片：噩梦难度勿久留，伪装威胁会活化。",
      en: "Deep in the Wild Forest stands an ancient tree, a dark hollow in its trunk. When near, you sense something inside — watching you. Gather a Light Seed from the underbrush and place it into the hollow. Golden light floods the cavity instantly. In the light, a shadow of an aberration creature becomes visible — curling, trembling, then vanishing. It fears light. But what it fears more: in the light, it is seen. On Nightmare difficulty, camouflage threats mimic ordinary environmental creatures. Only Light Seeds can force them to reveal themselves. Intelligence fragment: On Nightmare, don't linger — camouflage threats activate.",
    },
    location: {
      zh: "WF 区 — 古树树洞前，持光源种子投入",
      en: "WF Zone — before the ancient tree hollow, place Light Seed",
    },
    sceneDescription: {
      zh: "这棵古树比周围的所有树都要粗壮三倍，但它的叶子全部落光了——不是枯萎，是落得干干净净，像是树本身不想遮挡任何东西。树洞在树干中部，漆黑得反常，周围的光线到了洞口就断了，没有任何反射。站在树洞前，你的后颈发凉——不是因为风，是因为有人在看着你。",
      en: "This ancient tree is three times thicker than any around it, yet every leaf has fallen — not withered, but cleanly shed, as if the tree itself refuses to hide anything. The hollow sits mid-trunk, impossibly dark; light dies at its edge without reflection. Standing before it, your neck prickles — not from wind, but from being watched.",
    },
    relatedEntityIds: [],
  },
  {
    id: "WF-02",
    type: "resource",
    credibility: "teaching-true",
    title: { zh: "足迹的终点", en: "End of the Footprints" },
    excerpt: {
      zh: "足迹是畸变怪物的模仿，它们像人，却永远不是人。",
      en: "The footprints are the aberrations' mimicry — they resemble human, but will never be human.",
    },
    fullText: {
      zh: "荒野森林的泥地上有一串足迹——看起来像是人类的脚印，但间距不对，深度不对，方向也不对。取下枝头悬挂的追踪粉尘，撒在足迹上后，粉尘会发光并沿着足迹蔓延，清晰地标出畸变怪物的完整行动轨迹。这些足迹是怪物的'模仿'——它们试图模拟人类的存在，但永远无法做到完全正确。越靠近 Boss 房间，足迹越密集、越扭曲。追踪粉尘不仅显示路径，还揭示了怪物的心理：它们渴望成为人，但永远只是对人类的拙劣模仿。情报碎片：Boss 房在地图最远处。",
      en: "A trail of footprints marks the muddy ground of the Wild Forest — they look human, but the spacing is wrong, the depth is wrong, the direction is wrong. Taking the Tracking Dust from the branch and sprinkling it over the prints makes the dust glow and spread, clearly mapping the aberration monster's complete movement trail. These footprints are the monsters' 'mimicry' — attempts to simulate human presence, but never quite right. The closer to the boss room, the denser and more distorted the footprints become. The dust reveals not just the path, but the monster's psychology: they long to be human, yet remain only crude imitations. Intelligence fragment: The boss room lies at the map's farthest edge.",
    },
    location: {
      zh: "WF 区 — 异常足迹旁，持追踪粉尘使用",
      en: "WF Zone — beside abnormal footprints, use Tracking Dust",
    },
    sceneDescription: {
      zh: "泥地是森林中唯一没有植被覆盖的空地，像是刻意留出来的。脚印从森林边缘开始，歪歪扭扭地向深处延伸——但它们中途会转弯、重叠、甚至倒退。盯着这些脚印超过几秒，一种怪异的感觉涌上来：这些脚印的主人在走路的时候，脚趾的方向是反的。",
      en: "The mud patch is the forest's only bare ground, as if deliberately cleared. Footprints begin at the treeline and stagger deeper — but they turn, overlap, even backtrack. Staring at them for more than a few seconds, a wrongness surfaces: whatever made these prints walked with its toes facing backward.",
    },
    relatedEntityIds: [],
  },
  {
    id: "WF-03",
    type: "world",
    credibility: "emotionally-distorted",
    title: { zh: "不存在的果实", en: "The Fruit That Doesn't Exist" },
    excerpt: {
      zh: "果实是精神念头，是你摘到它，还是它选择被你看见？",
      en: "The fruit is a thought-form. Did you pick it, or did it choose to be seen by you?",
    },
    fullText: {
      zh: "荒野森林的一根树枝上，悬着一颗不存在的果实。你不看它时，它不存在于任何感官中——看一眼，它在那里。再看一眼，它的形状变了。触碰采摘后，果实会在你手中消散为纯粹的精神能量，并留下一段不属于你的记忆：一个人的声音说'我思故我在'，然后声音变成了尖叫。这颗果实是精神能量具象化的极致——它不是物质，而是'被看见'的念头本身。情报碎片：镜像室入口隐藏，勿被空白迷惑。",
      en: "On a branch in the Wild Forest hangs a fruit that does not exist. When you don't look at it, it doesn't exist in any sense — glance once, it's there. Glance again, its shape has changed. Plucking it causes it to dissolve in your hand into pure spiritual energy, leaving behind a memory that isn't yours: a voice says 'I think, therefore I am,' then the voice becomes a scream. This fruit is the extreme of spiritual energy materialization — it is not matter, but the thought of 'being seen' itself. Intelligence fragment: Mirror room entrance is hidden. Don't be fooled by emptiness.",
    },
    location: {
      zh: "WF 区 — 异常树枝前，触碰采摘果实",
      en: "WF Zone — before anomalous branch, touch to pluck fruit",
    },
    sceneDescription: {
      zh: "这根树枝单独从一棵枯死的老树上伸出来——整棵树只有这一根枝干还活着。果实悬在枝头，但你会发现自己很难确定它的颜色、大小甚至形状。每次你眨眼，它好像都变了一点点。周围没有任何鸟或昆虫靠近这棵树。它被寂静包围着，像被隔绝在时间之外。",
      en: "This branch extends alone from a dead old tree — the only living limb on the entire trunk. The fruit hangs at its tip, but you struggle to fix its color, size, or even shape. Every blink, it shifts slightly. No bird or insect comes near this tree. It stands wrapped in silence, as if sealed outside of time.",
    },
    relatedEntityIds: [],
  },

  // ═══════════════════════════════════════════
  // CR 区叙事碎片 — 洞穴遗迹（图书馆入口通道）
  // ═══════════════════════════════════════════
  {
    id: "CR-01",
    type: "world",
    credibility: "partial-true",
    title: { zh: "矿物的脉搏", en: "Mineral Pulse" },
    excerpt: {
      zh: "矿物投影出图书馆巨门，这是迷宫真正入口。",
      en: "The mineral projects the great gate of the Library — the Maze's true entrance.",
    },
    fullText: {
      zh: "洞穴深处有一块深橙色的特殊矿物，表面散发着微弱的、有节奏的脉动光——像心跳。小心取出嵌入其中的共振晶片后，将晶片靠近矿物，矿物会突然爆发光芒，向洞壁投射出一幅巨大的立体影像：图书馆的巨门。门上的文字是可读的——'入此门者，放弃一切过往。'这意味着荒野只是外层投影，真正的精神迷宫在图书馆内部。那些书页、怪物、真相——都在门的另一边。情报碎片：书页房间在地图深层。",
      en: "Deep in the cave lies a deep orange mineral, its surface pulsing with a faint, rhythmic light — like a heartbeat. After carefully extracting the Resonance Chip embedded within, bringing the chip close to the mineral triggers a sudden burst of light, projecting a massive three-dimensional image onto the cave wall: the great gate of the Library. The inscription on the gate is legible: 'Abandon all past, ye who enter here.' This means the wilds are only the outer projection — the true spiritual maze lies within the Library. The pages, the monsters, the truth — all on the other side of the gate. Intelligence fragment: Page rooms are in the map's deepest layers.",
    },
    location: {
      zh: "CR 区 — 深橙色矿物旁，持共振晶片读取记忆",
      en: "CR Zone — beside deep orange mineral, read memory with Resonance Chip",
    },
    sceneDescription: {
      zh: "矿脉嵌在洞穴最深处的岩壁上，像是被什么东西从内部撑开的伤口。深橙色的光芒有节奏地亮灭——1、2、3——1、2、3——不是心跳，更像是呼吸。周围的岩石表面凝结了一层薄薄的水珠，但水珠的振动频率和矿物的脉动完全同步。",
      en: "The vein is embedded in the cave's deepest wall, like a wound forced open from within. Deep orange light pulses in rhythm — one, two, three — one, two, three — not a heartbeat, closer to breathing. A thin film of moisture coats the surrounding rock, every droplet vibrating in sync with the mineral's pulse.",
    },
    relatedEntityIds: [],
  },
  {
    id: "CR-02",
    type: "mechanic",
    credibility: "partial-true",
    title: { zh: "机关的沉默", en: "The Mechanism's Silence" },
    excerpt: {
      zh: "机关铭文：门为被描述的人开启，你被描述了吗？",
      en: "The mechanism inscription: The gate opens for those who have been described. Have you been described?",
    },
    fullText: {
      zh: "洞穴深处有一座古老的机关，表面覆盖着精密咬合的齿轮结构——其中一枚齿轮缺失。从附近的宝箱中取出残缺的修复齿轮并安装后，机关开始运转。机关上的铭文逐渐亮起：'门为被描述的人开启。你被描述了吗？'这是一个令人不安的问题：'被描述'意味着你的存在已经被某本书写好了。如果你是自由意志的产物，门不会开启；如果你是被写好的角色——门为你而开。这不是物理的解锁，是存在论上的验证。情报碎片：前半段撤离点多为陷阱。",
      en: "Deep in the cave stands an ancient mechanism, its surface covered in precisely interlocking gears — one gear missing. Retrieving the worn Repair Gear from a nearby chest and installing it sets the mechanism in motion. The inscription on the mechanism gradually illuminates: 'The gate opens for those who have been described. Have you been described?' This is a troubling question: 'being described' means your existence has already been written in some book. If you are a product of free will, the gate won't open; if you are a written character — the gate opens for you. This is not a physical lock, but an ontological verification. Intelligence fragment: Most early evacuation points are traps. Choose carefully.",
    },
    location: {
      zh: "CR 区 — 古代机关前，持修复齿轮安装",
      en: "CR Zone — before ancient mechanism, install Repair Gear",
    },
    sceneDescription: {
      zh: "机关沉默着——它已经沉默了不知多久。齿轮的每一个齿都保持着精确的间距，仿佛上一秒还在运转。缺失的那枚齿轮留下了一个完美的圆形空缺，那个空缺的形状看起来异常舒适——因为你知道，它就是在等你的手放进去。周围没有任何声音，连洞穴的滴水声到了这里都消失了。",
      en: "The mechanism is silent — has been silent for untold time. Every gear tooth holds perfect spacing, as if it stopped spinning a second ago. The missing gear leaves a circular void, and the shape of that void is oddly comforting — because you know it's waiting for your hand. No sound reaches here; even the cave's dripping stops at the threshold.",
    },
    relatedEntityIds: [],
  },
  {
    id: "CR-03",
    type: "mechanic",
    credibility: "teaching-true",
    title: { zh: "深渊的低语", en: "Abyss Whispers" },
    excerpt: {
      zh: "耳坠传出撕书、尖叫，最后一声在叫你——勿听深渊秘声。",
      en: "The earring transmits tearing pages, screams, and finally a voice calling your name — don't listen to the abyss's secret sounds.",
    },
    fullText: {
      zh: "洞穴深处有一道狭窄的裂缝，从中不断传出低语——不是风，不是水，是语言。在裂缝旁拾取的静默耳坠似乎是一件个人遗物。戴上它后，耳坠开始向你传输声音：先是撕书的声音，然后是尖叫，最后——是一个声音在叫你的名字。不是你玩家的名字，是你角色的名字。这意味着深渊知道你是谁。勿听法则在这里最为强烈：听到的都会成为真实的。幻音魅影就是诞生于这种'被听到'的精神能量。情报碎片：传送门可能跳级，备好装备再入。",
      en: "Deep in the cave, a narrow fissure continuously emits whispers — not wind, not water, but language. The Silence Earring found beside the fissure appears to be a personal relic. When worn, it begins transmitting sounds: first, the tearing of pages, then screams, and finally — a voice calling your name. Not your player name. Your character's name. This means the abyss knows who you are. The Don't Listen prohibition is strongest here: what is heard becomes real. The Phantom Whisperer is born from this very spiritual energy of 'being heard.' Intelligence fragment: Portal may skip levels. Gear up before entering.",
    },
    location: {
      zh: "CR 区 — 洞穴裂缝旁，拾取静默耳坠",
      en: "CR Zone — beside cave fissure, pick up Silence Earring",
    },
    sceneDescription: {
      zh: "裂缝很窄——窄到你无法挤过去，但宽到足以让声音自由穿过。你第一次靠近时，裂缝里传出的低语让你以为是另一个玩家在说话。但内容不构成任何已知的语言，却又让你隐约觉得可以理解。耳坠就躺在裂缝边缘，上面没有灰尘——像是刚刚被人放下的。",
      en: "The fissure is narrow — too narrow to squeeze through, but wide enough for sound to pass freely. The first time you draw close, the whispers from within make you think another player is speaking. But the words form no known language, yet you feel you almost understand. The earring lies at the fissure's edge, free of dust — as if someone just set it down.",
    },
    relatedEntityIds: ["phantom-whisperer"],
  },
  {
    id: "CR-04",
    type: "world",
    credibility: "emotionally-distorted",
    title: { zh: "最后的警告", en: "The Final Warning" },
    excerpt: {
      zh: "你正走进一本早已写好的精神之书。你是书里的字，还是翻书的手？",
      en: "You are walking into a spiritual book already written. Are you the words in the book, or the hand that turns the pages?",
    },
    fullText: {
      zh: "在踏入图书馆之前，洞穴的尽头矗立着一面巨大的门框——空的，但你能感觉到门就在那里。凝视入口两秒后，所有已收集的叙事碎片在你脑海中拼合：你看到了一场精神能量实验的全貌、看到了守望者的牺牲、看到了三勿法则的诞生、看到了畸变的蔓延、看到了一个人——一个人的轮廓站在图书馆的中心，手中捧着一本沙之书。那个人是你吗？所有情报汇总：环境——图书馆是精神迷宫核心，随机生成通道、谜题、怪物；资源——40 页沙之书散落各处，13 枚碎片解锁真相；危险——三大怪物在图书馆内拥有更强的法则效力；机制——书页房间按对称排列，深层有 Boss 房间。跨过这道门槛，荒野声消，只剩翻书声。你不再是在探索——你是在被阅读。",
      en: "Before entering the Library, a massive doorframe stands at the cave's end — empty, yet you feel the door is there. After gazing at the entrance for two seconds, all collected narrative fragments assemble in your mind: you see the full scope of the spiritual energy experiment, the Watchers' sacrifice, the birth of the Three Prohibitions, the spread of aberrations, and a figure — a human silhouette standing at the Library's center, a Sand Book in their hands. Is that figure you? Intel summary: Environment — the Library is the spiritual maze core, with randomly generated passages, puzzles, and monsters; Resources — 40 Sand Book pages scattered throughout, 13 fragments to unlock the truth; Threats — the three great monsters possess enhanced rule potency inside the Library; Mechanics — page rooms are arranged symmetrically, boss rooms in deep layers. Cross this threshold, and the wilds fall silent. Only the sound of turning pages remains. You are no longer exploring — you are being read.",
    },
    location: {
      zh: "CR 区 — 洞穴入口框架前，凝视 2 秒",
      en: "CR Zone — before the cave entrance frame, gaze for 2 seconds",
    },
    sceneDescription: {
      zh: "门框立在那里，空荡荡的。但它周围的空气在流动——不是风，是某种更稠密的东西在缓慢地旋转。你站在门框前，可以看到另一边的洞穴墙壁，但你的大脑拒绝相信那边是墙。因为门框的'内部'——尽管空无一物——比框外的任何空间都更暗、更深、更真实。跨过去不需要勇气——需要的是放弃。",
      en: "The doorframe stands empty. But the air around it moves — not wind, but something denser, slowly rotating. Standing before it, you can see the cave wall on the other side, but your brain refuses to believe it's a wall. Because the 'inside' of the frame — though empty — is darker, deeper, more real than any space outside it. Stepping through doesn't take courage — it takes surrender.",
    },
    relatedEntityIds: ["eyeless-hunter", "phantom-whisperer", "smiling-madman"],
  },

  // ═══════════════════════════════════════════
  // 勿看 怪物线索 — 无瞳猎手
  // ═══════════════════════════════════════════
  {
    id: "CL-NK-01",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "非礼勿视，见怪必殃", en: "What Shouldn't Be Seen, Don't See" },
    excerpt: {
      zh: "非礼勿视，见怪必殃。不该看的不看，不该知的不知。",
      en: "What shouldn't be seen, don't see. Seeing the monster invites calamity.",
    },
    fullText: {
      zh: "非礼勿视，见怪必殃。不该看的不看，不该知的不知。无瞳猎手没有眼睛，但它通过你在精神迷宫中的注视找到你。直视它的时间越长，锁定越快。用余光判断它的位置。不看，就不会被锁定。",
      en: "What shouldn't be seen, don't see. Seeing the monster invites calamity. What shouldn't be known, don't know. The Eyeless Hunter has no eyes, yet it finds you through the gaze you project into the spiritual maze. The longer you look directly at it, the faster it locks onto you. Track its position through peripheral vision. Don't look, and it won't lock on.",
    },
    location: {
      zh: "AR 区石碑交互后浮现",
      en: "Appears after interacting with steles in AR zone",
    },
    sceneDescription: {
      zh: "这段铭文不是刻在石碑上的——它是在你触碰到无字石碑后，直接浮现在你的视野边缘的。文字以暗红色的光迹一笔一划地写进你的视网膜，写完即消失，不等你完全读完。你必须反复触碰石碑，才能拼出完整的内容。",
      en: "This inscription isn't carved on stone — it appears at the edges of your vision after touching the blank stele. The characters write themselves into your retina in dark red traces, stroke by stroke, vanishing before you fully read them. You must touch the stele repeatedly to piece together the full message.",
    },
    relatedEntityIds: ["eyeless-hunter"],
  },
  {
    id: "CL-NK-02",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "目之所及，皆为枷锁", en: "All That the Eye Beholds Becomes a Chain" },
    excerpt: {
      zh: "目之所及，皆为枷锁。你的眼睛是它的锁链——你看到的一切都在锁定你自己。",
      en: "All that the eye beholds becomes a chain. Your eyes are its chains — everything you see locks onto you.",
    },
    fullText: {
      zh: "目之所及，皆为枷锁。你的眼睛不是窗户——是一根锁链，锁住你看到的一切。你在迷宫中看到的每一个不该看的角落、每一块不该读的石碑、每一个不该直视的怪物——它们都在那一刻与你绑定。无瞳猎手不需要追你。你已经在看着它的时候，把自己锁在它身上了。",
      en: "All that the eye beholds becomes a chain. Your eyes are not windows — they are chains that bind everything you see. Every forbidden corner you look at, every stele you shouldn't read, every monster you shouldn't look at directly — they all bind to you in that moment. The Eyeless Hunter doesn't need to chase you. You've already chained yourself to it the moment you looked.",
    },
    location: {
      zh: "AR 区隐藏石碑",
      en: "Hidden stele in AR zone",
    },
    sceneDescription: {
      zh: "这块石碑藏在一堵半塌的墙壁后面，你必须蹲下才能看到它。石碑周围的空气中漂浮着微小的暗色粒子——它们在你注视时静止，在你移开视线时移动。石碑的表面刻着锁链的纹样，每一节链条都连着一个眼窝形状的凹槽。凹槽是空的，但你总觉得有什么东西在从里面看着你。",
      en: "This stele hides behind a half-collapsed wall, visible only while crouching. Dark microscopic particles float in the air around it — still while you watch, moving when you look away. The stele's surface bears chain patterns; every link connects to an eye-socket-shaped hollow. The hollows are empty, but you can't shake the feeling something inside is watching you.",
    },
    relatedEntityIds: ["eyeless-hunter"],
  },
  {
    id: "CL-NK-03",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "窥私者目盲，探密者眼瞎", en: "Those Who Pry Go Blind" },
    excerpt: {
      zh: "窥私者目盲，探密者眼瞎。越想知道，越失去看见的能力。",
      en: "Those who pry go blind. Those who probe secrets lose their sight. The more you want to know, the more you lose the ability to see.",
    },
    fullText: {
      zh: "窥私者目盲，探密者眼瞎。这是一句警告，也是一条物理法则——在精神迷宫中，好奇心会消耗你的视觉安全。每多看一眼不该看的东西，无瞳猎手就多一分锁定你的把握。最终，你会发现自己看见的越来越少，而它看见你的越来越多。目盲不是惩罚——是过度注视的自然结果。",
      en: "Those who pry go blind. Those who probe secrets lose their sight. This is both a warning and a physical law — in the spiritual maze, curiosity consumes your visual safety. Every extra glance at something forbidden gives the Eyeless Hunter more certainty in its lock on you. Eventually, you'll find you see less and less, while it sees you more and more. Blindness is not punishment — it is the natural consequence of excessive looking.",
    },
    location: {
      zh: "AR 区石碑深处铭文",
      en: "Deep stele inscription in AR zone",
    },
    sceneDescription: {
      zh: "这段铭文藏在石碑的深处——你必须用观测透镜透过碑面才能读到。读取时，你周围的光线会逐渐变暗，不是因为光源在熄灭，而是因为你的视线正在被消耗。读完最后一行时，你已经看不清自己脚下的地面了。但那种黑暗不是永久的——它在提醒你：你刚才看的东西，是有代价的。",
      en: "This inscription lies deep within a stele — only readable by looking through the surface with the Observation Lens. As you read, the light around you dims — not because the source fades, but because your sight is being consumed. By the last line, you can barely see the ground beneath you. But the darkness isn't permanent — it's reminding you: what you just looked at had a cost.",
    },
    relatedEntityIds: ["eyeless-hunter"],
  },
  {
    id: "CL-NK-04",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "一眼惊鸿，一生惊惶", en: "One Glance, a Lifetime of Terror" },
    excerpt: {
      zh: "一眼惊鸿，一生惊惶。对无瞳猎手的一次直视，让恐惧刻入你的余生。",
      en: "One glance, a lifetime of terror. One direct look at the Eyeless Hunter etches fear into the rest of your life.",
    },
    fullText: {
      zh: "一眼惊鸿，一生惊惶。无瞳猎手拥有一个独一无二的能力：被它锁定过的行动者，在整个会话期间都会持续感受到它的存在。即使你逃离了它的视线，那种被注视的感觉永远不会消失。一次对视，就足以在你的精神上留下不可磨灭的恐惧印记。在接下来的所有行动中，你都会感觉它在转角处。这可能只是你的恐惧——也可能不是。",
      en: "One glance, a lifetime of terror. The Eyeless Hunter has a unique ability: operatives who have been locked by it continue to feel its presence for the entire session. Even after escaping its line of sight, the feeling of being watched never truly fades. One eye contact is enough to leave an indelible mark of fear on your psyche. For the rest of your deployment, you'll feel it around every corner. It might just be your fear. It might not.",
    },
    location: {
      zh: "与无瞳猎手对视后浮现",
      en: "Appears after making eye contact with the Eyeless Hunter",
    },
    sceneDescription: {
      zh: "这条线索不需要你去寻找——它会在最不该出现的时候直接出现在你的视野正中。当你第一次与无瞳猎手对视——真正的、超过一秒的对视——这段文字会以灼烧般的方式烙印在你的视野里，无论你转向哪个方向，你都能看到它。它会慢慢褪去，但从不会完全消失。",
      en: "This clue doesn't need finding — it appears dead-center in your vision at the worst possible moment. The first time you lock eyes with the Eyeless Hunter — truly lock, for more than a second — this text burns itself into your sight. No matter where you turn, you can still see it. It fades slowly, but never fully.",
    },
    relatedEntityIds: ["eyeless-hunter"],
  },
  {
    id: "CL-NK-05",
    type: "behavior",
    credibility: "partial-true",
    title: { zh: "不该看的不看，不该知的不知", en: "What Shouldn't Be Seen, Don't See" },
    excerpt: {
      zh: "不该看的不看，不该知的不知。真正的自由是不去看那些不能改变的东西。",
      en: "What shouldn't be seen, don't see. What shouldn't be known, don't know. True freedom is not looking at what cannot be changed.",
    },
    fullText: {
      zh: "不该看的不看，不该知的不知。三勿法则的第一条不只是生存策略——它是一种存在哲学。有些真相被隐藏不是因为它们被禁止，而是因为看见它们不会给你带来任何自由，只会剥夺你的自由。无瞳猎手守护的不是秘密本身，而是你知道秘密后的那种绝望。它救你的方式，是阻止你看。",
      en: "What shouldn't be seen, don't see. What shouldn't be known, don't know. The first prohibition is more than survival strategy — it is a philosophy of existence. Some truths are hidden not because they are forbidden, but because seeing them won't bring you any freedom — only take it away. The Eyeless Hunter guards not the secrets themselves, but the despair that comes from knowing them. It saves you by stopping you from looking.",
    },
    location: {
      zh: "图书馆入口前浮现",
      en: "Appears before the Library entrance",
    },
    sceneDescription: {
      zh: "文本不是写下来的——它是从图书馆门框的内部渗出来的。暗色的雾气从空荡荡的门框中涌出，在地面上凝结成文字，排列整齐，等待你阅读。你每读完一行，那一行的雾气就散开，但门框里又涌出新的一行。读到最后，所有雾气重新聚拢，在你面前形成了一对没有瞳孔的眼睛——然后消散。",
      en: "The text isn't written — it seeps from inside the Library's doorframe. Dark mist pours from the empty frame, condensing on the ground into orderly lines of text, waiting to be read. Each line you finish dissipates, but fresh mist flows from the frame to write the next. At the end, all the mist gathers before you, forms a pair of pupil-less eyes — then scatters.",
    },
    relatedEntityIds: ["eyeless-hunter"],
  },

  // ═══════════════════════════════════════════
  // 勿听 怪物线索 — 幻音魅影
  // ═══════════════════════════════════════════
  {
    id: "CL-NT-01",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "隔墙有耳，乱听招灾", en: "Walls Have Ears — Reckless Listening Invites Disaster" },
    excerpt: {
      zh: "隔墙有耳，乱听招灾。耳不听，心不烦。",
      en: "Walls have ears — reckless listening invites disaster. What the ear doesn't hear, the heart doesn't fear.",
    },
    fullText: {
      zh: "隔墙有耳，乱听招灾。耳不听，心不烦。幻音魅影没有实体形态——它存在于声音本身之中。迷宫中听到的任何声音都可能是它：队友的呼救、熟悉的提示音、温暖的回忆声。它从你的听觉期待中诞生。不听，就是对它最大的抵抗。关闭不必要的音频通道，不要回应不寻常的声响。",
      en: "Walls have ears — reckless listening invites disaster. What the ear doesn't hear, the heart doesn't fear. The Phantom Whisperer has no physical form — it exists within sound itself. Any sound in the Maze could be it: a teammate's cry for help, a familiar signal, a warm memory. It is born from your auditory expectations. Not listening is the greatest resistance. Close unnecessary audio channels. Do not respond to unusual sounds.",
    },
    location: {
      zh: "CR 区裂缝附近浮现",
      en: "Appears near fissures in CR zone",
    },
    sceneDescription: {
      zh: "这段文字不是被看到的——是先被听到的。靠近裂缝时，一个轻微的声音在你耳边念出了这段话的第一个字，然后第二个、第三个——声音越来越小，你需要屏住呼吸才能听完。听完最后一个字后，文字才以暗色光迹的形式在你眼前短暂浮现，像是给刚才的声音做了一次书面确认。",
      en: "This text isn't seen — it's heard first. Near the fissure, a faint voice speaks the first word into your ear, then the second, the third — each quieter than the last, until you're holding your breath to catch them all. Only after the last word do the characters briefly appear before your eyes in dark light-traces, like a written receipt for what you just heard.",
    },
    relatedEntityIds: ["phantom-whisperer"],
  },
  {
    id: "CL-NT-02",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "是非皆因多开口，烦恼皆因强出头", en: "Trouble Comes from Open Ears" },
    excerpt: {
      zh: "是非皆因多开口，烦恼皆因强出头。你听到的求救声——真的是队友吗？",
      en: "Trouble comes from open ears, danger from curious minds. That cry for help you hear — is it really your teammate?",
    },
    fullText: {
      zh: "是非皆因多开口，烦恼皆因强出头。幻音魅影最擅长的战术是模仿队友的声音。它会重复你上一次听到的队友语音片段，但以微妙的偏差重新播放——一种让你觉得'好像不太对'但又无法确定的偏差。当你犹豫时，你已经在听了。当你听了，它就知道你在哪里。保持团队沟通时请确认声音来源的真实性——一句话重复出现两次，其中一次一定是它。",
      en: "Trouble comes from open ears, danger from curious minds. The Phantom Whisperer's most skilled tactic is mimicking teammates' voices. It replays the last voice clip you heard from a teammate, but with subtle deviations — distortions that make you think 'something's off' but you can't be sure. When you hesitate, you've already listened. When you've listened, it already knows where you are. Maintain team communication but verify the authenticity of sound sources — if a sentence repeats twice, one of them is definitely it.",
    },
    location: {
      zh: "WF 区异常音频触发",
      en: "Triggered by anomalous audio in WF zone",
    },
    sceneDescription: {
      zh: "荒野森林中有一片区域，在那里你的脚步声会产生延迟的回音——延迟的时间刚好让你以为身后有人。这种异常音频触发的线索会在你最不安的时候浮现：当你在安静中突然听到一个熟悉的声音叫你的名字——不是任何方向传来的，而是在你自己的脑海里。线索以耳鸣的形式出现，消退后留下这行文字。",
      en: "There's a patch in the Wild Forest where your footsteps echo with a delay — exactly the delay to make you think someone's behind you. This clue triggers at your most unsettled moment: when a familiar voice speaks your name in the silence — not from any direction, but inside your own head. The clue arrives as tinnitus, leaving these words behind as it fades.",
    },
    relatedEntityIds: ["phantom-whisperer"],
  },
  {
    id: "CL-NT-03",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "闻秘者危，知密者殆", en: "Those Who Hear Secrets Court Danger" },
    excerpt: {
      zh: "闻秘者危，知密者殆。迷宫中的每一个秘密声音都是一条通往你的线索。",
      en: "Those who hear secrets court danger. Those who know secrets face doom. Every secret sound in the Maze is a thread leading to you.",
    },
    fullText: {
      zh: "闻秘者危，知密者殆。幻音魅影狩猎的不是行动者的身体——是行动者的注意力。你听到的每一个异常声响，都意味着你的注意力在那个方向上分配了一部分。它对注意力的感知比对声音本身更敏锐。你'在意'某个声音的瞬间，就是它锁定你的瞬间。保持专注，不要让你的好奇心引导你的听觉。",
      en: "Those who hear secrets court danger. Those who know secrets face doom. The Phantom Whisperer hunts not the operative's body — but their attention. Every anomalous sound you hear means a portion of your attention is allocated in that direction. It senses attention even more keenly than sound itself. The moment you 'care about' a sound is the moment it locks onto you. Stay focused. Don't let curiosity guide your hearing.",
    },
    location: {
      zh: "CR 区深渊裂缝",
      en: "Abyss fissure in CR zone",
    },
    sceneDescription: {
      zh: "深渊裂缝比洞穴其他部分更冷——冷得不自然。你呼出的气在你面前凝结成雾，而你注意到雾的形状会在某些音节从裂缝传出时微微扭曲。这些低语不构成语言，但你发现自己在试图理解它们。就在你的注意力集中在某个特定低语的瞬间，裂缝中涌出一阵暖风——带着文字的暖风，在你面前的岩石上短暂地写下这段话。",
      en: "The abyss fissure is colder than the rest of the cave — unnaturally cold. Your breath fogs before you, and you notice the fog distorts slightly when certain syllables drift from the crack. The whispers form no language, but you catch yourself trying to understand. The exact moment your attention fixes on a particular murmur, a warm gust pours from the fissure — carrying text, briefly inscribing these words on the rock before you.",
    },
    relatedEntityIds: ["phantom-whisperer"],
  },
  {
    id: "CL-NT-04",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "流言入耳，祸事临门", en: "Rumors Enter the Ear, Disaster Arrives at the Door" },
    excerpt: {
      zh: "流言入耳，祸事临门。它第一次叫你的名字时，你最好已经忘记了自己的名字。",
      en: "Rumors enter the ear, disaster arrives at the door. When it first speaks your name, you'd better have already forgotten it.",
    },
    fullText: {
      zh: "流言入耳，祸事临门。幻音魅影的终极武器是名字。当它收集到足够的声音信息后，它会在你最脆弱的时候——受伤、孤立、迷路——轻声叫出你的角色名。这个名字不是语音合成的结果——它是从你队友的一次对话中提取出来的。听到自己的名字从一个怪物口中传来，是一种超越恐惧的体验：它意味着你已经不再是猎人，而是猎物。静默耳坠可以在这一刻之前阻断它的能力。",
      en: "Rumors enter the ear, disaster arrives at the door. The Phantom Whisperer's ultimate weapon is a name. When it has gathered enough sound information, it will — at your most vulnerable moment: injured, isolated, lost — whisper your character's name. This name is not the result of voice synthesis — it was extracted from a single conversation your teammate had. Hearing your own name from a monster's mouth is an experience beyond fear: it means you are no longer the hunter, but the hunted. The Silence Earring can block this ability before the moment arrives.",
    },
    location: {
      zh: "被幻音魅影追踪时浮现",
      en: "Appears when being tracked by the Phantom Whisperer",
    },
    sceneDescription: {
      zh: "这条线索不需要寻找——幻音魅影会确保你收到它。当它开始追踪你时，周围的背景音会逐渐消失：风停、脚步的回音消失、连你自己的呼吸声都被吸走。在绝对的安静中，你听到你的名字。不是从耳朵听到的——是直接在你的思维中响起的。名字消散后，这段话会以耳鸣的形式留给你。",
      en: "This clue doesn't need finding — the Phantom Whisperer makes sure you get it. When it begins tracking you, ambient sounds fade one by one: the wind dies, your footsteps stop echoing, even your own breathing is siphoned away. In the absolute silence, you hear your name. Not through your ears — directly inside your thoughts. After the name dissolves, these words linger as tinnitus.",
    },
    relatedEntityIds: ["phantom-whisperer"],
  },
  {
    id: "CL-NT-05",
    type: "behavior",
    credibility: "partial-true",
    title: { zh: "守口如瓶，听而不闻", en: "Seal Your Lips, Unhear the Heard" },
    excerpt: {
      zh: "真正的沉默不是不出声——是连听都不要听。不听沉默以外的一切。",
      en: "True silence is not making no sound — it is not even listening. Hear nothing beyond silence itself.",
    },
    fullText: {
      zh: "幻音魅影在迷宫中最脆弱的时候是沉默的间隙——即两个声音事件之间的空白。在绝对的安静中，它无法定位你，因为它的存在依赖声音的连续性。训练自己'听而不闻'：听到声音，但不解析它、不回应它、不让它在你的意识中留下痕迹。最高级别的对抗不是堵住耳朵——是让传入耳朵的每一个声音都变得毫无意义。它找不到不在意它的人。",
      en: "The Phantom Whisperer's most vulnerable moment in the Maze is the gap between sounds — the silence between two audio events. In absolute quiet, it cannot locate you because its existence depends on the continuity of sound. Train yourself to 'hear but not heed': hear the sound, but don't parse it, don't respond to it, don't let it leave a trace in your consciousness. The highest form of counterplay is not plugging your ears — it is making every sound that enters your ears meaningless. It cannot find someone who doesn't care about it.",
    },
    location: {
      zh: "图书馆深层寂静室",
      en: "Deep Silence Chamber in the Library",
    },
    sceneDescription: {
      zh: "寂静室是图书馆中唯一没有任何声音的房间。不是安静——是绝对的、物理层面的无声。你在这里听不到自己的心跳、血液流动、甚至骨头摩擦的声音。在这种绝对的沉默中，墙上缓缓浮现出这段话——但浮出的方式不是视觉的。你'感觉'到了这些文字的存在，就像盲人感觉到面前有一堵墙。",
      en: "The Silence Chamber is the only room in the Library with no sound at all. Not quiet — absolute, physical soundlessness. You can't hear your heartbeat, your blood flow, even the friction of your bones. In this absolute silence, these words slowly emerge on the wall — but not visually. You 'feel' their presence, the way a blind person feels a wall before them.",
    },
    relatedEntityIds: ["phantom-whisperer"],
  },

  // ═══════════════════════════════════════════
  // 勿言 怪物线索 — 笑面狂徒
  // ═══════════════════════════════════════════
  {
    id: "CL-WY-01",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "祸从口出，病从口入", en: "Calamity Comes from the Mouth" },
    excerpt: {
      zh: "祸从口出，病从口入。言多必失，语多必祸。",
      en: "Calamity comes from the mouth, disease enters through it. Many words, many losses.",
    },
    fullText: {
      zh: "祸从口出，病从口入。言多必失，语多必祸。笑面狂徒对言语的反应不依赖理解——它感知的是'交流意图'。无论是语音聊天还是文字消息，只要是发自内心的表达，就会被它截获。它不关心你说什么，它关心你说了这个事实。在它的巡逻区域内，任何形式的言语都会标记你的位置。沉默不是建议——是生存前提。",
      en: "Calamity comes from the mouth, disease enters through it. Many words, many losses. Many words, many disasters. The Smiling Madman's response to speech doesn't depend on understanding — it senses 'communicative intent.' Whether voice chat or text messages, as long as it is genuine expression, it will be intercepted. It doesn't care what you say; it cares that you spoke. In its patrol zones, any form of speech marks your position. Silence is not a suggestion — it is a prerequisite for survival.",
    },
    location: {
      zh: "CR 区机关铭文旁浮现",
      en: "Appears beside mechanism inscription in CR zone",
    },
    sceneDescription: {
      zh: "机关上的铭文亮起后，旁边的一面光秃秃的石壁上开始浮现文字——但你每读到第三个字，前两个字就消失了。你下意识地想把它念出来帮助记忆，但你的直觉在最后一刻阻止了你。你改用默读——文字开始稳定下来。石壁似乎在告诉你：说出来的记忆是不安全的。",
      en: "After the mechanism's inscription lights up, text begins surfacing on a bare stone wall beside it — but every third word you read, the first two vanish. Instinctively, you almost read it aloud to help memorize, but something stops you at the last moment. You switch to silent reading — and the text stabilizes. The wall seems to be telling you: spoken memory is unsafe.",
    },
    relatedEntityIds: ["smiling-madman"],
  },
  {
    id: "CL-WY-02",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "沉默是金，开口是银", en: "Silence Is Gold, Speech Is Silver" },
    excerpt: {
      zh: "沉默是金，开口是银。笑面狂徒的微笑面具永远在看着——你开口的那一刻。",
      en: "Silence is gold, speech is silver. The Smiling Madman's smile is always watching — the moment you open your mouth.",
    },
    fullText: {
      zh: "沉默是金，开口是银。笑面狂徒佩戴着一张永远微笑的面具——这个微笑不是友好的。它在远处静静地站着，不攻击，不移动，只是微笑。但当你开口说话——哪怕只是一个词——面具下的眼睛会瞬间锁定你。从那一刻起，你的每一个字都是它的导航信标。持续对话会强化它的追踪精度。一次简短的'这里安全'可能让你付出比沉默更高的代价。",
      en: "Silence is gold, speech is silver. The Smiling Madman wears an ever-smiling mask — and it is not a friendly smile. It stands still in the distance, not attacking, not moving, just smiling. But the moment you speak — even a single word — the eyes beneath the mask instantly lock onto you. From that moment, every word you speak becomes its navigation beacon. Sustained conversation enhances its tracking precision. One brief 'it's safe here' may cost you more than silence ever would.",
    },
    location: {
      zh: "首次遭遇笑面狂徒时浮现",
      en: "Appears on first encounter with the Smiling Madman",
    },
    sceneDescription: {
      zh: "第一次见到笑面狂徒时，最显眼的不是它的微笑——而是它周围那些悬浮的文字。这些文字是之前经过这里的行动者留下的对话片段，被精神能量凝固在空气中，像昆虫被琥珀封存。你能看到每一句话的最后一个字都在微微颤动——因为笑面狂徒正在'读取'它们。这些碎片在你靠近时散开，重组成了这条警告。",
      en: "The first time you see the Smiling Madman, it's not the smile that stands out most — it's the suspended text fragments floating around it. Words left by previous operatives who passed through, frozen in the air by spiritual energy like insects in amber. You can see the last character of every sentence trembling — because the Smiling Madman is 'reading' them. The fragments scatter as you draw near, reassembling into this warning.",
    },
    relatedEntityIds: ["smiling-madman"],
  },
  {
    id: "CL-WY-03",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "一语泄天机，半生遭天忌", en: "One Word Leaks Heaven's Secret" },
    excerpt: {
      zh: "一语泄天机，半生遭天忌。说出口的秘密不再是秘密——是笑面狂徒的邀请函。",
      en: "One word leaks heaven's secret, half a life cursed by heaven. A secret spoken is no longer a secret — it is the Smiling Madman's invitation.",
    },
    fullText: {
      zh: "一语泄天机，半生遭天忌。精神迷宫中存在着一些'天机'——关于实验真相的碎片信息。如果你在迷宫中大声讨论这些信息（例如三勿法则的本质、图书馆的位置、精神能量的真相），笑面狂徒的追踪强度会成倍增加。不是因为你说了敏感词——是因为这些内容本身就是精神能量的载体，一旦被说出口，就会像信标一样在迷宫中扩散。讨论情报请用标记系统或非语言信号。",
      en: "One word leaks heaven's secret, half a life cursed by heaven. There are 'heaven's secrets' in the spiritual maze — fragments of truth about the experiment. If you discuss these aloud in the Maze (e.g., the nature of the Three Prohibitions, the Library's location, the truth of spiritual energy), the Smiling Madman's tracking intensity multiplies. Not because you spoke sensitive keywords — but because these truths themselves are carriers of spiritual energy. Once spoken aloud, they spread through the Maze like beacons. Use the marking system or non-verbal signals to discuss intelligence.",
    },
    location: {
      zh: "图书馆内讨论真相时浮现",
      en: "Appears when discussing truth inside the Library",
    },
    sceneDescription: {
      zh: "这条线索的危险之处在于：你很可能不是一个人时触发它。当你和队友在图书馆内讨论关于实验真相的发现时，你们的对话会在空气中留下短暂的发光痕迹——每一个关于真相的字眼都像一小团磷火，漂浮几秒后熄灭。如果你们说出的真相太多，这些磷火会排列成这段文字。读到它时，你们会同时安静下来。",
      en: "The danger of this clue is: you probably won't be alone when it triggers. When you and your teammate discuss discoveries about the experiment's truth inside the Library, your words leave brief glowing traces in the air — every truth-laden syllable like a small phosphorescent flame, floating a few seconds before fading. If you speak too many truths, these flames arrange themselves into this text. Reading it, you'll both fall silent at once.",
    },
    relatedEntityIds: ["smiling-madman"],
  },
  {
    id: "CL-WY-04",
    type: "behavior",
    credibility: "teaching-true",
    title: { zh: "守口如瓶，方能保命", en: "Keep Your Mouth Sealed to Keep Your Life" },
    excerpt: {
      zh: "守口如瓶，方能保命。最安全的词是没说出口的那个。",
      en: "Keep your mouth sealed to keep your life. The safest word is the one never spoken.",
    },
    fullText: {
      zh: "守口如瓶，方能保命。笑面狂徒对交流意图的感知范围比你能想象的大得多。即使你认为自己在一个安全的角落低声说话——它也能感知到。迷宫中不存在'私密交流'这个概念。每一个词、每一个字、每一条消息都在它的巡视范围内。如果你必须沟通——用手势、用标记、用眼神。语言是你最后的选择。在笑面狂徒面前，最好的队友是你不说话也知道你在想什么的人。",
      en: "Keep your mouth sealed to keep your life. The Smiling Madman's perception range for communicative intent is far larger than you can imagine. Even if you think you're whispering in a safe corner — it can sense it. The concept of 'private communication' does not exist in the Maze. Every word, every character, every message falls within its patrol range. If you must communicate — use gestures, use markers, use eye contact. Language is your last resort. Before the Smiling Madman, the best teammate is someone who knows what you're thinking without you saying a word.",
    },
    location: {
      zh: "CR 区隐藏房间铭文",
      en: "Hidden room inscription in CR zone",
    },
    sceneDescription: {
      zh: "这间隐藏房间的入口被一块厚重的石板封住，石板上刻着一张闭着的嘴。推开石板后，房间里什么都没有——只有四面墙。但每面墙上都刻着相同的字，用不同的语言、不同的书写方向，重复着同一个信息。天花板中央悬挂着一块破碎的面具碎片——笑面狂徒的面具碎片。它在这里放过一个说话的人。那个人不在这里了。",
      en: "This hidden room's entrance is sealed by a heavy stone slab carved with a closed mouth. Inside, the room is empty — just four walls. But every wall bears the same words, in different scripts, different directions, repeating one message. A broken mask fragment hangs from the ceiling's center — a piece of the Smiling Madman's mask. It let someone speak here once. That person isn't here anymore.",
    },
    relatedEntityIds: ["smiling-madman"],
  },
  {
    id: "CL-WY-05",
    type: "behavior",
    credibility: "partial-true",
    title: { zh: "言多必失，语多必祸", en: "Many Words, Many Losses" },
    excerpt: {
      zh: "言多必失，语多必祸。你每说一个字，就离笑面狂徒的微笑更近一步。",
      en: "Many words, many losses. Many words, many disasters. With every word you speak, you take one step closer to the Smiling Madman's smile.",
    },
    fullText: {
      zh: "言多必失，语多必祸。这条法则有一个更深层的含义：你说话的对象不仅限于队友。自言自语、对怪物咒骂、阅读游戏内文本时念出声——这些全部算作'言语'。笑面狂徒不在意你的听众是谁，它只在意你发出了声音。有些行动者在极度恐惧中会不由自主地自言自语——而恰恰是这些人，最先被笑面狂徒找到。沉默不仅是一种战术——它是对自己精神状态的终极掌控。",
      en: "Many words, many losses. Many words, many disasters. This prohibition has a deeper meaning: your audience isn't limited to teammates. Talking to yourself, cursing at monsters, reading in-game text aloud — all of it counts as 'speech.' The Smiling Madman doesn't care who your audience is; it only cares that you made sound. Some operatives, in extreme fear, start talking to themselves involuntarily — and these are precisely the ones found first. Silence is not just a tactic — it is the ultimate mastery of your own mental state.",
    },
    location: {
      zh: "被笑面狂徒追击时浮现",
      en: "Appears when being chased by the Smiling Madman",
    },
    sceneDescription: {
      zh: "被笑面狂徒追击时，跑过的走廊墙壁上会映出你之前说过的每一句话——以发光的文字形式在墙上流动，像一条由语言铺成的、指向你的路。笑面狂徒沿着这些文字追赶，越读越快。你能看到墙壁上最新的那句话，就是你刚才气喘吁吁骂出口的那句脏话。它照亮了你的整张脸。",
      en: "While fleeing the Smiling Madman, every word you've spoken flows across the corridor walls in glowing script — a road of language, pointing straight to you. The Smiling Madman chases along these words, reading faster and faster. You can see the newest sentence on the wall: the curse you just gasped out. It lights up your entire face.",
    },
    relatedEntityIds: ["smiling-madman"],
  },
];

export const CLUE_TYPE_LABELS = {
  behavior: { zh: "行为线索", en: "Behavior" },
  mechanic: { zh: "机制线索", en: "Mechanic" },
  world: { zh: "世界观线索", en: "World" },
  resource: { zh: "资源线索", en: "Resource" },
} as const;

export const CLUE_CREDIBILITY_LABELS = {
  "teaching-true": { zh: "教学真实", en: "Teaching True" },
  "partial-true": { zh: "部分真实", en: "Partial True" },
  "emotionally-distorted": { zh: "情绪扭曲", en: "Emotionally Distorted" },
} as const;
