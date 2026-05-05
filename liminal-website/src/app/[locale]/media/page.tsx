"use client";

import { useTranslations } from "next-intl";
import SectionDivider from "@/components/SectionDivider";

const GALLERY = [
  { src: "/gallery-1.jpg", alt: "Screenshot 1" },
  { src: "/gallery-2.jpg", alt: "Screenshot 2" },
  { src: "/gallery-3.jpg", alt: "Screenshot 3" },
  { src: "/gallery-4.jpg", alt: "Screenshot 4" },
];

export default function MediaPage() {
  const t = useTranslations("media");

  return (
    <div className="max-w-6xl mx-auto px-6 py-24">
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

      {/* Screenshots */}
      <section>
        <h2 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-8">
          [{t("screenshots")}]
        </h2>
        <div className="grid sm:grid-cols-2 gap-4">
          {GALLERY.map((img, i) => (
            <div
              key={img.src}
              className="group relative aspect-video bg-[#111] border border-white/[0.06] overflow-hidden cursor-pointer"
            >
              <img
                src={img.src}
                alt={img.alt}
                className="w-full h-full object-cover transition-all duration-700 group-hover:scale-105 group-hover:brightness-110"
                loading={i < 2 ? "eager" : "lazy"}
              />

              {/* Subtle bottom gradient for mood */}
              <div className="absolute inset-0 bg-gradient-to-t from-[#0a0a0a]/30 to-transparent pointer-events-none" />

              {/* Corner index */}
              <span className="absolute top-3 left-3 terminal-text text-[10px] text-[#4a4a4a] tracking-[0.15em] bg-[#0a0a0a]/40 px-2 py-0.5">
                [{String(i + 1).padStart(2, "0")}]
              </span>
            </div>
          ))}
        </div>
      </section>

      <SectionDivider />

      {/* Concept Art placeholder */}
      <section className="mt-24">
        <h2 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-8">
          [{t("conceptArt")}]
        </h2>
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <div
              key={`ca-${i}`}
              className="aspect-[4/3] bg-[#111] border border-white/[0.04] flex items-center justify-center text-[#4a4a4a] font-mono text-xs"
            >
              [ {t("conceptArt")} {i + 1} ]
            </div>
          ))}
        </div>
      </section>

      <SectionDivider />

      {/* Videos placeholder */}
      <section className="mt-24">
        <h2 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-8">
          [{t("videos")}]
        </h2>
        <div className="aspect-video max-w-3xl mx-auto bg-[#111] border border-white/[0.04] flex items-center justify-center text-[#4a4a4a] font-mono text-sm">
          [ VIDEO PLAYER — COMING SOON ]
        </div>
      </section>
    </div>
  );
}
