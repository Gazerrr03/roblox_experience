"use client";

import { useEffect, useRef, useState } from "react";

export function useScrollProgress() {
  const ref = useRef<HTMLDivElement>(null);
  const [progress, setProgress] = useState(0);
  const [isNearViewport, setIsNearViewport] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el) return;

    const isMobile = typeof window !== "undefined" && window.innerWidth < 768;
    const rootMargin = isMobile ? "100px 0px" : "200px 0px";

    const observer = new IntersectionObserver(
      ([entry]) => {
        setIsNearViewport(entry.isIntersecting);
      },
      { rootMargin },
    );

    observer.observe(el);

    const handleScroll = () => {
      const rect = el.getBoundingClientRect();
      const viewportH = window.innerHeight;

      if (rect.bottom < 0 || rect.top > viewportH) {
        setProgress(rect.top > viewportH ? 0 : 1);
        return;
      }

      const totalScrollable = rect.height;
      const scrolledPastTop = viewportH - rect.top;
      const raw = scrolledPastTop / totalScrollable;
      setProgress(Math.max(0, Math.min(1, raw)));
    };

    handleScroll();
    let raf: number;
    const onScroll = () => {
      if (raf) cancelAnimationFrame(raf);
      raf = requestAnimationFrame(handleScroll);
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => {
      observer.disconnect();
      window.removeEventListener("scroll", onScroll);
      if (raf) cancelAnimationFrame(raf);
    };
  }, []);

  return { ref, progress, isNearViewport };
}
