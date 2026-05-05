export interface MonsterStats {
  hp: number;
  speed: number;
  visionRange: number;
  attackDamage: number;
  attackRange: number;
}

export interface Monster {
  id: string;
  codename: string;
  alias: { zh: string; en: string };
  type: { zh: string; en: string };
  mood: string;
  stats: MonsterStats;
  behavior: string[];
  effect?: { zh: string; en: string };
  description: { zh: string; en: string };
  flavorText: { zh: string; en: string };
  counterplay: { zh: string; en: string };
  modelUrl?: string;
  relatedClueIds: string[];
}

export interface ItemStats {
  weight: number;
  value: number;
  price?: number;
  damage?: number;
  swingRange?: number;
  swingArcDegrees?: number;
  knockback?: number;
  healAmount?: number;
  durability?: number;
  charges?: number;
  lightBrightness?: number;
  lightRange?: number;
  lightColor?: string;
  cooldown?: number;
}

export interface Item {
  id: string;
  name: { zh: string; en: string };
  category: "tool";
  stats: ItemStats;
  description: { zh: string; en: string };
  flavorText: { zh: string; en: string };
  modelUrl?: string;
}

export type ClueType = "behavior" | "mechanic" | "world" | "resource";
export type ClueCredibility = "teaching-true" | "partial-true" | "emotionally-distorted";

export interface Clue {
  id: string;
  type: ClueType;
  credibility: ClueCredibility;
  title: { zh: string; en: string };
  excerpt: { zh: string; en: string };
  fullText: { zh: string; en: string };
  location: { zh: string; en: string };
  sceneDescription?: { zh: string; en: string };
  relatedEntityIds: string[];
}

export type TrophyRarity = "common" | "uncommon" | "rare" | "legendary";

export interface Trophy {
  id: string;
  name: { zh: string; en: string };
  source: { zh: string; en: string };
  rarity: TrophyRarity;
  description: { zh: string; en: string };
  flavorText: { zh: string; en: string };
  modelUrl?: string;
}
