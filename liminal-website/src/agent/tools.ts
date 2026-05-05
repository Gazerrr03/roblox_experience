import { tool } from "ai";
import { z } from "zod/v4";
import { monsters } from "@/data/monsters";
import { items } from "@/data/items";
import { clues } from "@/data/clues";

export const generateImageTool = tool({
  description:
    "Generate concept art for a player-created monster, scene, or item within the LIMINAL Maze. Describe the visual in the Maze's clinical-poetic aesthetic.",
  inputSchema: z.object({
    prompt: z.string().describe("The image generation prompt in English"),
    style: z
      .enum(["concept-art", "field-sketch", "archival-illustration"])
      .describe("Visual style"),
  }),
  execute: async ({ prompt, style }) => {
    const styleModifiers: Record<string, string> = {
      "concept-art":
        "dark atmospheric concept art, monochrome with amber highlights, horror aesthetic, gritty texture, CRT scanlines",
      "field-sketch":
        "rough field sketch, charcoal on aged paper, clinical annotations, forensic photography style",
      "archival-illustration":
        "archival scientific illustration, cross-hatching, vintage medical textbook, labeled diagram",
    };

    const fullPrompt = `${prompt}, ${styleModifiers[style]}`;

    const apiKey = process.env.IMAGE_GEN_API_KEY;
    const apiUrl =
      process.env.IMAGE_GEN_API_URL || "https://api.openai.com/v1/images/generations";

    if (!apiKey) {
      return {
        success: false,
        error: "Image generation service is not configured.",
        prompt: fullPrompt,
        imageUrl: "",
      };
    }

    try {
      const response = await fetch(apiUrl, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${apiKey}`,
        },
        body: JSON.stringify({
          model: process.env.IMAGE_GEN_MODEL || "dall-e-3",
          prompt: fullPrompt,
          n: 1,
          size: "1024x1024",
        }),
      });

      const data = (await response.json()) as Record<string, unknown>;
      const imageUrl = (data.data as Array<{ url?: string }>)?.[0]?.url || (data.url as string) || "";

      return {
        success: true,
        imageUrl,
        prompt: fullPrompt,
        error: "",
      };
    } catch (error) {
      return {
        success: false,
        error: String(error),
        prompt: fullPrompt,
        imageUrl: "",
      };
    }
  },
});

export const searchArchiveTool = tool({
  description:
    "Search the LIMINAL Archive for information about monsters, items, clues, or zones.",
  inputSchema: z.object({
    query: z.string().describe("Search query"),
    entityType: z
      .enum(["monster", "item", "clue", "all"])
      .describe("Type of entity to search"),
  }),
  execute: async ({ query, entityType }) => {
    const q = query.toLowerCase();
    const results: string[] = [];

    if (entityType === "monster" || entityType === "all") {
      for (const m of monsters) {
        if (
          m.alias.en.toLowerCase().includes(q) ||
          m.alias.zh.includes(query) ||
          m.codename.toLowerCase().includes(q) ||
          m.type.en.toLowerCase().includes(q)
        ) {
          results.push(
            `[MONSTER] ${m.alias.en} / ${m.alias.zh} (${m.codename}): ${m.description.en.slice(0, 300)}`
          );
        }
      }
    }

    if (entityType === "item" || entityType === "all") {
      for (const item of items) {
        if (
          item.name.en.toLowerCase().includes(q) ||
          item.name.zh.includes(query)
        ) {
          results.push(
            `[ITEM] ${item.name.en} / ${item.name.zh} (${item.category}): ${item.description.en.slice(0, 300)}`
          );
        }
      }
    }

    if (entityType === "clue" || entityType === "all") {
      for (const clue of clues) {
        if (
          clue.title.en.toLowerCase().includes(q) ||
          clue.title.zh.includes(query) ||
          clue.excerpt.en.toLowerCase().includes(q)
        ) {
          results.push(
            `[CLUE] ${clue.title.en} / ${clue.title.zh} (Credibility: ${clue.credibility}): ${clue.excerpt.en.slice(0, 300)}`
          );
        }
      }
    }

    return {
      query,
      entityType,
      count: results.length,
      results: results.slice(0, 10),
    };
  },
});

export const generateClueFragmentTool = tool({
  description:
    "Generate a new clue fragment in the LIMINAL narrative style, with appropriate credibility tier and zone placement.",
  inputSchema: z.object({
    title: z.string().describe("Clue title in English"),
    titleZh: z.string().describe("Clue title in Chinese"),
    zone: z
      .enum(["AT", "AR", "WF", "CR", "Library"])
      .describe("Zone where the clue is found"),
    credibility: z
      .enum(["teaching-true", "partial-true", "emotionally-distorted"])
      .describe("Credibility tier"),
    theme: z.string().describe("Narrative theme the clue explores"),
    relatedMonsterId: z
      .string()
      .optional()
      .describe("Related monster ID if applicable"),
  }),
  execute: async (params) => {
    return {
      ...params,
      template: {
        id: `CL-UGC-${Date.now()}`,
        type: "world" as const,
        credibility: params.credibility,
        title: { zh: params.titleZh, en: params.title },
        relatedEntityIds: params.relatedMonsterId ? [params.relatedMonsterId] : [],
      },
      instruction:
        "The LLM should now generate the excerpt, fullText, location, and flavor fields following the game's narrative style.",
    };
  },
});

export function getAgentTools() {
  return {
    generateImage: generateImageTool,
    searchArchive: searchArchiveTool,
    generateClueFragment: generateClueFragmentTool,
  };
}
