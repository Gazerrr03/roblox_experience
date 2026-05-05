"use client";

import { useLocale, useTranslations } from "next-intl";
import ModelPreview from "./ModelPreview";
import type { Monster, Item, Trophy, Clue } from "@/data/types";
import { clues, CLUE_TYPE_LABELS } from "@/data/clues";
import { TROPHY_RARITY_COLORS, TROPHY_RARITY_LABELS } from "@/data/trophies";

interface StatRowProps {
  label: string;
  value: string | number;
  accent?: boolean;
}

function StatRow({ label, value, accent }: StatRowProps) {
  return (
    <div className="flex justify-between items-center py-1 border-b border-white/[0.03]">
      <span className="text-[10px] text-[#4a4a4a] font-mono">{label}</span>
      <span className={`text-[10px] font-mono ${accent ? "text-[#c4a35a]" : "text-[#6b6b6b]"}`}>
        {value}
      </span>
    </div>
  );
}

function RelatedClues({ entityId }: { entityId: string }) {
  const locale = useLocale();
  const related = clues.filter((c) => c.relatedEntityIds.includes(entityId));
  if (related.length === 0) return null;

  return (
    <div className="mt-4 pt-4 border-t border-white/[0.04]">
      <span className="terminal-text text-[10px] text-[#4a4a4a] tracking-[0.1em]">
        {locale === "zh" ? "关联线索" : "RELATED CLUES"}
      </span>
      {related.map((clue) => (
        <div key={clue.id} className="mt-2 flex items-center gap-2">
          <span className="text-[9px] text-[#8b1a1a] font-mono">{clue.id}</span>
          <span className="text-[10px] text-[#6b6b6b]">
            {locale === "zh" ? clue.title.zh : clue.title.en}
          </span>
          <span className="text-[8px] text-[#4a4a4a] font-mono">
            {locale === "zh" ? CLUE_TYPE_LABELS[clue.type].zh : CLUE_TYPE_LABELS[clue.type].en}
          </span>
        </div>
      ))}
    </div>
  );
}

export function MonsterDetail({ monster, onBack }: { monster: Monster; onBack: () => void }) {
  const locale = useLocale();
  const alias = locale === "zh" ? monster.alias.zh : monster.alias.en;
  const type = locale === "zh" ? monster.type.zh : monster.type.en;
  const desc = locale === "zh" ? monster.description.zh : monster.description.en;
  const flavor = locale === "zh" ? monster.flavorText.zh : monster.flavorText.en;
  const counter = locale === "zh" ? monster.counterplay.zh : monster.counterplay.en;
  const effect = monster.effect ? (locale === "zh" ? monster.effect.zh : monster.effect.en) : null;

  return (
    <div>
      {/* Back button */}
      <button
        onClick={onBack}
        className="terminal-text text-[10px] text-[#4a4a4a] hover:text-[#c4a35a] transition-colors mb-6"
      >
        ← {locale === "zh" ? "返回图鉴" : "BACK TO INDEX"}
      </button>

      <div className="grid md:grid-cols-2 gap-8">
        {/* Left: 3D preview */}
        <ModelPreview modelUrl={monster.modelUrl} className="md:sticky md:top-24" />

        {/* Right: data */}
        <div>
          <div className="mb-6">
            <p className="classified text-xs mb-1">{monster.codename}</p>
            <h2 className="terminal-text text-2xl tracking-[0.1em] text-[#e0e0e0] mb-1">
              {alias}
            </h2>
            <p className="terminal-text text-xs text-[#6b6b6b] tracking-[0.1em]">{type}</p>
          </div>

          {/* Stats */}
          <div className="card-stone p-4 mb-6 noise-overlay">
            <span className="terminal-text text-[10px] text-[#4a4a4a] tracking-[0.1em]">
              {locale === "zh" ? "属性数据" : "STATISTICS"}
            </span>
            <div className="mt-2 space-y-0">
              <StatRow label="HP" value={monster.stats.hp} accent />
              <StatRow label={locale === "zh" ? "速度" : "Speed"} value={monster.stats.speed} />
              <StatRow
                label={locale === "zh" ? "感知范围" : "Vision Range"}
                value={monster.stats.visionRange}
              />
              <StatRow
                label={locale === "zh" ? "伤害" : "Damage"}
                value={monster.stats.attackDamage}
                accent
              />
              <StatRow
                label={locale === "zh" ? "攻击范围" : "Attack Range"}
                value={monster.stats.attackRange}
              />
              <StatRow
                label={locale === "zh" ? "行为" : "Behavior"}
                value={monster.behavior.join(" → ")}
              />
              {effect && (
                <StatRow label={locale === "zh" ? "效果" : "Effect"} value={effect} accent />
              )}
            </div>
          </div>

          {/* Description */}
          <p className="text-sm text-[#6b6b6b] leading-relaxed mb-4">{desc}</p>

          {/* Flavor text */}
          <div className="border-l-2 border-[#8b1a1a]/30 pl-3 mb-4">
            <p className="text-xs text-[#8b7340] italic leading-relaxed font-mono">{flavor}</p>
          </div>

          {/* Counterplay */}
          <div className="card-stone p-4 noise-overlay mb-4">
            <span className="terminal-text text-[10px] text-[#c4a35a] tracking-[0.1em]">
              {locale === "zh" ? "反制方式" : "COUNTERPLAY"}
            </span>
            <p className="text-xs text-[#6b6b6b] mt-1 leading-relaxed">{counter}</p>
          </div>

          <RelatedClues entityId={monster.id} />
        </div>
      </div>
    </div>
  );
}

export function ItemDetail({ item, onBack }: { item: Item; onBack: () => void }) {
  const locale = useLocale();
  const name = locale === "zh" ? item.name.zh : item.name.en;
  const desc = locale === "zh" ? item.description.zh : item.description.en;
  const flavor = locale === "zh" ? item.flavorText.zh : item.flavorText.en;
  const s = item.stats;

  return (
    <div>
      <button
        onClick={onBack}
        className="terminal-text text-[10px] text-[#4a4a4a] hover:text-[#c4a35a] transition-colors mb-6"
      >
        ← {locale === "zh" ? "返回图鉴" : "BACK TO INDEX"}
      </button>

      <div className="grid md:grid-cols-2 gap-8">
        <ModelPreview modelUrl={item.modelUrl} className="md:sticky md:top-24" />

        <div>
          <div className="mb-6">
            <p className="text-[10px] text-[#4a4a4a] font-mono tracking-[0.15em] uppercase mb-1">
              {item.category}
            </p>
            <h2 className="terminal-text text-2xl tracking-[0.1em] text-[#e0e0e0] mb-1">{name}</h2>
          </div>

          <div className="card-stone p-4 mb-6 noise-overlay">
            <span className="terminal-text text-[10px] text-[#4a4a4a] tracking-[0.1em]">
              {locale === "zh" ? "属性" : "STATS"}
            </span>
            <div className="mt-2 space-y-0">
              <StatRow label={locale === "zh" ? "重量" : "Weight"} value={s.weight} />
              <StatRow label={locale === "zh" ? "价值" : "Value"} value={s.value} accent />
              {s.price != null && (
                <StatRow label={locale === "zh" ? "价格" : "Price"} value={s.price} accent />
              )}
              {s.damage != null && (
                <StatRow
                  label={locale === "zh" ? "伤害" : "Damage"}
                  value={s.damage}
                  accent
                />
              )}
              {s.swingRange != null && (
                <StatRow
                  label={locale === "zh" ? "范围" : "Range"}
                  value={`${s.swingRange} / ${s.swingArcDegrees}°`}
                />
              )}
              {s.knockback != null && (
                <StatRow label={locale === "zh" ? "击退" : "Knockback"} value={s.knockback} />
              )}
              {s.healAmount != null && (
                <StatRow
                  label={locale === "zh" ? "恢复" : "Heal"}
                  value={`${s.healAmount} HP`}
                  accent
                />
              )}
              {s.durability != null && (
                <StatRow label={locale === "zh" ? "耐久" : "Durability"} value={s.durability} />
              )}
              {s.charges != null && (
                <StatRow label={locale === "zh" ? "充能" : "Charges"} value={s.charges} />
              )}
              {s.lightBrightness != null && (
                <StatRow
                  label={locale === "zh" ? "亮度" : "Brightness"}
                  value={`${s.lightBrightness} / ${s.lightRange}`}
                  accent
                />
              )}
              {s.lightColor != null && (
                <StatRow label={locale === "zh" ? "光色" : "Color"} value={s.lightColor} />
              )}
              {s.cooldown != null && (
                <StatRow
                  label={locale === "zh" ? "冷却" : "Cooldown"}
                  value={`${s.cooldown}s`}
                />
              )}
            </div>
          </div>

          <p className="text-sm text-[#6b6b6b] leading-relaxed mb-4">{desc}</p>

          <div className="border-l-2 border-[#8b1a1a]/30 pl-3">
            <p className="text-xs text-[#8b7340] italic leading-relaxed font-mono">{flavor}</p>
          </div>
        </div>
      </div>
    </div>
  );
}

export function TrophyDetail({ trophy, onBack }: { trophy: Trophy; onBack: () => void }) {
  const locale = useLocale();
  const t = useTranslations("database");
  const name = locale === "zh" ? trophy.name.zh : trophy.name.en;
  const desc = locale === "zh" ? trophy.description.zh : trophy.description.en;
  const flavor = locale === "zh" ? trophy.flavorText.zh : trophy.flavorText.en;
  const source = locale === "zh" ? trophy.source.zh : trophy.source.en;
  const rarityColor = TROPHY_RARITY_COLORS[trophy.rarity];
  const rarityLabel = locale === "zh"
    ? TROPHY_RARITY_LABELS[trophy.rarity].zh
    : TROPHY_RARITY_LABELS[trophy.rarity].en;

  return (
    <div>
      <button
        onClick={onBack}
        className="terminal-text text-[10px] text-[#4a4a4a] hover:text-[#c4a35a] transition-colors mb-6"
      >
        ← {locale === "zh" ? "返回图鉴" : "BACK TO INDEX"}
      </button>

      <div className="grid md:grid-cols-2 gap-8">
        <ModelPreview modelUrl={trophy.modelUrl} className="md:sticky md:top-24" />

        <div>
          <div className="mb-6">
            <span
              className="text-[10px] font-mono tracking-[0.1em] px-2 py-0.5 border inline-block mb-2"
              style={{
                color: rarityColor,
                borderColor: rarityColor + "30",
                background: rarityColor + "10",
              }}
            >
              {rarityLabel}
            </span>
            <h2 className="terminal-text text-2xl tracking-[0.1em] text-[#e0e0e0] mb-1">
              {name}
            </h2>
          </div>

          {/* Source */}
          <div className="card-stone p-4 mb-6 noise-overlay">
            <span className="terminal-text text-[10px] text-[#c4a35a] tracking-[0.1em]">
              {t("trophySource")}
            </span>
            <p className="text-xs text-[#6b6b6b] mt-1 leading-relaxed">{source}</p>
          </div>

          <p className="text-sm text-[#6b6b6b] leading-relaxed mb-4">{desc}</p>

          <div className="border-l-2 border-[#8b1a1a]/30 pl-3">
            <p className="text-xs text-[#8b7340] italic leading-relaxed font-mono">{flavor}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
