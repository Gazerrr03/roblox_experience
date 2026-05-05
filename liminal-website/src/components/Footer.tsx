"use client";

import { useTranslations } from "next-intl";

export default function Footer() {
  const t = useTranslations("footer");

  return (
    <footer className="border-t border-white/[0.04] bg-[#0a0a0a] mt-24">
      <div className="max-w-6xl mx-auto px-6 py-12 flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex flex-col items-center md:items-start gap-1">
          <span className="terminal-text text-xs tracking-[0.2em]">
            LIMINAL
          </span>
          <span className="text-[10px] tracking-[0.15em] text-[#4a4a4a] uppercase">
            &copy; {new Date().getFullYear()} {t("copyright")}
          </span>
        </div>
        <p className="text-xs text-[#4a4a4a] italic font-mono">
          {t("tagline")}
        </p>
      </div>
    </footer>
  );
}
