"use client";

import { useLocale, useTranslations } from "next-intl";
import type { Trophy } from "@/data/types";
import { TROPHY_RARITY_COLORS, TROPHY_RARITY_LABELS } from "@/data/trophies";

interface TrophyCardProps {
  trophy: Trophy;
  onClick: () => void;
}

export default function TrophyCard({ trophy, onClick }: TrophyCardProps) {
  const locale = useLocale();
  const t = useTranslations("database");
  const name = locale === "zh" ? trophy.name.zh : trophy.name.en;
  const source = locale === "zh" ? trophy.source.zh : trophy.source.en;
  const rarityKey = `trophyRarity${trophy.rarity.charAt(0).toUpperCase() + trophy.rarity.slice(1)}` as const;
  const rarityColor = TROPHY_RARITY_COLORS[trophy.rarity];

  return (
    <button
      onClick={onClick}
      className="card-stone p-5 noise-overlay text-left transition-all duration-300 hover:border-[#c4a35a]/20 w-full"
    >
      <div className="flex items-center justify-between mb-2">
        <h4 className="terminal-text text-sm tracking-[0.1em] text-[#e0e0e0]">{name}</h4>
        <span
          className="text-[8px] font-mono tracking-[0.1em] px-2 py-0.5 border"
          style={{
            color: rarityColor,
            borderColor: rarityColor + "30",
            background: rarityColor + "10",
          }}
        >
          {locale === "zh"
            ? TROPHY_RARITY_LABELS[trophy.rarity].zh
            : TROPHY_RARITY_LABELS[trophy.rarity].en}
        </span>
      </div>
      <p className="text-[10px] text-[#4a4a4a] font-mono uppercase tracking-[0.05em]">
        {t("trophySource")}: {source}
      </p>
    </button>
  );
}
