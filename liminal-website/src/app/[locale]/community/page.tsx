"use client";

import { useTranslations, useLocale } from "next-intl";
import { Link } from "@/i18n/navigation";

export default function CommunityPage() {
  const t = useTranslations("community");
  const locale = useLocale();

  return (
    <div className="max-w-3xl mx-auto px-6 py-24">
      {/* Header */}
      <section className="text-center mb-24">
        <p className="terminal-text text-[10px] tracking-[0.4em] text-[#4a4a4a] mb-8">
          ████████████████████████████
        </p>
        <h1 className="font-mono text-4xl md:text-5xl font-bold tracking-[0.2em] text-[#e0e0e0] mb-6">
          {t("title")}
        </h1>
        <p className="terminal-text text-sm text-[#6b6b6b] tracking-[0.15em]">
          {t("subtitle")}
        </p>
      </section>

      <div className="space-y-12">
        {/* Discord */}
        <div className="card-stone p-8 noise-overlay text-center">
          <h2 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-3">
            {t("discord")}
          </h2>
          <p className="text-sm text-[#6b6b6b] mb-6">{t("discordDesc")}</p>
          <a
            href="#"
            className="inline-block terminal-text text-sm tracking-[0.1em] text-[#c4a35a] border border-[#c4a35a]/30 px-6 py-3 hover:bg-[#c4a35a]/10 transition-all duration-300 hover:border-[#c4a35a]/60"
          >
            [ JOIN DISCORD ]
          </a>
        </div>

        {/* Socials */}
        <div className="card-stone p-8 noise-overlay text-center">
          <h2 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-3">
            {t("socials")}
          </h2>
          <p className="text-sm text-[#6b6b6b] mb-6">{t("socialsDesc")}</p>
          <div className="flex justify-center gap-4">
            <a
              href="#"
              className="terminal-text text-xs text-[#4a4a4a] hover:text-[#c4a35a] transition-colors tracking-[0.1em]"
            >
              [TWITTER]
            </a>
            <a
              href="#"
              className="terminal-text text-xs text-[#4a4a4a] hover:text-[#c4a35a] transition-colors tracking-[0.1em]"
            >
              [YOUTUBE]
            </a>
            <a
              href="#"
              className="terminal-text text-xs text-[#4a4a4a] hover:text-[#c4a35a] transition-colors tracking-[0.1em]"
            >
              [GITHUB]
            </a>
          </div>
        </div>

        {/* Archive Terminal */}
        <div className="card-stone p-8 noise-overlay text-center border-amber-900/30">
          <h2 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-3">
            {t("archiveTerminal")}
          </h2>
          <p className="text-sm text-[#6b6b6b] mb-6">{t("archiveTerminalDesc")}</p>
          <Link
            href="/community/agent"
            className="inline-block terminal-text text-sm tracking-[0.1em] text-[#c4a35a] border border-[#c4a35a]/30 px-6 py-3 hover:bg-[#c4a35a]/10 transition-all duration-300 hover:border-[#c4a35a]/60"
          >
            [ {t("accessTerminal")} ]
          </Link>
        </div>

        {/* Contact */}
        <div className="card-stone p-8 noise-overlay text-center">
          <h2 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-3">
            {t("contact")}
          </h2>
          <p className="text-sm text-[#6b6b6b] mb-6">{t("contactDesc")}</p>
          <a
            href="mailto:contact@liminal-game.com"
            className="terminal-text text-sm tracking-[0.1em] text-[#6b6b6b] hover:text-[#c4a35a] transition-colors"
          >
            contact@liminal-game.com
          </a>
        </div>
      </div>
    </div>
  );
}
