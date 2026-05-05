"use client";

import { useState, useEffect, useCallback } from "react";
import { OrbitControls } from "@react-three/drei";
import AtmosphericCanvas from "./AtmosphericCanvas";
import TextReveal from "./TextReveal";
import { useScrollProgress } from "./useScrollProgress";

interface ChapterText {
  text: string;
  threshold?: number;
  className?: string;
}

interface ChapterSectionProps {
  scene: React.ComponentType;
  chapterNumber: number;
  chapterTitle: string;
  texts: ChapterText[];
  className?: string;
}

export default function ChapterSection({
  scene: SceneComponent,
  chapterNumber,
  chapterTitle,
  texts,
  className = "",
}: ChapterSectionProps) {
  const { ref, progress, isNearViewport } = useScrollProgress();
  const [shouldRender, setShouldRender] = useState(false);

  useEffect(() => {
    if (isNearViewport && !shouldRender) {
      setShouldRender(true);
    }
  }, [isNearViewport, shouldRender]);

  const handleUnmount = useCallback(() => {
    if (!isNearViewport) {
      setShouldRender(false);
    }
  }, [isNearViewport]);

  useEffect(() => {
    if (!isNearViewport && shouldRender) {
      const timer = setTimeout(handleUnmount, 2000);
      return () => clearTimeout(timer);
    }
  }, [isNearViewport, shouldRender, handleUnmount]);

  return (
    <section
      ref={ref}
      className={`chapter-section relative w-full ${className}`}
      style={{ minHeight: "100vh" }}
    >
      {/* Sticky 3D canvas background */}
      <div className="chapter-canvas-sticky sticky top-0 h-screen w-full -z-10">
        {shouldRender && (
          <AtmosphericCanvas progress={progress}>
            <OrbitControls
              enableZoom={false}
              enablePan={false}
              rotateSpeed={0.3}
              autoRotate
              autoRotateSpeed={0.15}
            />
            <SceneComponent />
          </AtmosphericCanvas>
        )}
      </div>

      {/* Text overlay */}
      <div className="chapter-text-overlay absolute inset-0 pointer-events-none flex flex-col items-center justify-center px-6">
        <div className="max-w-2xl w-full space-y-10 px-6 py-12 rounded-lg" style={{ background: "rgba(0,0,0,0.3)", backdropFilter: "blur(6px)" }}>
          {/* Chapter number + title */}
          <TextReveal
            progress={progress}
            threshold={0}
            animation="decrypt"
            className="text-center"
          >
            <span className="terminal-text text-[10px] tracking-[0.3em] text-[#4a4a4a] block mb-4">
              CHAPTER {String(chapterNumber).padStart(2, "0")}
            </span>
            <h2 className="terminal-text text-xl md:text-2xl tracking-[0.15em] text-[#c4a35a]">
              {chapterTitle}
            </h2>
          </TextReveal>

          {/* Chapter body texts */}
          {texts.map((t, i) => (
            <TextReveal
              key={i}
              progress={progress}
              threshold={t.threshold ?? 0.15 + i * 0.2}
              animation="decrypt"
              className={t.className}
            >
              <p className="text-sm md:text-base leading-relaxed font-sans max-w-lg mx-auto">
                {t.text}
              </p>
            </TextReveal>
          ))}
        </div>
      </div>
    </section>
  );
}
