"use client";

import { useEffect, useState } from "react";

type Animation = "fade" | "decrypt";

interface TextRevealProps {
  children: React.ReactNode;
  progress: number;
  threshold?: number;
  animation?: Animation;
  className?: string;
}

export default function TextReveal({
  children,
  progress,
  threshold = 0,
  animation = "decrypt",
  className = "",
}: TextRevealProps) {
  const [stage, setStage] = useState<-1 | 0 | 1 | 2>(-1);

  useEffect(() => {
    if (progress < threshold) {
      setStage(-1);
      return;
    }

    const localProgress = (progress - threshold) / (1 - threshold);

    if (animation === "fade") {
      setStage(localProgress > 0 ? 2 : -1);
      return;
    }

    // decrypt: 3 stages — red → amber → normal
    if (localProgress < 0.15) {
      setStage(0);
    } else if (localProgress < 0.35) {
      setStage(1);
    } else {
      setStage(2);
    }
  }, [progress, threshold, animation]);

  const base = "transition-all duration-700 ease-out";

  if (stage === -1) {
    return (
      <div className={`${base} opacity-10 blur-[4px] translate-y-4 ${className}`}>
        {children}
      </div>
    );
  }

  if (animation === "fade") {
    return (
      <div className={`${base} opacity-100 blur-0 translate-y-0 ${className}`}>
        {children}
      </div>
    );
  }

  // decrypt stages
  const stageStyles: Record<number, string> = {
    0: "opacity-70 blur-[2px] text-[#8b1a1a] [text-shadow:0_0_12px_rgba(139,26,26,0.5)]",
    1: "opacity-90 blur-[0.5px] text-[#c4a35a] [text-shadow:0_0_6px_rgba(196,163,90,0.3)]",
    2: "opacity-100 blur-0 text-[#e0e0e0]",
  };

  return (
    <div
      className={`${base} ${stageStyles[stage]} ${className}`}
    >
      {children}
    </div>
  );
}
