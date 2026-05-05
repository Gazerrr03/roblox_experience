"use client";

import { useRef, useEffect, useState } from "react";
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import type { UIMessage } from "ai";

interface AgentChatPanelProps {
  locale: "en" | "zh";
}

const T = {
  placeholder: { en: "Type your message, operative...", zh: "输入你的消息，行动者……" },
  title: { en: "ARCHIVE TERMINAL", zh: "档案终端" },
  subtitle: {
    en: "ENTITY-ARCHIVE // Secure Channel // Clearance: OPERATIVE",
    zh: "ENTITY-ARCHIVE // 安全频道 // 权限级别：行动者",
  },
  stateIdle: { en: "AWAITING INPUT", zh: "等待输入" },
  stateListening: { en: "LISTENING", zh: "聆听中" },
  stateNarrate: { en: "ACCESSING ARCHIVE", zh: "调取档案" },
  stateCreate: { en: "CREATION MODE", zh: "创作模式" },
  stateExplore: { en: "THEORY ANALYSIS", zh: "理论分析" },
  stateProducing: { en: "MATERIALIZING", zh: "具象化中" },
  stateRefining: { en: "REFINING", zh: "精炼中" },
  stateReveal: { en: "RESULT READY", zh: "结果就绪" },
  newSession: { en: "NEW SESSION", zh: "新会话" },
  thinking: { en: "The Archive is processing...", zh: "档案处理中……" },
  userLabel: { en: "OPERATIVE", zh: "行动者" },
  archiveLabel: { en: "ARCHIVE", zh: "档案实体" },
  send: { en: "SEND", zh: "发送" },
  errorTitle: {
    en: "TRANSMISSION ERROR",
    zh: "传输异常",
  },
  errorDefault: {
    en: "The Archive did not respond. The signal is unstable — try again.",
    zh: "档案实体未响应。信号不稳定——请重试。",
  },
  retry: { en: "RETRY", zh: "重试" },
  dismiss: { en: "DISMISS", zh: "关闭" },
} as const;

function renderMessageParts(msg: UIMessage): string {
  const texts: string[] = [];
  for (const part of msg.parts) {
    if (part.type === "text") {
      texts.push(part.text);
    } else if (part.type.startsWith("tool-")) {
      const toolName = part.type.replace("tool-", "");
      texts.push(`\n> ⚙ ${toolName}...\n`);
    } else if (part.type === "dynamic-tool") {
      texts.push(`\n> ⚙ ${part.toolName}\n`);
    }
  }
  return texts.join("");
}

export default function AgentChatPanel({ locale }: AgentChatPanelProps) {
  const sessionId = useRef(`session-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`);
  const scrollRef = useRef<HTMLDivElement>(null);
  const [agentState, setAgentState] = useState<string>("idle");
  const [errorDismissed, setErrorDismissed] = useState(false);
  const userMsgCountRef = useRef(0);

  const { messages, sendMessage, status, error, regenerate } = useChat({
    id: sessionId.current,
    transport: new DefaultChatTransport({
      api: "/api/agent/chat",
      body: {
        sessionId: sessionId.current,
        locale,
      },
    }),
  });

  const userMsgCount = messages.filter((m) => m.role === "user").length;
  if (userMsgCount !== userMsgCountRef.current) {
    if (errorDismissed) setErrorDismissed(false);
    userMsgCountRef.current = userMsgCount;
  }

  useEffect(() => {
    scrollRef.current?.scrollTo({ top: scrollRef.current.scrollHeight, behavior: "smooth" });
  }, [messages]);

  useEffect(() => {
    if (status === "streaming") {
      setAgentState("listening");
    } else {
      setAgentState("idle");
    }
  }, [status]);

  const stateLabel = (() => {
    const key = agentState as keyof typeof T;
    if (key in T) {
      const entry = T[key];
      if (entry && typeof entry === "object" && "en" in entry) {
        return (entry as { en: string; zh: string })[locale];
      }
    }
    return T.stateIdle[locale];
  })();

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const form = e.currentTarget;
    const input = form.elements.namedItem("message") as HTMLInputElement;
    if (!input.value.trim()) return;
    sendMessage({ text: input.value });
    input.value = "";
  };

  return (
    <div className="flex flex-col h-[75vh] border border-cyan-500/20 rounded-lg overflow-hidden font-mono text-sm bg-[#030a14]/90 backdrop-blur-sm shadow-[0_0_60px_rgba(0,180,216,0.05)]">
      {/* Header */}
      <div className="flex items-center justify-between px-5 py-3 border-b border-cyan-500/10 bg-gradient-to-r from-[#0a1628] via-[#0d1f35] to-[#0a1628]">
        <div className="flex items-center gap-3">
          {/* Hexagon icon */}
          <div className="w-7 h-7 flex items-center justify-center">
            <svg viewBox="0 0 24 24" className="w-5 h-5 text-cyan-400/60">
              <polygon
                points="12,1 22,6 22,17 12,22 2,17 2,6"
                fill="none"
                stroke="currentColor"
                strokeWidth="1.5"
              />
            </svg>
          </div>
          <div>
            <div className="text-cyan-400 text-xs tracking-[0.25em] uppercase font-semibold">
              {T.title[locale]}
            </div>
            <div className="text-cyan-700/50 text-[10px] tracking-wider">
              {T.subtitle[locale]}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          {/* Pulsing status dot */}
          <span className="relative flex h-2 w-2">
            <span
              className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${
                status === "streaming" ? "bg-cyan-400" : "bg-cyan-600"
              }`}
            />
            <span
              className={`relative inline-flex rounded-full h-2 w-2 ${
                status === "streaming" ? "bg-cyan-300" : "bg-cyan-500"
              }`}
            />
          </span>
          <span className="text-[10px] text-cyan-600/60 tracking-wider">
            {stateLabel}
          </span>
          <button
            onClick={() => window.location.reload()}
            className="text-[10px] text-cyan-700/50 hover:text-cyan-400 transition-colors border border-cyan-500/20 px-2 py-0.5 rounded"
          >
            {T.newSession[locale]}
          </button>
        </div>
      </div>

      {/* Messages */}
      <div
        ref={scrollRef}
        className="flex-1 overflow-y-auto p-5 space-y-4"
        style={{
          backgroundImage:
            "radial-gradient(circle at 50% 50%, rgba(0,180,216,0.03) 0%, transparent 60%)",
        }}
      >
        {messages.length === 0 && (
          <div className="text-cyan-600/30 text-center mt-12">
            <svg viewBox="0 0 48 48" className="w-12 h-12 mx-auto mb-4 opacity-30">
              <polygon
                points="24,4 40,12 40,28 24,36 8,28 8,12"
                fill="none"
                stroke="currentColor"
                strokeWidth="1"
              />
              <line x1="24" y1="4" x2="24" y2="36" stroke="currentColor" strokeWidth="0.5" />
              <line x1="8" y1="12" x2="40" y2="12" stroke="currentColor" strokeWidth="0.5" />
            </svg>
            <div className="text-sm text-cyan-500/40 animate-pulse">
              {T.placeholder[locale]}
            </div>
            <div className="text-[10px] mt-6 text-cyan-700/15">
              ENTITY-ARCHIVE v1.0 // Secure quantum channel
            </div>
          </div>
        )}

        {messages.map((msg) => (
          <div
            key={msg.id}
            className={`flex ${msg.role === "user" ? "justify-end" : "justify-start"}`}
          >
            <div
              className={`max-w-[80%] px-4 py-3 rounded-lg border ${
                msg.role === "user"
                  ? "bg-amber-500/5 border-amber-500/20 text-amber-200/90"
                  : "bg-cyan-500/[0.03] border-cyan-500/15 text-cyan-100/80"
              }`}
            >
              <div
                className={`text-[10px] mb-1.5 tracking-[0.15em] flex items-center gap-2 ${
                  msg.role === "user" ? "text-amber-600/50" : "text-cyan-600/50"
                }`}
              >
                {msg.role === "assistant" && (
                  <svg viewBox="0 0 12 12" className="w-2.5 h-2.5">
                    <polygon
                      points="6,0 12,3 12,9 6,12 0,9 0,3"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="1"
                    />
                  </svg>
                )}
                [{msg.role === "user" ? T.userLabel[locale] : T.archiveLabel[locale]}]
              </div>
              <div className="whitespace-pre-wrap leading-relaxed text-[13px]">
                {renderMessageParts(msg)}
              </div>
            </div>
          </div>
        ))}

        {error && !errorDismissed && (
          <div className="flex justify-center">
            <div className="max-w-[85%] w-full border border-red-500/30 bg-red-500/[0.04] rounded-lg px-4 py-3">
              <div className="flex items-start gap-3">
                {/* Warning hexagon */}
                <svg viewBox="0 0 16 16" className="w-4 h-4 mt-0.5 shrink-0 text-red-400/60">
                  <polygon
                    points="8,1 15,5 15,11 8,15 1,11 1,5"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="1"
                  />
                  <line x1="8" y1="5" x2="8" y2="9" stroke="currentColor" strokeWidth="1" />
                  <circle cx="8" cy="11" r="0.5" fill="currentColor" />
                </svg>
                <div className="flex-1 min-w-0">
                  <div className="text-[10px] tracking-[0.15em] text-red-400/70 mb-1">
                    {T.errorTitle[locale]}
                  </div>
                  <div className="text-[12px] text-red-300/60 leading-relaxed">
                    {error.message || T.errorDefault[locale]}
                  </div>
                </div>
                <div className="flex gap-2 shrink-0">
                  <button
                    onClick={() => regenerate()}
                    className="text-[10px] text-red-400/50 hover:text-red-300 border border-red-500/20 hover:border-red-400/40 px-2 py-0.5 rounded transition-colors tracking-wider"
                  >
                    {T.retry[locale]}
                  </button>
                  <button
                    onClick={() => setErrorDismissed(true)}
                    className="text-[10px] text-red-400/30 hover:text-red-300 px-2 py-0.5 transition-colors"
                  >
                    {T.dismiss[locale]}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}

        {status === "streaming" && (
          <div className="flex justify-start">
            <div className="bg-cyan-500/[0.03] border border-cyan-500/10 px-4 py-3 rounded-lg text-cyan-400/50 text-[11px] animate-pulse flex items-center gap-2">
              <span className="relative flex h-1.5 w-1.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-cyan-300" />
              </span>
              {T.thinking[locale]}
            </div>
          </div>
        )}
      </div>

      {/* Input */}
      <form onSubmit={handleSubmit} className="border-t border-cyan-500/10 p-4 flex gap-3 bg-[#030a14]/60 backdrop-blur-sm">
        <span className="text-cyan-500/50 self-center text-sm font-mono">{">"}</span>
        <input
          name="message"
          type="text"
          className="flex-1 bg-transparent text-cyan-200/80 placeholder-cyan-700/30 outline-none text-[13px]"
          placeholder={T.placeholder[locale]}
          disabled={status === "streaming"}
          autoComplete="off"
        />
        <button
          type="submit"
          disabled={status === "streaming"}
          className="text-[11px] text-cyan-600/60 hover:text-cyan-300 disabled:opacity-20 transition-all border border-cyan-500/20 px-4 py-1 rounded-md tracking-[0.15em] hover:border-cyan-400/40 hover:shadow-[0_0_12px_rgba(0,180,216,0.15)]"
        >
          {T.send[locale]}
        </button>
      </form>
    </div>
  );
}
