"use client";

import { use } from "react";
import { useTranslations } from "next-intl";
import AgentChatPanel from "@/components/AgentChatPanel";

const T = {
  title: { en: "UGC CREATE", zh: "UGC 创作" },
  subtitle: {
    en: "Converse with ENTITY-ARCHIVE. Design monsters, write clue fragments, generate concept art. Your imagination, materialized within the LIMINAL universe.",
    zh: "与 ENTITY-ARCHIVE 对话。设计怪物、撰写线索碎片、生成概念图。你的想象，在 LIMINAL 宇宙中具象化。",
  },
  footer: {
    en: "All creations are recorded in the Archive. The Maze remembers everything.",
    zh: "所有创作将被档案记录。迷宫记住一切。",
  },
};

export default function UGCPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = use(params);
  const t = useTranslations("common");

  return (
    <div className="min-h-screen bg-gradient-to-b from-[#020910] via-[#0a0f1a] to-[#020910]">
      <div className="max-w-4xl mx-auto px-6 py-20">
        {/* Header */}
        <section className="text-center mb-12">
          <p className="font-mono text-[10px] tracking-[0.4em] text-[#1a2a3a] mb-8">
            ████████████████████████████
          </p>
          <h1 className="font-mono text-4xl md:text-5xl font-bold tracking-[0.2em] text-[#c8d6e5] mb-4">
            {T.title[locale as "en" | "zh"]}
          </h1>
          <p className="font-mono text-sm text-[#5a7a9a] tracking-[0.1em] max-w-xl mx-auto leading-relaxed">
            {T.subtitle[locale as "en" | "zh"]}
          </p>
        </section>

        {/* Chat Panel */}
        <AgentChatPanel locale={locale as "en" | "zh"} />

        {/* Footer note */}
        <p className="text-center mt-6 font-mono text-[10px] text-[#1a2a3a] tracking-[0.1em]">
          {T.footer[locale as "en" | "zh"]}
        </p>
      </div>
    </div>
  );
}
