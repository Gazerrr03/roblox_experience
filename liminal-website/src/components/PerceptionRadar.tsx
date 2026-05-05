"use client";

import { useEffect, useRef } from "react";
import { useTranslations } from "next-intl";

export default function PerceptionRadar() {
  const t = useTranslations("about");
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const animRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let tick = 0;

    const resize = () => {
      const rect = canvas.parentElement?.getBoundingClientRect();
      if (!rect) return;
      const dpr = window.devicePixelRatio || 1;
      canvas.width = rect.width * dpr;
      canvas.height = rect.height * dpr;
      canvas.style.width = `${rect.width}px`;
      canvas.style.height = `${rect.height}px`;
      ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    };

    resize();
    window.addEventListener("resize", resize);

    const draw = () => {
      const w = canvas.width / (window.devicePixelRatio || 1);
      const h = canvas.height / (window.devicePixelRatio || 1);
      const cx = w / 2;
      const cy = h * 0.55;
      const maxR = Math.min(w, h) * 0.42;

      ctx.clearRect(0, 0, w, h);

      // Draw concentric rings with labels
      const rings = [
        { r: maxR * 0.25, color: "rgba(196,57,43,0.15)", label: t("radarDangerZone") },
        { r: maxR * 0.5, color: "rgba(139,115,64,0.12)", label: t("radarWarningZone") },
        { r: maxR * 0.78, color: "rgba(196,163,90,0.08)", label: t("radarSafeZone") },
      ];

      rings.forEach(({ r, color }) => {
        ctx.beginPath();
        ctx.arc(cx, cy, r, 0, Math.PI * 2);
        ctx.strokeStyle = color;
        ctx.lineWidth = 1;
        ctx.setLineDash([4, 8]);
        ctx.stroke();
        ctx.setLineDash([]);
      });

      // Animated ripple
      const ripplePhase = (tick * 0.02) % (Math.PI * 2);
      for (let i = 0; i < 3; i++) {
        const rippleRadius = ((tick * 0.4 + i * maxR * 0.33) % maxR);
        const alpha = Math.max(0, 0.15 - (rippleRadius / maxR) * 0.15);
        ctx.beginPath();
        ctx.arc(cx, cy, rippleRadius, 0, Math.PI * 2);
        ctx.strokeStyle = `rgba(196,163,90,${alpha})`;
        ctx.lineWidth = 1;
        ctx.stroke();
      }

      // Center point (player)
      ctx.beginPath();
      ctx.arc(cx, cy, 4, 0, Math.PI * 2);
      ctx.fillStyle = "#c4a35a";
      ctx.fill();
      ctx.beginPath();
      ctx.arc(cx, cy, 8, 0, Math.PI * 2);
      ctx.fillStyle = "rgba(196,163,90,0.15)";
      ctx.fill();

      // Crosshair lines
      ctx.strokeStyle = "rgba(74,74,74,0.3)";
      ctx.lineWidth = 0.5;
      ctx.beginPath();
      ctx.moveTo(cx - maxR - 10, cy);
      ctx.lineTo(cx + maxR + 10, cy);
      ctx.moveTo(cx, cy - maxR - 10);
      ctx.lineTo(cx, cy + maxR + 10);
      ctx.stroke();

      // Distance labels
      ctx.font = "8px 'JetBrains Mono', monospace";
      ctx.fillStyle = "#4a4a4a";
      ctx.textAlign = "center";
      rings.forEach(({ r, label }) => {
        ctx.fillText(label, cx + r + 2, cy + 10);
      });

      // Predator indicator (pulses in place)
      const predAngle = Math.PI * 0.35;
      const predDist = maxR * 0.15 + Math.sin(tick * 0.05) * 4;
      const px = cx + Math.cos(predAngle) * predDist;
      const py = cy - Math.sin(predAngle) * predDist;
      const predAlpha = 0.3 + Math.sin(tick * 0.08) * 0.15;

      ctx.beginPath();
      ctx.arc(px, py, 5, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(196,57,43,${predAlpha})`;
      ctx.fill();
      ctx.beginPath();
      ctx.arc(px, py, 10, 0, Math.PI * 2);
      ctx.fillStyle = `rgba(196,57,43,${predAlpha * 0.4})`;
      ctx.fill();

      // "PREDATOR" label
      ctx.font = "7px 'JetBrains Mono', monospace";
      ctx.fillStyle = `rgba(196,57,43,${predAlpha + 0.2})`;
      ctx.fillText("PREDATOR", px, py - 14);

      tick++;
      animRef.current = requestAnimationFrame(draw);
    };

    draw();

    return () => {
      cancelAnimationFrame(animRef.current);
      window.removeEventListener("resize", resize);
    };
  }, [t]);

  return (
    <div className="card-stone p-6 noise-overlay">
      <h3 className="terminal-text text-sm text-[#c4a35a] tracking-[0.1em] mb-2">
        {t("radarTitle")}
      </h3>
      <div className="relative w-full" style={{ aspectRatio: "16/10" }}>
        <canvas ref={canvasRef} className="absolute inset-0 w-full h-full" />
      </div>
    </div>
  );
}
