"use client";

import { useState, useMemo } from "react";
import { useTranslations, useLocale } from "next-intl";
import SectionDivider from "@/components/SectionDivider";
import ThreatTabs from "@/components/ThreatTabs";
import EntityCard from "@/components/EntityCard";
import { MonsterDetail, ItemDetail, TrophyDetail } from "@/components/EntityDetail";
import ClueCard from "@/components/ClueCard";
import ClueDetailModal from "@/components/ClueDetailModal";
import TrophyCard from "@/components/TrophyCard";

import { monsters } from "@/data/monsters";
import { items } from "@/data/items";
import { clues, CLUE_TYPE_LABELS, CLUE_CREDIBILITY_LABELS } from "@/data/clues";
import { trophies } from "@/data/trophies";
import type { Monster, Item, Trophy, Clue } from "@/data/types";
import type { ClueType, ClueCredibility } from "@/data/types";

export default function DatabasePage() {
  const t = useTranslations("database");
  const locale = useLocale();

  const [activeTab, setActiveTab] = useState("monsters");
  const [selectedMonster, setSelectedMonster] = useState<Monster | null>(null);
  const [selectedItem, setSelectedItem] = useState<Item | null>(null);
  const [selectedTrophy, setSelectedTrophy] = useState<Trophy | null>(null);
  const [modalClue, setModalClue] = useState<Clue | null>(null);
  const [clueTypeFilter, setClueTypeFilter] = useState<ClueType | "all">("all");
  const [clueCredFilter, setClueCredFilter] = useState<ClueCredibility | "all">("all");

  const filteredClues = useMemo(() => {
    return clues.filter((c) => {
      if (clueTypeFilter !== "all" && c.type !== clueTypeFilter) return false;
      if (clueCredFilter !== "all" && c.credibility !== clueCredFilter) return false;
      return true;
    });
  }, [clueTypeFilter, clueCredFilter]);

  const handleEntityClick = (entityId: string) => {
    setModalClue(null);

    const monster = monsters.find((m) => m.id === entityId);
    if (monster) {
      setActiveTab("monsters");
      setSelectedMonster(monster);
      return;
    }
    const item = items.find((i) => i.id === entityId);
    if (item) {
      setActiveTab("items");
      setSelectedItem(item);
    }
  };

  const tabs = [
    { key: "monsters", label: t("tabMonsters") },
    { key: "items", label: t("tabItems") },
    { key: "clues", label: t("tabClues") },
    { key: "trophies", label: t("tabTrophies") },
  ];

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

      <SectionDivider />

      {/* Tab bar */}
      <section className="mt-24">
        <ThreatTabs tabs={tabs} activeTab={activeTab} onTabChange={(key) => {
          setActiveTab(key);
          setSelectedMonster(null);
          setSelectedItem(null);
          setSelectedTrophy(null);
          setModalClue(null);
        }}>
          {/* ═══ MONSTERS TAB ═══ */}
          {activeTab === "monsters" && (
            <div>
              {selectedMonster ? (
                <MonsterDetail
                  monster={selectedMonster}
                  onBack={() => setSelectedMonster(null)}
                />
              ) : (
                <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {monsters.map((m) => (
                    <EntityCard
                      key={m.id}
                      id={m.id}
                      name={m.alias}
                      subtitle={locale === "zh" ? m.type.zh : m.type.en}
                      tag={m.codename}
                      onClick={() => setSelectedMonster(m)}
                    />
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ═══ ITEMS TAB ═══ */}
          {activeTab === "items" && (
            <div>
              {selectedItem ? (
                <ItemDetail item={selectedItem} onBack={() => setSelectedItem(null)} />
              ) : (
                <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {items.map((item) => (
                    <EntityCard
                      key={item.id}
                      id={item.id}
                      name={item.name}
                      subtitle={locale === "zh" ? item.description.zh : item.description.en}
                      tag={t("shopPurchase")}
                      onClick={() => setSelectedItem(item)}
                    />
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ═══ CLUES TAB ═══ */}
          {activeTab === "clues" && (
            <div>
              {/* Filters */}
              <div className="flex flex-wrap gap-4 mb-6">
                <div className="flex items-center gap-2">
                  <span className="text-[9px] text-[#4a4a4a] font-mono">{t("filters")}:</span>
                  <select
                    value={clueTypeFilter}
                    onChange={(e) => setClueTypeFilter(e.target.value as ClueType | "all")}
                    className="bg-[#111] border border-white/[0.06] text-[10px] text-[#6b6b6b] font-mono px-2 py-1"
                  >
                    <option value="all">{t("categoryAll")}</option>
                    {(Object.keys(CLUE_TYPE_LABELS) as ClueType[]).map((type) => (
                      <option key={type} value={type}>
                        {locale === "zh" ? CLUE_TYPE_LABELS[type].zh : CLUE_TYPE_LABELS[type].en}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="flex items-center gap-2">
                  <select
                    value={clueCredFilter}
                    onChange={(e) => setClueCredFilter(e.target.value as ClueCredibility | "all")}
                    className="bg-[#111] border border-white/[0.06] text-[10px] text-[#6b6b6b] font-mono px-2 py-1"
                  >
                    <option value="all">{t("categoryAll")}</option>
                    {(Object.keys(CLUE_CREDIBILITY_LABELS) as ClueCredibility[]).map((cred) => (
                      <option key={cred} value={cred}>
                        {locale === "zh" ? CLUE_CREDIBILITY_LABELS[cred].zh : CLUE_CREDIBILITY_LABELS[cred].en}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {filteredClues.length === 0 ? (
                <div className="text-center py-12">
                  <p className="text-xs text-[#4a4a4a] italic font-mono">
                    {locale === "zh" ? "没有匹配的线索档案。" : "No matching clue dossiers."}
                  </p>
                </div>
              ) : (
                <div className="grid sm:grid-cols-2 gap-4">
                  {filteredClues.map((clue) => (
                    <ClueCard
                      key={clue.id}
                      clue={clue}
                      onClick={(c) => setModalClue(c)}
                    />
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ═══ TROPHIES TAB ═══ */}
          {activeTab === "trophies" && (
            <div>
              {selectedTrophy ? (
                <TrophyDetail
                  trophy={selectedTrophy}
                  onBack={() => setSelectedTrophy(null)}
                />
              ) : (
                <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
                  {trophies.map((trophy) => (
                    <TrophyCard
                      key={trophy.id}
                      trophy={trophy}
                      onClick={() => setSelectedTrophy(trophy)}
                    />
                  ))}
                </div>
              )}
            </div>
          )}
        </ThreatTabs>
      </section>

      {/* Clue Detail Modal */}
      {modalClue && (
        <ClueDetailModal
          clue={modalClue}
          onClose={() => setModalClue(null)}
          onEntityClick={handleEntityClick}
        />
      )}
    </div>
  );
}
