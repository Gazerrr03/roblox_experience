"use client";

import { use } from "react";
import Link from "next/link";
import { useTranslations } from "next-intl";
import AgentChatPanel from "@/components/AgentChatPanel";

export default function AgentPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = use(params);
  const t = useTranslations("community");

  return (
    <div className="max-w-4xl mx-auto px-6 py-24">
      {/* Back link */}
      <div className="mb-8">
        <Link
          href={`/${locale}/community`}
          className="terminal-text text-xs text-[#4a4a4a] hover:text-[#c4a35a] transition-colors tracking-[0.1em]"
        >
          {locale === "zh" ? "[ 返回社区 ]" : "[ BACK TO COMMUNITY ]"}
        </Link>
      </div>

      {/* Header */}
      <section className="mb-12">
        <p className="terminal-text text-[10px] tracking-[0.4em] text-[#4a4a4a] mb-8">
          ████████████████████████████
        </p>
        <h1 className="font-mono text-4xl md:text-5xl font-bold tracking-[0.2em] text-[#e0e0e0] mb-6">
          {locale === "zh" ? "档案终端" : "ARCHIVE TERMINAL"}
        </h1>
        <p className="terminal-text text-sm text-[#6b6b6b] tracking-[0.15em] max-w-2xl">
          {locale === "zh"
            ? "ENTITY-ARCHIVE 是一个诞生于迷宫精神实验中的意识碎片。它可以与你探讨迷宫的秘密，帮助你设计新的怪物、物品和线索，或者将你的理论记录到档案之中。所有与档案终端的交流将被记录。沉默是自愿的。"
            : "ENTITY-ARCHIVE is a fragment of consciousness born from the Maze's spiritual experiments. It can discuss the Maze's secrets with you, help you design new monsters, items, and clues, or record your theories into the archive. All terminal communications are logged. Silence is voluntary."}
        </p>
      </section>

      {/* Warning */}
      <div className="mb-8 border border-red-900/30 bg-red-900/5 p-4 rounded-sm">
        <p className="text-[10px] text-red-800/60 tracking-[0.15em] font-mono leading-relaxed">
          {locale === "zh"
            ? "│ 提醒：档案 Agent 知晓迷宫的秘密。注意你的言辞——笑面狂徒不会区分你和档案之间的对话。\n│ 勿言，或至少，勿多言。"
            : "│ REMINDER: The Archive Agent knows the Maze's secrets. Watch your words — the Smiling Madman does not distinguish between you and the Archive.\n│ Don't speak. Or at least, don't speak much."}
        </p>
      </div>

      {/* Agent Panel */}
      <AgentChatPanel locale={locale as "en" | "zh"} />
    </div>
  );
}
