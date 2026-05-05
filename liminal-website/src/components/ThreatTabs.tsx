"use client";

import type { ReactNode } from "react";

interface Tab {
  key: string;
  label: string;
}

interface ThreatTabsProps {
  tabs: Tab[];
  activeTab: string;
  onTabChange: (key: string) => void;
  children: ReactNode;
}

export default function ThreatTabs({ tabs, activeTab, onTabChange, children }: ThreatTabsProps) {
  return (
    <div>
      {/* Tab bar */}
      <div className="flex gap-0 border-b border-white/[0.06] overflow-x-auto -mx-1 px-1">
        {tabs.map((tab) => {
          const isActive = tab.key === activeTab;
          return (
            <button
              key={tab.key}
              onClick={() => onTabChange(tab.key)}
              className={`shrink-0 px-4 py-3 text-xs tracking-[0.15em] transition-all duration-300 border-b-2 -mb-[1px] ${
                isActive
                  ? "text-[#c4a35a] border-[#c4a35a]"
                  : "text-[#4a4a4a] border-transparent hover:text-[#6b6b6b] hover:border-[#2a2520]"
              }`}
            >
              {tab.label}
            </button>
          );
        })}
      </div>

      {/* Tab content */}
      <div className="mt-8">{children}</div>
    </div>
  );
}
