import type { Monster } from "./types";

export const monsters: Monster[] = [
  {
    id: "eyeless-hunter",
    codename: "PREDATOR-02",
    alias: { zh: "无瞳猎手", en: "Eyeless Hunter" },
    type: { zh: "视觉感知猎手 — 勿看法则", en: "Vision-Driven Hunter — Don't Look" },
    mood: "Horror",
    stats: { hp: 4, speed: 18, visionRange: 48, attackDamage: 2, attackRange: 5 },
    behavior: ["Patrol", "SenseNearestTarget", "Chase", "Attack", "LoseTarget"],
    effect: { zh: "视线锁定：被其目视超过 3 秒将触发即死", en: "Gaze Lock: direct line of sight >3s triggers instant death" },
    description: {
      zh: "三勿法则第一位——勿看。非礼勿视，见怪必殃。无瞳猎手没有眼睛，但它仍能'看见'你——通过你投射在精神迷宫中的注视。直视它的时间越长，它锁定你的速度越快。不看，就不会被它找到。",
      en: "First of the Three Prohibitions — Don't Look. It has no eyes, yet it 'sees' you — through the gaze you project into the spiritual maze. The longer you look directly at it, the faster it locks onto you. Don't look, and it won't find you.",
    },
    flavorText: {
      zh: "不该看的不看，不该知的不知。目之所及，皆为枷锁。窥私者目盲，探密者眼瞎。",
      en: "What shouldn't be seen, don't see. What shouldn't be known, don't know. All that the eye beholds becomes a chain. Those who pry go blind.",
    },
    counterplay: {
      zh: "绝对不能长时间直视它。利用掩体遮挡视线，通过声音和余光判断其位置。观测透镜可以帮助安全地破解其'勿看'法则。",
      en: "Never maintain direct eye contact for extended periods. Use cover to break line of sight, track its position through sound and peripheral vision. The Observation Lens helps safely bypass its gaze rule.",
    },
    relatedClueIds: ["CL-NK-01"],
  },
  {
    id: "phantom-whisperer",
    codename: "PREDATOR-01",
    alias: { zh: "幻音魅影", en: "Phantom Whisperer" },
    type: { zh: "听觉感知猎手 — 勿听法则", en: "Hearing-Driven Hunter — Don't Listen" },
    mood: "Dread",
    stats: { hp: 3, speed: 22, visionRange: 0, attackDamage: 1, attackRange: 6 },
    behavior: ["SenseNearestTarget", "Chase", "Attack", "LoseTarget"],
    effect: { zh: "声音诱捕：模仿队友/求救声引诱玩家靠近；压制冲刺持续 2.5 秒", en: "Sound Lure: mimics teammates and distress calls to draw players close; Sprint Suppressed (2.5s)" },
    description: {
      zh: "三勿法则第二位——勿听。迷宫中唯一的头号捕食者。它不依赖视觉——仅通过声音事件导航和猎杀。它没有实体形态，以声音为媒介在迷宫中游荡。它会模仿你认识的人的声音——队友的呼救、熟悉的提示音、甚至你自己的回声。持续噪音会放大追逐压力，安静和静止则削弱其追踪锁定。它不是全知的，但它清楚你给了它什么。",
      en: "Second of the Three Prohibitions — Don't Listen. The Maze's sole headline predator. It does not rely on vision — it navigates and hunts exclusively through sound events. It has no physical form, drifting through the Maze as pure sound. It mimics voices you know — a teammate's cry for help, a familiar signal, even your own echo. Sustained noise amplifies pursuit pressure; silence and stillness degrade its tracking lock. It does not know everything, but it knows what you give it.",
    },
    flavorText: {
      zh: "是非皆因多开口，烦恼皆因强出头。一团由废弃金属和怨恨凝结而成的存在，以声为食，以恐惧为导航。耳不听，心不烦。闻秘者危，知密者殆。",
      en: "Trouble comes from open ears, danger from curious minds. A knot of scavenged metal and spite that feeds on sound and navigates by fear. What the ear doesn't hear, the heart doesn't fear. Those who hear secrets court danger.",
    },
    counterplay: {
      zh: "在拐角处脱离视线，利用距离重置其路径。减少奔跑、避免连续制造噪音。听到可疑声音时不要靠近。静默耳坠可以屏蔽其声音诱捕。v1 中无专用压制工具——克制是你唯一的武器。",
      en: "Break line of sight around corners and use distance to reset its path. Reduce sprinting and avoid sustained noise. Do not approach suspicious sounds. The Silence Earring blocks its sound lures. No dedicated suppression tools in v1 — restraint is your only weapon.",
    },
    relatedClueIds: ["CL-0001", "CL-NT-01"],
  },
  {
    id: "smiling-madman",
    codename: "PREDATOR-04",
    alias: { zh: "笑面狂徒", en: "Smiling Madman" },
    type: { zh: "言语感知猎手 — 勿言法则", en: "Speech-Driven Hunter — Don't Speak" },
    mood: "Tense",
    stats: { hp: 5, speed: 16, visionRange: 32, attackDamage: 2, attackRange: 3 },
    behavior: ["Patrol", "SenseNearestTarget", "Chase", "Attack", "LoseTarget"],
    effect: { zh: "言语标记：语音聊天/打字会标记玩家位置", en: "Speech Mark: voice chat or text chat marks player location" },
    description: {
      zh: "三勿法则第三位——勿言。祸从口出，言多必失。笑面狂徒永远带着一张不协调的微笑面具，它在迷宫中巡游，对任何形式的言语交流做出反应——语音聊天、文字消息、甚至游戏内的提示文本。说出口的每一个字，都是它的导航信标。",
      en: "Third of the Three Prohibitions — Don't Speak. Disaster springs from the mouth; too many words invite loss. It roams the Maze wearing an unsettling permanent smile, reacting to all forms of verbal communication — voice chat, text messages, even in-game prompt text. Every word spoken becomes its beacon.",
    },
    flavorText: {
      zh: "祸从口出，病从口入。言多必失，语多必祸。沉默是金，开口是银。守口如瓶，方能保命。",
      en: "Calamity comes from the mouth, disease enters through it. Many words, many losses. Silence is gold, speech is silver. Keep your mouth sealed to keep your life.",
    },
    counterplay: {
      zh: "在它的巡逻区域内保持沉默。使用非语言信号与队友沟通（手势、标记系统）。如果必须交流，保持简短、低频。笑面狂徒对持续对话最敏感。",
      en: "Remain silent in its patrol zones. Use non-verbal signals to communicate with teammates (gestures, marking system). If communication is necessary, keep it brief and infrequent. The Smiling Madman is most sensitive to sustained conversation.",
    },
    relatedClueIds: ["CL-WY-01"],
  },
  {
    id: "apostle",
    codename: "ENTITY-02",
    alias: { zh: "使徒", en: "The Apostle" },
    type: { zh: "视觉驱动小型威胁", en: "Vision-Driven Minor Threat" },
    mood: "Pressure",
    stats: { hp: 2, speed: 15, visionRange: 28, attackDamage: 1, attackRange: 3 },
    behavior: ["SenseNearestTarget", "Chase", "Attack"],
    description: {
      zh: "一种小型迷宫清道夫，对视线范围内的移动做出反应。通常成对巡逻，单独出现时威胁不大，但与主要捕食者同时出现会显著增加生存压力。两种变体外观略有不同但行为一致，均可被撬棍消灭。",
      en: "A small Maze scavenger that reacts to movement in its line of sight. Often patrols in pairs. Minor threat alone but significantly increases survival pressure alongside primary predators. Two visual variants exist with identical behavior — both eliminated by crowbar.",
    },
    flavorText: {
      zh: "迷宫清道夫，在可见范围内跟踪入侵者。它们从不单独出现——如果你看到一只，另一只可能已经在看着你了。",
      en: "Maze scavengers that stalk visible intruders. They never appear alone — if you see one, another may already be watching you.",
    },
    counterplay: {
      zh: "撬棍攻击 2 次即可消灭。保持静止可避免被其发现。优先处理它们，以免在关键时刻暴露你的位置。注意可能存在的第二只。",
      en: "Two crowbar hits eliminate it. Remain still to avoid detection. Dispatch quickly before they compromise your position. Watch for a possible second one.",
    },
    relatedClueIds: [],
  },
];
