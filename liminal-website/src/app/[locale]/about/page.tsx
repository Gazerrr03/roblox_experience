"use client";

import { useTranslations } from "next-intl";
import SectionDivider from "@/components/SectionDivider";
import PerceptionRadar from "@/components/PerceptionRadar";
import BehaviorStateMachine from "@/components/BehaviorStateMachine";

export default function AboutPage() {
  const t = useTranslations("about");

  return (
    <div className="max-w-6xl mx-auto px-6 py-24">
      {/* Header */}
      <section className="text-center mb-24">
        <p className="terminal-text text-[10px] tracking-[0.4em] text-[#4a4a4a] mb-8">
          ████████████████████████████
        </p>
        <h1 className="font-mono text-5xl md:text-6xl font-bold tracking-[0.2em] text-[#e0e0e0] mb-6">
          {t("title")}
        </h1>
        <p className="terminal-text text-sm text-[#6b6b6b] tracking-[0.15em]">
          {t("subtitle")}
        </p>
      </section>

      <SectionDivider />

      {/* 1. Worldview */}
      <section className="mt-24">
        <h2 className="classified text-sm mb-8">{t("worldviewTitle")}</h2>
        <div className="grid md:grid-cols-2 gap-8">
          <p className="text-sm text-[#6b6b6b] leading-relaxed">
            {t("worldviewP1")}
          </p>
          <p className="text-sm text-[#6b6b6b] leading-relaxed">
            {t("worldviewP2")}
          </p>
        </div>
      </section>

      <SectionDivider />

      {/* 2. Core Rule: Sound is Death */}
      <section className="mt-24 max-w-3xl mx-auto">
        <div className="card-dossier p-8 md:p-12 noise-overlay">
          <h2 className="classified text-lg mb-4">{t("coreRule")}</h2>
          <p className="text-sm text-[#6b6b6b] leading-relaxed">
            {t("coreRuleDesc")}
          </p>
        </div>
      </section>

      <SectionDivider />

      {/* 3. Sound Tier System */}
      <section className="mt-24">
        <h2 className="terminal-text text-xl tracking-[0.2em] text-[#c4a35a] mb-8 text-center">
          {t("soundTierSection")}
        </h2>
        <p className="text-sm text-[#6b6b6b] leading-relaxed mb-12 text-center max-w-2xl mx-auto">
          {t("soundTierIntro")}
        </p>

        <div className="card-stone p-6 noise-overlay max-w-2xl mx-auto">
          <h4 className="terminal-text text-xs text-[#4a4a4a] tracking-[0.1em] mb-4">
            TIER THREAT CONTEXT
          </h4>
          <div className="grid sm:grid-cols-2 gap-3">
            {[
              { tier: 1, distance: 30, speed: 0, actionKey: "自由行动，保持安静移动。" },
              { tier: 2, distance: 80, speed: 0.5, actionKey: "减少奔跑，注意环境声音反馈。" },
              { tier: 3, distance: 150, speed: 1.0, actionKey: "立即停止当前动作，寻找掩体。" },
              { tier: 4, distance: 300, speed: 1.5, actionKey: "闭嘴。不要动。不要跑。" },
            ].map(({ tier, distance, speed, actionKey }) => (
              <div key={tier} className="border border-white/[0.04] p-3">
                <span className="terminal-text text-[10px] text-[#c4a35a]">
                  TIER {tier}
                </span>
                <p className="text-[10px] text-[#6b6b6b] mt-1">
                  {t("soundTierDistance", { distance })}
                </p>
                <p className="text-[10px] text-[#6b6b6b]">
                  {t("soundTierSpeed", { speed })}
                </p>
                {actionKey && (
                  <p className="text-[10px] text-[#8b7340] mt-1">
                    {t("soundTierAction", { action: actionKey })}
                  </p>
                )}
              </div>
            ))}
          </div>
        </div>
      </section>

      <SectionDivider />

      {/* 4. Headline Threat: The Listener */}
      <section className="mt-24">
        <h2 className="terminal-text text-xl tracking-[0.2em] text-[#c4a35a] mb-16 text-center">
          {t("headlineTitle")}
        </h2>

        <div className="card-dossier noise-overlay p-8 md:p-12">
          {/* Dossier header */}
          <div className="mb-8">
            <p className="classified text-xs mb-2">{t("headlineName")}</p>
            <h3 className="terminal-text text-2xl tracking-[0.15em] text-[#e0e0e0]">
              {t("headlineAlias")}
            </h3>
            <p className="terminal-text text-xs text-[#6b6b6b] mt-2 tracking-[0.1em]">
              {t("headlineType")}
            </p>
          </div>

          {/* Behavior */}
          <div className="space-y-8">
            <div>
              <h4 className="terminal-text text-sm text-[#c4a35a] tracking-[0.1em] mb-3">
                {t("headlineBehavior")}
              </h4>
              <p className="text-sm text-[#6b6b6b] leading-relaxed">
                {t("headlineBehaviorDesc")}
              </p>
            </div>

            <div className="border-l-2 border-[#8b1a1a] pl-4 py-2">
              <p className="classified text-[10px] mb-2">{t("clueReference")}</p>
              <p className="text-sm text-[#8b7340] italic leading-relaxed font-mono">
                {t("clueText")}
              </p>
            </div>
          </div>

          <SectionDivider />

          {/* Perception Radar */}
          <div className="mt-12">
            <h4 className="terminal-text text-sm text-[#c4a35a] tracking-[0.1em] mb-6">
              {t("headlinePerception")}
            </h4>
            <p className="text-sm text-[#6b6b6b] leading-relaxed mb-8">
              {t("headlinePerceptionDesc")}
            </p>
            <PerceptionRadar />
          </div>

          <SectionDivider />

          {/* Chase + State Machine */}
          <div className="mt-12 space-y-8">
            <BehaviorStateMachine />

            <div>
              <h4 className="terminal-text text-sm text-[#c4a35a] tracking-[0.1em] mb-4">
                {t("headlineChase")}
              </h4>
              <div className="space-y-2 font-mono text-sm text-[#6b6b6b]">
                <p>{t("headlineChase1")}</p>
                <p>{t("headlineChase2")}</p>
                <p>{t("headlineChase3")}</p>
                <p>{t("headlineChase4")}</p>
                <p>{t("headlineChase5")}</p>
              </div>
            </div>

            {/* Fairness guarantees */}
            <div>
              <h4 className="terminal-text text-sm text-[#c4a35a] tracking-[0.1em] mb-4">
                {t("headlineFairness")}
              </h4>
              <ul className="space-y-3 text-sm text-[#6b6b6b]">
                <li className="flex gap-3">
                  <span className="text-[#c4a35a] font-mono shrink-0">01</span>
                  {t("headlineFairness1")}
                </li>
                <li className="flex gap-3">
                  <span className="text-[#c4a35a] font-mono shrink-0">02</span>
                  {t("headlineFairness2")}
                </li>
                <li className="flex gap-3">
                  <span className="text-[#c4a35a] font-mono shrink-0">03</span>
                  {t("headlineFairness3")}
                </li>
                <li className="flex gap-3">
                  <span className="text-[#c4a35a] font-mono shrink-0">04</span>
                  {t("headlineFairness4")}
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      <SectionDivider />

      {/* 5. Run → Maze → Return Loop */}
      <section className="mt-24">
        <h2 className="terminal-text text-xl tracking-[0.2em] text-[#c4a35a] mb-16 text-center">
          {t("loopTitle")}
        </h2>

        <div className="grid md:grid-cols-3 gap-12">
          {/* Run */}
          <div className="card-stone p-8 flex flex-col items-center text-center gap-4">
            <span className="terminal-text text-xs text-[#4a4a4a] tracking-[0.2em]">
              PHASE 01
            </span>
            <h3 className="terminal-text text-lg tracking-[0.15em] text-[#e0e0e0]">
              {t("runTitle")}
            </h3>
            <p className="text-sm text-[#6b6b6b] leading-relaxed">
              {t("runDesc")}
            </p>
          </div>

          {/* Maze */}
          <div className="card-stone p-8 flex flex-col items-center text-center gap-4 border-t-2 border-[#8b1a1a]">
            <span className="terminal-text text-xs text-[#8b1a1a] tracking-[0.2em]">
              PHASE 02
            </span>
            <h3 className="terminal-text text-lg tracking-[0.15em] text-[#c0392b]">
              {t("mazeTitle")}
            </h3>
            <p className="text-sm text-[#6b6b6b] leading-relaxed">
              {t("mazeDesc")}
            </p>
          </div>

          {/* Return */}
          <div className="card-stone p-8 flex flex-col items-center text-center gap-4">
            <span className="terminal-text text-xs text-[#4a4a4a] tracking-[0.2em]">
              PHASE 03
            </span>
            <h3 className="terminal-text text-lg tracking-[0.15em] text-[#e0e0e0]">
              {t("returnTitle")}
            </h3>
            <p className="text-sm text-[#6b6b6b] leading-relaxed">
              {t("returnDesc")}
            </p>
          </div>
        </div>
      </section>

      <SectionDivider />

      {/* 6. Pages as Currency */}
      <section className="mt-24 max-w-3xl mx-auto">
        <h2 className="terminal-text text-xl tracking-[0.2em] text-[#c4a35a] mb-8 text-center">
          {t("pagesTitle")}
        </h2>
        <div className="grid md:grid-cols-2 gap-8">
          <p className="text-sm text-[#6b6b6b] leading-relaxed">
            {t("pagesP1")}
          </p>
          <p className="text-sm text-[#8b7340] leading-relaxed italic font-mono">
            {t("pagesP2")}
          </p>
        </div>
      </section>

      <SectionDivider />

      {/* 7. Survival Philosophy */}
      <section className="mt-24">
        <h2 className="terminal-text text-xl tracking-[0.2em] text-[#c4a35a] mb-16 text-center">
          {t("retreatTitle")}
        </h2>

        <div className="grid md:grid-cols-2 gap-8 mb-16">
          <div className="card-stone p-8 noise-overlay">
            <h3 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-4">
              {t("retreatTitle")}
            </h3>
            <p className="text-sm text-[#6b6b6b] leading-relaxed mb-4">
              {t("retreatP1")}
            </p>
            <p className="text-sm text-[#8b7340] leading-relaxed italic font-mono">
              {t("retreatP2")}
            </p>
          </div>

          <div className="card-stone p-8 noise-overlay">
            <h3 className="terminal-text text-lg tracking-[0.15em] text-[#c4a35a] mb-4">
              {t("toolsTitle")}
            </h3>
            <p className="text-sm text-[#6b6b6b] leading-relaxed mb-4">
              {t("toolsP1")}
            </p>
            <p className="text-sm text-[#8b1a1a] leading-relaxed font-mono text-xs">
              {t("toolsP2")}
            </p>
          </div>
        </div>

        {/* Aftermath */}
        <div className="max-w-2xl mx-auto text-center mb-16">
          <h3 className="classified text-sm mb-6">{t("aftermathTitle")}</h3>
          <p className="text-sm text-[#6b6b6b] leading-relaxed mb-6">
            {t("aftermathP1")}
          </p>
          <p className="terminal-text text-sm text-[#c4a35a]">
            {t("aftermathP2")}
          </p>
        </div>

        {/* 5-Round Arc */}
        <div>
          <h3 className="terminal-text text-xl tracking-[0.2em] text-[#c4a35a] mb-12 text-center">
            {t("pacingTitle")}
          </h3>
          <div className="space-y-4 max-w-2xl mx-auto">
            {[1, 2, 3, 4].map((i) => (
              <div
                key={i}
                className="card-stone p-6 flex items-start gap-6 noise-overlay"
              >
                <span className="terminal-text text-lg text-[#4a4a4a] shrink-0">
                  [{i}]
                </span>
                <p className="text-sm text-[#6b6b6b] leading-relaxed">
                  {t(`round${i}`)}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <SectionDivider />

      {/* 8. Core Philosophy */}
      <section className="mt-24 max-w-3xl mx-auto text-center">
        <h2 className="classified text-sm mb-8">{t("philosophyTitle")}</h2>
        <p className="text-sm text-[#6b6b6b] leading-relaxed mb-6">
          {t("philosophyP1")}
        </p>
        <p className="terminal-text text-sm text-[#c4a35a]">
          {t("philosophyP2")}
        </p>
      </section>
    </div>
  );
}
