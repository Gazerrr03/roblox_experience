"use client";

import { useLocale } from "next-intl";
import type { Clue } from "@/data/types";
import { CLUE_TYPE_LABELS, CLUE_CREDIBILITY_LABELS } from "@/data/clues";

const TYPE_COLORS: Record<string, string> = {
  behavior: "#8b1a1a",
  mechanic: "#2a5a8a",
  world: "#8b7340",
  resource: "#3a6a3a",
};

const CREDIBILITY_COLORS: Record<string, string> = {
  "teaching-true": "#3a6a3a",
  "partial-true": "#8b7340",
  "emotionally-distorted": "#8b1a1a",
};

interface ClueCardProps {
  clue: Clue;
  onClick: (clue: Clue) => void;
}

export default function ClueCard({ clue, onClick }: ClueCardProps) {
  const locale = useLocale();
  const title = locale === "zh" ? clue.title.zh : clue.title.en;
  const excerpt = locale === "zh" ? clue.excerpt.zh : clue.excerpt.en;
  const location = locale === "zh" ? clue.location.zh : clue.location.en;
  const typeLabel = locale === "zh" ? CLUE_TYPE_LABELS[clue.type].zh : CLUE_TYPE_LABELS[clue.type].en;
  const credLabel = locale === "zh" ? CLUE_CREDIBILITY_LABELS[clue.credibility].zh : CLUE_CREDIBILITY_LABELS[clue.credibility].en;

  return (
    <button
      onClick={() => onClick(clue)}
      className="card-stone p-5 noise-overlay text-left transition-all duration-300 hover:border-[#c4a35a]/20 w-full"
    >
      {/* Header row */}
      <div className="flex items-center gap-2 mb-3">
        <span className="text-[9px] text-[#4a4a4a] font-mono">{clue.id}</span>
        <span
          className="text-[9px] font-mono tracking-[0.1em] px-2 py-0.5 border"
          style={{ color: TYPE_COLORS[clue.type], borderColor: TYPE_COLORS[clue.type] + "30" }}
        >
          {typeLabel}
        </span>
        <span
          className="text-[8px] font-mono tracking-[0.05em] px-1.5 py-0.5"
          style={{ color: CREDIBILITY_COLORS[clue.credibility], background: CREDIBILITY_COLORS[clue.credibility] + "10" }}
        >
          {credLabel}
        </span>
        <span className="terminal-text text-[9px] text-[#4a4a4a] ml-auto">[+]</span>
      </div>

      {/* Title */}
      <h4 className="terminal-text text-sm tracking-[0.1em] text-[#e0e0e0] mb-2">{title}</h4>

      {/* Excerpt */}
      <div className="border-l-2 border-[#2a2520] pl-3 mb-2">
        <p className="text-xs text-[#6b6b6b] italic leading-relaxed font-mono">{excerpt}</p>
      </div>

      {/* Location hint */}
      <p className="text-[9px] text-[#3a3a3a] font-mono">{location}</p>
    </button>
  );
}
