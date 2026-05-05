"use client";

import { useState } from "react";
import { useTranslations } from "next-intl";

interface StateDef {
  key: string;
  labelKey: string;
  descKey: string;
  triggerKey: string;
  exitKey: string;
  isLethal?: boolean;
}

const STATES: StateDef[] = [
  { key: "idle", labelKey: "stateIdle", descKey: "stateIdleDesc", triggerKey: "stateIdleTrigger", exitKey: "stateIdleExit" },
  { key: "tracking", labelKey: "stateTracking", descKey: "stateTrackingDesc", triggerKey: "stateTrackingTrigger", exitKey: "stateTrackingExit" },
  { key: "investigating", labelKey: "stateInvestigating", descKey: "stateInvestigatingDesc", triggerKey: "stateInvestigatingTrigger", exitKey: "stateInvestigatingExit" },
  { key: "hunting", labelKey: "stateHunting", descKey: "stateHuntingDesc", triggerKey: "stateHuntingTrigger", exitKey: "stateHuntingExit" },
  { key: "lethal", labelKey: "stateLethal", descKey: "stateLethalDesc", triggerKey: "stateLethalTrigger", exitKey: "stateLethalExit", isLethal: true },
];

export default function BehaviorStateMachine() {
  const t = useTranslations("about");
  const [selectedState, setSelectedState] = useState<string | null>(null);

  const selected = STATES.find((s) => s.key === selectedState);

  return (
    <div className="card-stone p-6 md:p-8 noise-overlay">
      {/* State nodes */}
      <div className="flex items-start gap-0 overflow-x-auto pb-4">
        {STATES.map((state, i) => {
          const isSelected = state.key === selectedState;
          const isLethal = state.isLethal;
          return (
            <div key={state.key} className="flex items-center shrink-0">
              <button
                onClick={() => setSelectedState(isSelected ? null : state.key)}
                className={`shrink-0 px-3 py-3 border text-center min-w-[90px] transition-all duration-300 ${
                  isLethal
                    ? isSelected
                      ? "border-[#c0392b] bg-[#c0392b]/10 shadow-[0_0_15px_rgba(192,57,43,0.2)]"
                      : "border-[#8b1a1a]/30 hover:border-[#c0392b]/50"
                    : isSelected
                      ? "border-[#c4a35a] bg-[#c4a35a]/10 shadow-[0_0_15px_rgba(196,163,90,0.1)]"
                      : "border-white/[0.06] hover:border-[#c4a35a]/30"
                }`}
              >
                <span
                  className={`block text-[10px] tracking-[0.1em] font-mono ${
                    isSelected ? (isLethal ? "text-[#c0392b]" : "text-[#c4a35a]") : "text-[#4a4a4a]"
                  }`}
                >
                  {t(state.labelKey)}
                </span>
              </button>
              {/* Arrow between nodes */}
              {i < STATES.length - 1 && (
                <div className="flex items-center shrink-0 px-1">
                  <div className="w-4 h-px bg-[#2a2520]" />
                  <div className="w-0 h-0 border-t-[4px] border-t-transparent border-b-[4px] border-b-transparent border-l-[5px] border-l-[#2a2520]" />
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Selected state detail */}
      <div className="mt-6 min-h-[120px]">
        {selected ? (
          <div className="border-l-2 border-[#c4a35a]/30 pl-4 py-1">
            <h4 className="terminal-text text-sm tracking-[0.1em] mb-2" style={{ color: selected.isLethal ? "#c0392b" : "#c4a35a" }}>
              {t(selected.labelKey)}
            </h4>
            <p className="text-sm text-[#6b6b6b] leading-relaxed mb-3">{t(selected.descKey)}</p>
            <div className="space-y-1">
              <p className="text-[10px] text-[#4a4a4a] font-mono">
                <span className="text-[#8b7340]">{t(selected.triggerKey)}</span>
              </p>
              <p className="text-[10px] text-[#4a4a4a] font-mono">{t(selected.exitKey)}</p>
            </div>
          </div>
        ) : (
          <p className="text-xs text-[#4a4a4a] italic font-mono text-center py-4">
            [ {t("tabChase")} — {t("stateIdle")} / {t("stateTracking")} / {t("stateInvestigating")} / {t("stateHunting")} / {t("stateLethal")} ]
          </p>
        )}
      </div>
    </div>
  );
}
