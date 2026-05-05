import type { Item } from "./types";

export const items: Item[] = [
  {
    id: "tool-flashlight",
    name: { zh: "手电筒", en: "Flashlight" },
    category: "tool",
    stats: { weight: 0, value: 0, price: 50, durability: 100 },
    description: {
      zh: "基础照明工具，从营地商店购买。在黑暗的迷宫通道中提供可见光源。不消耗电量，可无限使用。",
      en: "Basic illumination tool, purchased from the camp shop. Provides visible light in the Maze's dark corridors. Does not consume battery — unlimited use.",
    },
    flavorText: {
      zh: "光明不会拯救你，但黑暗会让你死得更快。",
      en: "Light won't save you, but darkness will kill you faster.",
    },
  },
  {
    id: "tool-crowbar",
    name: { zh: "撬棍", en: "Crowbar" },
    category: "tool",
    stats: {
      weight: 0,
      value: 0,
      price: 120,
      durability: 10,
      damage: 1,
      swingRange: 8,
      swingArcDegrees: 75,
      knockback: 15,
    },
    description: {
      zh: "唯一的近战武器，从营地商店购买。造成 1 点伤害，挥击范围 8 单位，弧度 75°，附带击退效果。可以消灭小型威胁，但无法对抗头号捕食者。",
      en: "The only melee weapon, purchased from the camp shop. Deals 1 damage, swing range 8 units, 75° arc, with knockback. Can eliminate minor threats but useless against the headline predator.",
    },
    flavorText: {
      zh: "一把弯曲的铁棍。它能撬开的远不止箱子。",
      en: "A bent iron bar. It opens more than just crates.",
    },
  },
  {
    id: "tool-potion",
    name: { zh: "药水", en: "Potion" },
    category: "tool",
    stats: { weight: 0, value: 0, price: 80, charges: 3, healAmount: 1, cooldown: 1 },
    description: {
      zh: "恢复 1 格生命值，从营地商店购买。3 次充能，每次使用冷却 1 秒。在生命值上限仅 2 格的 Liminal 中，一瓶药水就是第二次机会。",
      en: "Restores 1 health pip, purchased from the camp shop. 3 charges, 1-second cooldown per use. In Liminal where max HP is only 2, a potion is a second chance.",
    },
    flavorText: {
      zh: "标签上写着'仅限紧急使用'。在这里，每一刻都是紧急情况。",
      en: "The label says 'For emergency use only.' Here, every moment is an emergency.",
    },
  },
];
