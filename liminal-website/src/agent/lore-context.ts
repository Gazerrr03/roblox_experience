import type { Monster, Item, Clue } from "@/data/types";
import type { LoreContext } from "./types";
import { monsters } from "@/data/monsters";
import { items } from "@/data/items";
import { clues } from "@/data/clues";

const ZONE_KEYWORDS: Record<string, { en: string[]; zh: string[] }> = {
  AT: {
    en: ["abandoned temple", "AT zone", "lighthouse", "watcher", "fire stone"],
    zh: ["废弃神庙", "AT区", "灯塔", "守望者", "引火石"],
  },
  AR: {
    en: ["ancient ruins", "AR zone", "stele", "scale", "resonance stone", "eyeless"],
    zh: ["古代遗迹", "AR区", "石碑", "天平", "共鸣石", "无瞳"],
  },
  WF: {
    en: ["wild forest", "WF zone", "tree hollow", "fruit", "footprint", "aberration"],
    zh: ["荒野森林", "WF区", "树洞", "果实", "足迹", "畸变"],
  },
  CR: {
    en: ["cave ruins", "CR zone", "mineral", "fissure", "mechanism", "gate"],
    zh: ["洞穴遗迹", "CR区", "矿物", "裂缝", "机关", "门"],
  },
  Library: {
    en: ["library", "sand book", "page", "core maze", "deep layer"],
    zh: ["图书馆", "沙之书", "书页", "核心迷宫", "深层"],
  },
};

const THEME_KEYWORDS: Record<string, string[]> = {
  "free-will": ["free will", "written", "character", "predetermined", "fate", "choice", "自由意志", "被写好的", "角色", "预定", "命运", "选择"],
  experiment: ["experiment", "spiritual energy", "失控", "resonance", "frequency", "实验", "精神能量", "共振", "频率"],
  recording: ["record", "remember", "forget", "archive", "memory", "记录", "记住", "遗忘", "档案", "记忆"],
  prohibition: ["don't look", "don't listen", "don't speak", "prohibition", "勿看", "勿听", "勿言", "法则", "三勿"],
  sacrifice: ["watcher", "sacrifice", "skeleton", "守望者", "牺牲", "骨架", "遗言"],
};

export function retrieveRelevantLore(
  playerMessage: string,
  locale: "en" | "zh"
): LoreContext {
  const msg = playerMessage.toLowerCase();

  const matchedMonsters = monsters.filter((m) => {
    const alias = locale === "zh" ? m.alias.zh : m.alias.en;
    const type = locale === "zh" ? m.type.zh : m.type.en;
    return (
      msg.includes(alias.toLowerCase()) ||
      msg.includes(m.codename.toLowerCase()) ||
      msg.includes(type.toLowerCase())
    );
  });

  const matchedItems = items.filter((item) => {
    const name = locale === "zh" ? item.name.zh : item.name.en;
    return msg.includes(name.toLowerCase());
  });

  const matchedClues = clues.filter((clue) => {
    const title = locale === "zh" ? clue.title.zh : clue.title.en;
    const excerpt = locale === "zh" ? clue.excerpt.zh : clue.excerpt.en;
    return (
      msg.includes(title.toLowerCase()) ||
      excerpt.toLowerCase().split(" ").some((w) => msg.includes(w.toLowerCase())) ||
      matchedMonsters.some((m) => clue.relatedEntityIds.includes(m.id)) ||
      matchedItems.some((i) => clue.relatedEntityIds.includes(i.id))
    );
  });

  let zoneContext = "";
  for (const [zone, keywords] of Object.entries(ZONE_KEYWORDS)) {
    const kw = locale === "zh" ? keywords.zh : keywords.en;
    if (kw.some((k) => msg.includes(k))) {
      zoneContext = zone;
      break;
    }
  }

  const referencedEntityIds = [
    ...matchedMonsters.map((m) => m.id),
    ...matchedItems.map((i) => i.id),
    ...matchedClues.map((c) => c.id),
  ];

  return {
    relevantMonsters: matchedMonsters,
    relevantClues: matchedClues.slice(0, 5),
    relevantItems: matchedItems.slice(0, 5),
    zoneContext,
    referencedEntityIds,
  };
}

export function formatLoreContext(
  lore: LoreContext,
  locale: "en" | "zh"
): string {
  const parts: string[] = [];

  if (lore.zoneContext) {
    parts.push(
      locale === "en"
        ? `The operative is inquiring about Zone ${lore.zoneContext}.`
        : `行动者正在询问 ${lore.zoneContext} 区域。`
    );
  }

  for (const m of lore.relevantMonsters) {
    const alias = locale === "zh" ? m.alias.zh : m.alias.en;
    const type = locale === "zh" ? m.type.zh : m.type.en;
    const desc = locale === "zh" ? m.description.zh : m.description.en;
    const flavor = locale === "zh" ? m.flavorText.zh : m.flavorText.en;
    const counter = locale === "zh" ? m.counterplay.zh : m.counterplay.en;
    parts.push(
      `[ARCHIVE: ${alias} (${m.codename}, ${type})] ${desc} Flavor: ${flavor} Counterplay: ${counter}`
    );
  }

  for (const item of lore.relevantItems) {
    const name = locale === "zh" ? item.name.zh : item.name.en;
    const desc = locale === "zh" ? item.description.zh : item.description.en;
    const flavor = locale === "zh" ? item.flavorText.zh : item.flavorText.en;
    parts.push(`[ARCHIVE ITEM: ${name}] ${desc} Flavor: ${flavor}`);
  }

  for (const clue of lore.relevantClues) {
    const title = locale === "zh" ? clue.title.zh : clue.title.en;
    const full = locale === "zh" ? clue.fullText.zh : clue.fullText.en;
    parts.push(
      `[ARCHIVE CLUE: ${title} (Credibility: ${clue.credibility})] ${full.slice(0, 600)}`
    );
  }

  return parts.join("\n\n");
}

export function buildEntitySummary(
  entityId: string,
  locale: "en" | "zh"
): string {
  const monster = monsters.find((m) => m.id === entityId);
  if (monster) {
    const alias = locale === "zh" ? monster.alias.zh : monster.alias.en;
    const desc = locale === "zh" ? monster.description.zh : monster.description.en;
    const flavor = locale === "zh" ? monster.flavorText.zh : monster.flavorText.en;
    return `[${alias}] ${desc}\n${flavor}`;
  }

  const item = items.find((i) => i.id === entityId);
  if (item) {
    const name = locale === "zh" ? item.name.zh : item.name.en;
    const desc = locale === "zh" ? item.description.zh : item.description.en;
    return `[${name}] ${desc}`;
  }

  const clue = clues.find((c) => c.id === entityId);
  if (clue) {
    const title = locale === "zh" ? clue.title.zh : clue.title.en;
    const full = locale === "zh" ? clue.fullText.zh : clue.fullText.en;
    return `[${title}] ${full}`;
  }

  return "";
}
