"use client";

import { useState, useEffect, useRef, useCallback } from "react";

const EASE = "cubic-bezier(0.23, 1, 0.32, 1)";

const SCAN_SHIFTS = [33, 62, 41, 55, 37, 68]; // deterministic per-line float distance

function ScanLines() {
  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden" style={{ opacity: 0.07 }}>
      {[0, 17, 34, 51, 68, 85].map((top, i) => (
        <div
          key={i}
          className="absolute left-0 right-0"
          style={{
            top: `${top}%`,
            height: "1px",
            background: "linear-gradient(90deg, transparent, #c4a35a, transparent)",
            animation: `scan-float-${i} ${4 + i * 1.5}s ease-in-out ${i * 0.7}s infinite alternate`,
          }}
        />
      ))}
      <style>{`
        ${SCAN_SHIFTS.map(
          (shift, i) => `
        @keyframes scan-float-${i} {
          0% { transform: translateY(0); opacity: 0.4; }
          100% { transform: translateY(${shift}px); opacity: 0.9; }
        }`
        ).join("")}
      `}</style>
    </div>
  );
}

// Deterministic pseudo-random values from index to avoid SSR mismatch
function particleLeft(i: number) { return (i * 17) % 100; }
function particleDelay(i: number) { return (i * 7) % 8; }
function particleDur(i: number) { return 6 + (i * 11) % 10; }
function particleSize(i: number) { return 1 + (i * 3) % 3; }

function Particles() {
  return (
    <div className="absolute inset-0 pointer-events-none overflow-hidden">
      {Array.from({ length: 40 }).map((_, i) => (
        <div
          key={i}
          className="absolute rounded-full bg-[#c4a35a]"
          style={{
            left: `${particleLeft(i)}%`,
            bottom: "-4px",
            width: `${particleSize(i)}px`,
            height: `${particleSize(i)}px`,
            opacity: 0,
            animation: `particle-rise ${particleDur(i)}s ${particleDelay(i)}s infinite linear`,
          }}
        />
      ))}
      <style>{`
        @keyframes particle-rise {
          0% { transform: translateY(0) scale(1); opacity: 0; }
          10% { opacity: 0.5; }
          80% { opacity: 0.15; }
          100% { transform: translateY(-100vh) scale(0.3); opacity: 0; }
        }
      `}</style>
    </div>
  );
}

function GlowSpot({ mouse }: { mouse: { x: number; y: number } }) {
  if (mouse.x === 0 && mouse.y === 0) return null;
  return (
    <div
      className="absolute inset-0 pointer-events-none overflow-hidden"
    >
      <div
        style={{
          position: "absolute",
          left: "50%",
          top: "50%",
          width: "400px",
          height: "400px",
          transform: `translate(calc(-50% + ${mouse.x * 100}%), calc(-50% + ${mouse.y * 100}%))`,
          background: "radial-gradient(circle, rgba(196,163,90,0.08) 0%, transparent 70%)",
        }}
      />
    </div>
  );
}

interface LandingHeroProps {
  tagline: string;
}

export default function LandingHero({ tagline }: LandingHeroProps) {
  const sectionRef = useRef<HTMLDivElement>(null);
  const rafRef = useRef<number>(0);
  const [mouse, setMouse] = useState({ x: 0, y: 0 });
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const timer = setTimeout(() => setVisible(true), 100);
    return () => clearTimeout(timer);
  }, []);

  const handleMouseMove = useCallback((e: React.MouseEvent) => {
    if (rafRef.current) return;
    rafRef.current = requestAnimationFrame(() => {
      rafRef.current = 0;
      if (!sectionRef.current) return;
      const rect = sectionRef.current.getBoundingClientRect();
      setMouse({
        x: (e.clientX - rect.left) / rect.width - 0.5,
        y: (e.clientY - rect.top) / rect.height - 0.5,
      });
    });
  }, []);

  const handleMouseLeave = useCallback(() => {
    if (rafRef.current) {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = 0;
    }
    setMouse({ x: 0, y: 0 });
  }, []);

  // 3D card tilt
  const tiltX = mouse.y * -3;
  const tiltY = mouse.x * 3;

  // multi-layer parallax
  const titleOffset = { x: mouse.x * -8, y: mouse.y * -8 };
  const taglineOffset = { x: mouse.x * -16, y: mouse.y * -16 };
  const lineOffset = { x: mouse.x * -24, y: mouse.y * -24 };

  return (
    <section
      ref={sectionRef}
      className="relative w-full flex items-center justify-center overflow-hidden"
      style={{ minHeight: "100vh" }}
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
    >
      {/* Layer 1: background image with parallax */}
      <div
        className="absolute inset-0"
        style={{
          backgroundImage: "url(/assets/01.png)",
          backgroundSize: "cover",
          backgroundPosition: "center",
          transform: `translate(${mouse.x * -12}px, ${mouse.y * -12}px)`,
          transition: `transform 0.8s ${EASE}`,
        }}
      />

      {/* Layer 2: vignette */}
      <div
        className="absolute inset-0"
        style={{
          background: "radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,0.55) 100%)",
        }}
      />

      {/* Layer 3: noise texture */}
      <div
        className="absolute inset-0 pointer-events-none"
        style={{ opacity: 0.03 }}
      >
        <svg width="100%" height="100%">
          <filter id="noise">
            <feTurbulence type="fractalNoise" baseFrequency="0.65" numOctaves="3" stitchTiles="stitch" />
          </filter>
          <rect width="100%" height="100%" filter="url(#noise)" />
        </svg>
      </div>

      {/* Atmosphere: scan lines */}
      <ScanLines />

      {/* Atmosphere: particles */}
      <Particles />

      {/* Glow follow */}
      <GlowSpot mouse={mouse} />

      {/* Content with 3D tilt */}
      <div
        className="relative max-w-2xl w-full text-center px-6"
        style={{
          perspective: "800px",
        }}
      >
        <div
          style={{
            transform: `rotateX(${tiltX}deg) rotateY(${tiltY}deg)`,
            transition: `transform 0.8s ${EASE}`,
            transformStyle: "preserve-3d",
          }}
        >
          {/* Decorative line */}
          <p
            className="terminal-text text-[10px] tracking-[0.4em] text-[#4a4a4a] mb-12"
            style={{
              transform: `translate(${lineOffset.x}px, ${lineOffset.y}px)`,
              transition: `transform 0.8s ${EASE}`,
            }}
          >
            ████████████████████████████
          </p>

          {/* Title */}
          <h1
            className="font-mono text-6xl md:text-8xl font-bold tracking-[0.3em] text-[#e0e0e0] select-none"
            style={{
              transform: `translate(${titleOffset.x}px, ${titleOffset.y}px)`,
              transition: `opacity 800ms ease-out, filter 800ms ease-out, transform 0.8s ${EASE}`,
              opacity: visible ? 1 : 0,
              filter: visible ? "blur(0px)" : "blur(4px)",
            }}
          >
            LIMINAL
          </h1>

          {/* Tagline */}
          <p
            className="terminal-text text-xs md:text-sm tracking-[0.2em] leading-relaxed max-w-lg mx-auto mt-8 select-none"
            style={{
              color: "#9a9a9a",
              transform: `translate(${taglineOffset.x}px, ${taglineOffset.y}px)`,
              transition: `opacity 800ms ease-out 200ms, transform 0.8s ${EASE}`,
              opacity: visible ? 1 : 0,
            }}
          >
            {tagline}
          </p>
        </div>
      </div>
    </section>
  );
}
