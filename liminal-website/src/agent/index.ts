import type { ModelMessage } from "ai";
import type { AgentState } from "./types";
import { agentStateMachine } from "./state-machine";
import { buildSystemPrompt, buildStateInstructions } from "./system-prompt";
import { retrieveRelevantLore, formatLoreContext } from "./lore-context";

interface ProcessedMessage {
  systemPrompt: string;
  messages: ModelMessage[];
  state: AgentState;
}

export function processMessage(
  sessionId: string,
  messages: ModelMessage[],
  locale: "en" | "zh"
): ProcessedMessage {
  const state = agentStateMachine.getOrCreateSession(sessionId, locale);

  const lastUserMessage = [...messages]
    .reverse()
    .find((m) => m.role === "user");

  if (lastUserMessage && lastUserMessage.content) {
    const content =
      typeof lastUserMessage.content === "string"
        ? lastUserMessage.content
        : Array.isArray(lastUserMessage.content)
          ? lastUserMessage.content
              .filter(
                (p): p is { type: "text"; text: string } =>
                  typeof p === "object" && p !== null && "type" in p && p.type === "text"
              )
              .map((p) => p.text)
              .join(" ")
          : "";

    const nextState = agentStateMachine.transition(state, content);

    const lore = retrieveRelevantLore(content, locale);
    const loreBlock = formatLoreContext(lore, locale);

    const basePrompt = buildSystemPrompt(locale);
    const stateInstructions = buildStateInstructions(
      nextState.currentNode,
      locale
    );

    const systemPrompt = `${basePrompt}

## Current Archive Node: ${nextState.currentNode.toUpperCase()}
${stateInstructions}

${loreBlock ? `\n## Retrieved Archive Records\n${loreBlock}` : ""}

${
  nextState.creationContext
    ? `\n## Current Creation Context\nThe operative is designing a ${nextState.creationContext.contentType}. Stage: ${nextState.creationContext.generationStage}.`
    : ""
}
${
  nextState.theoryContext
    ? `\n## Current Theory Exploration\nThe operative is exploring: ${nextState.theoryContext.playerHypothesis.slice(0, 200)}`
    : ""
}`;

    return {
      systemPrompt,
      messages,
      state: nextState,
    };
  }

  const basePrompt = buildSystemPrompt(locale);
  const stateInstructions = buildStateInstructions("idle", locale);

  return {
    systemPrompt: `${basePrompt}\n\n## Current Archive Node: IDLE\n${stateInstructions}`,
    messages,
    state,
  };
}
