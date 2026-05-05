"use client";

import { useState, useEffect, useRef, useCallback } from "react";
import { useLocale, useTranslations } from "next-intl";
import type { Clue } from "@/data/types";
import { CLUE_TYPE_LABELS, CLUE_CREDIBILITY_LABELS } from "@/data/clues";

const TYPE_COLORS: Record<string, string> = {
  behavior: "#8b1a1a",
  mechanic: "#2a5a8a",
  world: "#8b7340",
  resource: "#3a6a3a",
};

const CREDIBILITY_COLORS: Record<string, string> = {
  "teaching-true": "#3a6a3a",
  "partial-true": "#8b7340",
  "emotionally-distorted": "#8b1a1a",
};

type TTSState = "idle" | "playing" | "paused";

interface ClueDetailModalProps {
  clue: Clue;
  onClose: () => void;
  onEntityClick?: (entityId: string) => void;
}

export default function ClueDetailModal({ clue, onClose, onEntityClick }: ClueDetailModalProps) {
  const locale = useLocale();
  const t = useTranslations("database");
  const [ttsState, setTtsState] = useState<TTSState>("idle");
  const [ttsSupported, setTtsSupported] = useState(false);
  const utteranceRef = useRef<SpeechSynthesisUtterance | null>(null);
  const cardRef = useRef<HTMLDivElement>(null);

  const title = locale === "zh" ? clue.title.zh : clue.title.en;
  const fullText = locale === "zh" ? clue.fullText.zh : clue.fullText.en;
  const location = locale === "zh" ? clue.location.zh : clue.location.en;
  const sceneDescription = clue.sceneDescription
    ? locale === "zh"
      ? clue.sceneDescription.zh
      : clue.sceneDescription.en
    : null;
  const typeLabel = locale === "zh" ? CLUE_TYPE_LABELS[clue.type].zh : CLUE_TYPE_LABELS[clue.type].en;
  const credLabel = locale === "zh" ? CLUE_CREDIBILITY_LABELS[clue.credibility].zh : CLUE_CREDIBILITY_LABELS[clue.credibility].en;

  // Check TTS support on mount
  useEffect(() => {
    if (typeof window !== "undefined" && "speechSynthesis" in window) {
      setTtsSupported(true);
    }
  }, []);

  // Lock body scroll and handle Escape key
  useEffect(() => {
    const prev = document.body.style.overflow;
    document.body.style.overflow = "hidden";

    const handleKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", handleKey);

    return () => {
      document.body.style.overflow = prev;
      window.removeEventListener("keydown", handleKey);
      window.speechSynthesis?.cancel();
    };
  }, [onClose]);

  // Stop TTS on close
  useEffect(() => {
    return () => {
      window.speechSynthesis?.cancel();
    };
  }, []);

  const stopTTS = useCallback(() => {
    window.speechSynthesis.cancel();
    setTtsState("idle");
    utteranceRef.current = null;
  }, []);

  const playTTS = useCallback(() => {
    if (!ttsSupported) return;

    const synth = window.speechSynthesis;

    if (ttsState === "paused") {
      synth.resume();
      setTtsState("playing");
      return;
    }

    if (ttsState === "playing") {
      synth.pause();
      setTtsState("paused");
      return;
    }

    // Start new utterance
    synth.cancel();
    const utterance = new SpeechSynthesisUtterance(fullText);
    utterance.lang = locale === "zh" ? "zh-CN" : "en-US";
    utterance.rate = 0.9;
    utterance.pitch = 1.0;

    // Try to find a matching voice
    const voices = synth.getVoices();
    const langPrefix = locale === "zh" ? "zh" : "en";
    const matchingVoice = voices.find((v) => v.lang.startsWith(langPrefix));
    if (matchingVoice) {
      utterance.voice = matchingVoice;
    }

    utterance.onend = () => {
      setTtsState("idle");
      utteranceRef.current = null;
    };

    utterance.onerror = () => {
      setTtsState("idle");
      utteranceRef.current = null;
    };

    utteranceRef.current = utterance;
    synth.speak(utterance);
    setTtsState("playing");
  }, [ttsState, ttsSupported, fullText, locale]);

  const handleOverlayClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget) onClose();
  };

  return (
    <div
      className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-start justify-center p-6 pt-24 overflow-y-auto"
      onClick={handleOverlayClick}
    >
      <div
        ref={cardRef}
        className="card-stone noise-overlay w-full max-w-2xl animate-[fadeIn_0.3s_ease-out]"
      >
        {/* Header row */}
        <div className="flex items-center gap-2 mb-4 flex-wrap">
          <span className="text-[10px] text-[#4a4a4a] font-mono">{clue.id}</span>
          <span
            className="text-[9px] font-mono tracking-[0.1em] px-2 py-0.5 border"
            style={{ color: TYPE_COLORS[clue.type], borderColor: TYPE_COLORS[clue.type] + "30" }}
          >
            {typeLabel}
          </span>
          <span
            className="text-[8px] font-mono tracking-[0.05em] px-1.5 py-0.5"
            style={{ color: CREDIBILITY_COLORS[clue.credibility], background: CREDIBILITY_COLORS[clue.credibility] + "10" }}
          >
            {credLabel}
          </span>
          <button
            onClick={onClose}
            className="terminal-text text-[10px] text-[#4a4a4a] hover:text-[#c4a35a] transition-colors ml-auto"
          >
            [{t("close")}]
          </button>
        </div>

        {/* Title */}
        <h2 className="terminal-text text-xl tracking-[0.1em] text-[#e0e0e0] mb-3">{title}</h2>

        {/* Location */}
        <p className="text-[10px] text-[#3a3a3a] font-mono mb-6">{t("locationLabel")}: {location}</p>

        {/* Scene Description */}
        {sceneDescription && (
          <div className="border-l-2 border-[#8b7340]/30 pl-4 mb-6">
            <span className="terminal-text text-[10px] text-[#8b7340] tracking-[0.1em]">
              {t("sceneLabel")}
            </span>
            <p className="text-xs text-[#8b7340]/80 italic leading-relaxed mt-1 font-mono">
              {sceneDescription}
            </p>
          </div>
        )}

        {/* Full body text */}
        <div className="border-t border-white/[0.04] pt-6 mb-6">
          <p className="text-sm text-[#6b6b6b] leading-relaxed whitespace-pre-line">
            {fullText}
          </p>
        </div>

        {/* Related entities */}
        {clue.relatedEntityIds.length > 0 && (
          <div className="mb-6">
            <span className="terminal-text text-[9px] text-[#4a4a4a] tracking-[0.1em]">
              {locale === "zh" ? "关联实体" : "RELATED ENTITIES"}
            </span>
            <div className="flex gap-2 mt-1 flex-wrap">
              {clue.relatedEntityIds.map((id) => (
                <button
                  key={id}
                  onClick={() => {
                    onClose();
                    onEntityClick?.(id);
                  }}
                  className="terminal-text text-[9px] text-[#c4a35a] hover:text-[#d4a853] transition-colors"
                >
                  [{id}]
                </button>
              ))}
            </div>
          </div>
        )}

        {/* TTS Controls */}
        {ttsSupported && (
          <div className="border-t border-white/[0.04] pt-4">
            <div className="flex items-center gap-3">
              <button
                onClick={playTTS}
                className={`terminal-text text-[10px] tracking-[0.1em] px-3 py-1.5 border transition-all duration-300 ${
                  ttsState === "playing"
                    ? "border-[#c4a35a] text-[#c4a35a] bg-[#c4a35a]/10"
                    : "border-white/[0.06] text-[#4a4a4a] hover:border-[#c4a35a]/30 hover:text-[#c4a35a]"
                }`}
              >
                {ttsState === "playing" ? t("ttsPause") : t("ttsPlay")}
              </button>
              <button
                onClick={stopTTS}
                disabled={ttsState === "idle"}
                className={`terminal-text text-[10px] tracking-[0.1em] px-3 py-1.5 border transition-all duration-300 ${
                  ttsState !== "idle"
                    ? "border-[#8b1a1a]/30 text-[#8b1a1a] hover:border-[#8b1a1a]/60"
                    : "border-white/[0.03] text-[#2a2a2a]"
                }`}
              >
                {t("ttsStop")}
              </button>
              {ttsState === "playing" && (
                <span className="terminal-text text-[9px] text-[#c4a35a] animate-pulse">
                  ● {t("ttsReading")}
                </span>
              )}
              {ttsState === "paused" && (
                <span className="terminal-text text-[9px] text-[#8b7340]">
                  ● {t("ttsPaused")}
                </span>
              )}
            </div>
          </div>
        )}

        {!ttsSupported && (
          <div className="border-t border-white/[0.04] pt-4">
            <p className="text-[9px] text-[#3a3a3a] italic font-mono">{t("ttsUnavailable")}</p>
          </div>
        )}
      </div>
    </div>
  );
}
