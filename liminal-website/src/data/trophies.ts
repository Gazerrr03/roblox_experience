import type { Trophy, TrophyRarity } from "./types";

export const trophies: Trophy[] = [
  {
    id: "echo-shard",
    name: { zh: "回响碎片", en: "Echo Shard" },
    source: { zh: "迷宫死胡同中声波结晶化形成", en: "Found where sound events have accumulated in Maze dead-ends" },
    rarity: "uncommon",
    description: {
      zh: "一枚半透明的晶体碎片，表面不断颤动着微弱的声纹。当大量声音事件在迷宫死胡同中反复回荡时，精神能量会将这些声波压缩成物理形态——回响碎片。每一枚都封存着最后一个穿过它的声音。",
      en: "A translucent crystalline shard, its surface quivering with faint sound waves. When sound events echo repeatedly in Maze dead-ends, spiritual energy compresses those waves into physical form — the Echo Shard. Each one preserves the last sound that passed through it.",
    },
    flavorText: {
      zh: "它在你手中低吟着不属于你的脚步声。迷宫的每一条死胡同都有耳朵。",
      en: "It hums with footsteps that are not yours. Every dead end in the Maze has ears.",
    },
  },
  {
    id: "experiment-log",
    name: { zh: "实验日志残页", en: "Experiment Log Fragment" },
    source: { zh: "废弃神庙区隐藏交互点", en: "Found at hidden interaction points in the Abandoned Temple zone" },
    rarity: "common",
    description: {
      zh: "一张几乎被烧毁的实验日志残页，大部分文字已经无法辨认。残留的片段提到了精神能量实验的早期阶段——在灾难发生之前。某些段落暗示实验团队早已预见到了失控的可能性，但他们选择了继续。",
      en: "A nearly-burned fragment of an experiment log. Most text is illegible. The remaining fragments reference the early stages of the spiritual energy experiments — before the disaster. Certain passages suggest the research team foresaw the possibility of失控 but chose to continue.",
    },
    flavorText: {
      zh: "墨迹烧焦了，但字句燃烧得更亮。'7号受试者对频率反应——过于强烈。'",
      en: "The ink is scorched but the words burn brighter. 'Subject 7 responded to the frequency — too strongly.'",
    },
  },
  {
    id: "watcher-bone",
    name: { zh: "守望者遗骨", en: "Watcher's Remains" },
    source: { zh: "点燃废弃神庙区全部三座灯塔后显现", en: "Manifested after lighting all three lighthouses in the Abandoned Temple zone" },
    rarity: "rare",
    description: {
      zh: "一节石化的指骨，来自一位在实验失控中化为骨架的守望者。表面残留着微弱的精神能量余温——不是火的热，是守望者在最后一刻试图压制实验时留下的意志温度。触碰它时，你能短暂地看到守望者最后看到的画面。",
      en: "A petrified finger bone from one of the Watchers reduced to skeleton when the experiment失控. The surface retains faint residual warmth of spiritual energy — not heat from fire, but the temperature of a Watcher's final will to contain the experiment. Touching it gives you a brief glimpse of the last thing the Watcher saw.",
    },
    flavorText: {
      zh: "他们守望到最后一刻。骨头记得它最后看见的东西——它看见了你。",
      en: "They watched until the end. The bone remembers the last thing it saw — and it saw you.",
    },
  },
  {
    id: "resonance-shard",
    name: { zh: "共鸣石碎片", en: "Resonance Stone Shard" },
    source: { zh: "洞穴遗迹区共鸣水晶矿脉旁", en: "Found near resonance crystal veins in the Cave Ruins zone" },
    rarity: "uncommon",
    description: {
      zh: "一片从共鸣水晶矿脉上剥离的碎片，触碰到任何声音都会以完全相同的频率共振。它发出的是迷宫的核心频率——那个在实验之初就被设定的、贯穿一切精神能量的'旋律'。持有它的人偶尔会在没有声音的时候听到碎片自主发出共鸣。",
      en: "A fragment chipped from a resonance crystal vein, vibrating at exactly the same frequency as any sound it touches. It emits the Maze's core frequency — the 'melody' set at the experiment's inception, threading through all spiritual energy. Its bearer occasionally hears it resonate on its own, in silence.",
    },
    flavorText: {
      zh: "一个音符。迷宫就是建立在这个音符上的。你不自觉地跟着哼了起来。",
      en: "One note. The same note the Maze was built on. You hum it without realizing.",
    },
  },
  {
    id: "sand-seal",
    name: { zh: "沙之书印章", en: "Sand Book Seal" },
    source: { zh: "图书馆最深层的隐藏房间", en: "Hidden chamber in the Library's deepest layers" },
    rarity: "rare",
    description: {
      zh: "一枚古老的印章，曾用于封印沙之书的书页。印章表面的刻印在你每次注视时都会变化——它仍在封印着什么，或者正在解封。有人猜测每一枚印章都对应着沙之书的一页，而找到印章意味着那页书曾被某个人特意隐藏。",
      en: "An ancient seal once used to bind Sand Book pages. The engraving on its surface shifts with every glance — it is still sealing something, or unsealing it. Some believe each seal corresponds to a specific Sand Book page, and finding one means that page was deliberately hidden by someone.",
    },
    flavorText: {
      zh: "印章的图案每次都不一样。它仍然在封印——或者正在释放。你看得太久，图案变成了你的名字。",
      en: "The seal's pattern changes every time. It is still sealing — or releasing. You look too long, and the pattern becomes your name.",
    },
  },
  {
    id: "eyeless-eye",
    name: { zh: "无瞳之眼", en: "Eyeless Eye" },
    source: { zh: "从无瞳猎手遭遇中生还后概率获得", en: "Rare drop from surviving an Eyeless Hunter encounter" },
    rarity: "legendary",
    description: {
      zh: "一颗结晶化的注视——它不是眼睛，而是'被注视'这个概念在精神迷宫中的物理凝结。它没有瞳孔，因为它从来不需要看见你；它记录的是所有曾注视过它的人的视线。持有它的人会获得一种诡异的能力：闭上眼睛时，反而能更清晰地感知到周围的威胁。",
      en: "A crystallized gaze — not an eye, but the physical condensation of the concept of 'being watched' within the spiritual Maze. It has no pupil because it never needed to see you; it records the sight-lines of everyone who has ever looked at it. Its bearer gains an uncanny ability: eyes closed, they perceive surrounding threats more clearly.",
    },
    flavorText: {
      zh: "它没有瞳孔，因为它从来不需要。看着它，就像在被它看回去。",
      en: "It has no pupil because it never needed one. Looking at it feels like being looked at back.",
    },
  },
  {
    id: "whispering-ear",
    name: { zh: "幻音之耳", en: "Whispering Ear" },
    source: { zh: "从幻音魅影遭遇中生还后概率获得", en: "Rare drop from surviving a Phantom Whisperer encounter" },
    rarity: "legendary",
    description: {
      zh: "一只由声音凝结成的耳形共鸣体，仍在低声重播它捕获的声音片段。这些片段来自被幻音魅影追踪过的所有行动者——你会在其中听到你不认识的声音在呼救、在说安全、在叫你的名字。持有它的人能听到迷宫中的声音事件比正常稍早一点——就像耳朵提前适应了恐惧的频率。",
      en: "An ear-shaped resonance formation condensed from pure sound, still whispering fragments of voices it captured. These fragments come from every operative the Phantom Whisperer has tracked — you'll hear strangers crying for help, saying it's safe, calling your name. Its bearer hears sound events in the Maze slightly sooner than normal — as if the ear has attuned to the frequency of fear.",
    },
    flavorText: {
      zh: "它低语着你队友的名字。你已经三轮没听到过那个队友的声音了。",
      en: "It whispers your teammate's name. You haven't heard that teammate in three rounds.",
    },
  },
  {
    id: "silent-tongue",
    name: { zh: "沉默之舌", en: "Silent Tongue" },
    source: { zh: "从笑面狂徒遭遇中生还后概率获得", en: "Rare drop from surviving a Smiling Madman encounter" },
    rarity: "legendary",
    description: {
      zh: "一块石化的舌头，永远凝固在说出一个词的瞬间。这个词的半截形状还残留在舌尖上——永远无法被完整说出。它来自一位在被笑面狂徒找到之前试图呼救的行动者。持有它的人会在说话之前本能地停顿半秒——而这半秒可能就是生存的关键。",
      en: "A petrified tongue, forever frozen mid-word. Half the word's shape still lingers on its tip — never to be fully spoken. It came from an operative who tried to call for help before the Smiling Madman found them. Its bearer instinctively pauses for half a second before speaking — and that half-second may be the key to survival.",
    },
    flavorText: {
      zh: "那个词还在那里，等着被说出口。你几乎能在表面上读出它——但读出来就太晚了。",
      en: "The word is still there, waiting to be spoken. You can almost read it on the surface — but reading it aloud would be too late.",
    },
  },
];

export const TROPHY_RARITY_COLORS: Record<TrophyRarity, string> = {
  common: "#6b6b6b",
  uncommon: "#3a6a3a",
  rare: "#2a5a8a",
  legendary: "#c4a35a",
};

export const TROPHY_RARITY_LABELS: Record<TrophyRarity, { zh: string; en: string }> = {
  common: { zh: "普通", en: "Common" },
  uncommon: { zh: "稀有", en: "Uncommon" },
  rare: { zh: "罕见", en: "Rare" },
  legendary: { zh: "传说", en: "Legendary" },
};
