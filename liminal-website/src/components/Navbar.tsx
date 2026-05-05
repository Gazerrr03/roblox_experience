"use client";

import { useTranslations, useLocale } from "next-intl";
import { Link, usePathname } from "@/i18n/navigation";
import { useState } from "react";

export default function Navbar() {
  const t = useTranslations("common");
  const locale = useLocale();
  const pathname = usePathname();
  const [mobileOpen, setMobileOpen] = useState(false);

  const switchLocale = locale === "en" ? "zh" : "en";

  const navLinks = [
    { href: "/", label: t("nav.home") },
    { href: "/about", label: t("nav.about") },
    { href: "/database", label: t("nav.database") },
    { href: "/ugc", label: t("nav.ugc") },
    { href: "/media", label: t("nav.media") },
    { href: "/blog", label: t("nav.blog") },
    { href: "/community", label: t("nav.community") },
  ];

  return (
    <nav className="border-b border-white/[0.04] bg-[#0a0a0a]/90 backdrop-blur-sm sticky top-0 z-50">
      <div className="max-w-6xl mx-auto px-6 h-16 flex items-center justify-between">
        {/* Logo */}
        <Link
          href="/"
          className="terminal-text text-lg tracking-[0.3em] glitch-hover no-underline"
        >
          LIMINAL
        </Link>

        {/* Desktop nav */}
        <div className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            <Link
              key={link.href}
              href={link.href}
              className={`text-xs tracking-[0.15em] uppercase transition-colors duration-200 no-underline ${
                pathname === link.href
                  ? "text-[#c4a35a]"
                  : "text-[#6b6b6b] hover:text-[#e0e0e0]"
              }`}
            >
              {link.label}
            </Link>
          ))}
          {/* Lang switch */}
          <Link
            href={pathname}
            locale={switchLocale}
            className="text-xs tracking-[0.15em] text-[#4a4a4a] hover:text-[#c4a35a] transition-colors duration-200 no-underline ml-4 border-l border-white/[0.06] pl-4"
          >
            {t("languageSwitch")}
          </Link>
        </div>

        {/* Mobile toggle */}
        <button
          className="md:hidden text-[#6b6b6b] hover:text-[#e0e0e0] transition-colors"
          onClick={() => setMobileOpen(!mobileOpen)}
          aria-label="Toggle menu"
        >
          <svg width="20" height="20" viewBox="0 0 20 20" fill="none">
            {mobileOpen ? (
              <path
                d="M5 5l10 10M15 5L5 15"
                stroke="currentColor"
                strokeWidth="1.5"
              />
            ) : (
              <path
                d="M3 5h14M3 10h14M3 15h14"
                stroke="currentColor"
                strokeWidth="1.5"
              />
            )}
          </svg>
        </button>
      </div>

      {/* Mobile menu */}
      {mobileOpen && (
        <div className="md:hidden border-t border-white/[0.04] bg-[#0a0a0a]">
          <div className="px-6 py-4 flex flex-col gap-4">
            {navLinks.map((link) => (
              <Link
                key={link.href}
                href={link.href}
                onClick={() => setMobileOpen(false)}
                className={`text-xs tracking-[0.15em] uppercase no-underline ${
                  pathname === link.href
                    ? "text-[#c4a35a]"
                    : "text-[#6b6b6b]"
                }`}
              >
                {link.label}
              </Link>
            ))}
            <Link
              href={pathname}
              locale={switchLocale}
              onClick={() => setMobileOpen(false)}
              className="text-xs tracking-[0.15em] text-[#4a4a4a] no-underline pt-2 border-t border-white/[0.04]"
            >
              {t("languageSwitch")}
            </Link>
          </div>
        </div>
      )}
    </nav>
  );
}
