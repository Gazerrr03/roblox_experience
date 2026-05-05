import type { AgentState, AgentNode, Intent, ConversationSession } from "./types";

const INTENT_SIGNALS: Record<Intent, { en: string[]; zh: string[] }> = {
  narrate: {
    en: [
      "what is",
      "tell me about",
      "explain",
      "who is",
      "how does",
      "why",
      "lore",
      "story",
      "background",
      "history",
      "archive",
    ],
    zh: [
      "什么是",
      "告诉我",
      "解释",
      "谁",
      "怎么",
      "为什么",
      "故事",
      "背景",
      "历史",
      "档案",
      "设定",
      "世界观",
    ],
  },
  create: {
    en: [
      "create",
      "make",
      "design",
      "generate",
      "build",
      "draw",
      "imagine",
      "new monster",
      "new item",
      "new clue",
      "concept",
      "write",
    ],
    zh: [
      "创造",
      "做",
      "设计",
      "生成",
      "画",
      "想象",
      "新怪物",
      "新物品",
      "新线索",
      "概念",
      "写",
      "创作",
    ],
  },
  explore: {
    en: [
      "i think",
      "my theory",
      "what if",
      "maybe",
      "could it be",
      "is it possible",
      "i believe",
      "suppose",
      "what about",
    ],
    zh: [
      "我觉得",
      "我的理论",
      "如果",
      "也许",
      "会不会",
      "可能",
      "我相信",
      "假设",
      "推测",
      "有没有可能",
    ],
  },
};

export function classifyIntent(
  message: string,
  locale: "en" | "zh"
): Intent {
  const msg = message.toLowerCase();

  const scores: Record<Intent, number> = { narrate: 0, create: 0, explore: 0 };

  for (const [intent, signals] of Object.entries(INTENT_SIGNALS)) {
    const kw = locale === "zh" ? signals.zh : signals.en;
    for (const keyword of kw) {
      if (msg.includes(keyword)) {
        scores[intent as Intent] += 1;
      }
    }
  }

  if (scores.create > scores.narrate && scores.create > scores.explore) {
    return "create";
  }
  if (scores.explore > scores.narrate && scores.explore > scores.create) {
    return "explore";
  }
  return "narrate";
}

function evaluateTransition(
  from: AgentNode,
  intent: Intent | undefined,
  hasToolsResults: boolean,
  playerWantsRefine: boolean,
  playerWantsNew: boolean
): AgentNode {
  switch (from) {
    case "idle":
      return "listening";

    case "listening":
      if (intent === "create") return "create";
      if (intent === "explore") return "explore";
      return "narrate";

    case "narrate":
    case "explore":
      if (playerWantsNew) return "listening";
      return "reveal";

    case "create":
      if (hasToolsResults) return "reveal";
      return "producing";

    case "producing":
      return "reveal";

    case "refining":
      if (playerWantsNew) return "listening";
      return "producing";

    case "reveal":
      if (playerWantsRefine) return "refining";
      if (playerWantsNew) return "listening";
      return "idle";

    default:
      return "idle";
  }
}

function detectPlayerSignals(message: string): {
  wantsRefine: boolean;
  wantsNew: boolean;
} {
  const msg = message.toLowerCase();
  const refineKeywords = [
    "change",
    "revise",
    "different",
    "instead",
    "no",
    "修改",
    "改",
    "换",
    "调整",
    "不",
    "不要",
  ];
  const newKeywords = [
    "new",
    "another",
    "different topic",
    "something else",
    "新",
    "另一个",
    "别的",
    "换个",
  ];

  return {
    wantsRefine: refineKeywords.some((k) => msg.includes(k)),
    wantsNew: newKeywords.some((k) => msg.includes(k)),
  };
}

export class AgentStateMachine {
  private sessions: Map<string, AgentState> = new Map();

  createSession(conversationId: string, locale: "en" | "zh"): AgentState {
    const state: AgentState = {
      conversationId,
      currentNode: "idle",
      locale,
      toolResults: [],
    };
    this.sessions.set(conversationId, state);
    return state;
  }

  getSession(conversationId: string): AgentState | undefined {
    return this.sessions.get(conversationId);
  }

  getOrCreateSession(
    conversationId: string,
    locale: "en" | "zh"
  ): AgentState {
    return (
      this.sessions.get(conversationId) ||
      this.createSession(conversationId, locale)
    );
  }

  transition(state: AgentState, playerMessage: string): AgentState {
    const intent = classifyIntent(playerMessage, state.locale);
    const signals = detectPlayerSignals(playerMessage);
    const hasToolsResults = state.toolResults.length > 0;

    const nextNode = evaluateTransition(
      state.currentNode,
      intent,
      hasToolsResults,
      signals.wantsRefine,
      signals.wantsNew
    );

    const nextState: AgentState = {
      ...state,
      currentNode: nextNode,
      intent: nextNode === "listening" ? undefined : intent,
    };

    if (nextNode === "create" && !state.creationContext) {
      nextState.creationContext = {
        contentType: "monster",
        referencedEntityIds: [],
        generationStage: "concept",
      };
    }

    if (nextNode === "explore" && !state.theoryContext) {
      nextState.theoryContext = {
        topic: "",
        relatedClueIds: [],
        playerHypothesis: playerMessage,
        agentStance: "expanding",
      };
    }

    this.sessions.set(state.conversationId, nextState);
    return nextState;
  }

  updateState(state: AgentState, partial: Partial<AgentState>): AgentState {
    const nextState = { ...state, ...partial };
    this.sessions.set(state.conversationId, nextState);
    return nextState;
  }

  deleteSession(conversationId: string): void {
    this.sessions.delete(conversationId);
  }
}

export const agentStateMachine = new AgentStateMachine();
