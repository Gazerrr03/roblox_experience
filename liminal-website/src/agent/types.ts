import type { Monster, Item, Clue } from "@/data/types";

export type AgentNode =
  | "idle"
  | "listening"
  | "narrate"
  | "create"
  | "explore"
  | "producing"
  | "refining"
  | "reveal";

export type Intent = "narrate" | "create" | "explore";

export interface LoreContext {
  relevantMonsters: Monster[];
  relevantClues: Clue[];
  relevantItems: Item[];
  zoneContext: string;
  referencedEntityIds: string[];
}

export interface CreationContext {
  contentType: "story" | "monster" | "item" | "clue" | "image" | "zone";
  theme?: string;
  referencedEntityIds: string[];
  generationStage: "concept" | "draft" | "refining" | "complete";
}

export interface TheoryContext {
  topic: string;
  relatedClueIds: string[];
  playerHypothesis: string;
  agentStance: "supporting" | "challenging" | "expanding";
}

export interface ToolResult {
  toolName: string;
  result: unknown;
  error?: string;
}

export interface AgentState {
  conversationId: string;
  currentNode: AgentNode;
  locale: "en" | "zh";
  intent?: Intent;
  creationContext?: CreationContext;
  theoryContext?: TheoryContext;
  toolResults: ToolResult[];
}

export interface ConversationSession {
  id: string;
  state: AgentState;
  startedAt: number;
  lastActiveAt: number;
}
