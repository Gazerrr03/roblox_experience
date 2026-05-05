import { streamText, convertToModelMessages } from "ai";
import type { UIMessage } from "ai";
import { createOpenAI } from "@ai-sdk/openai";
import { processMessage } from "@/agent";
import { getAgentTools } from "@/agent/tools";

const kimi = createOpenAI({
  apiKey: process.env.MOONSHOT_API_KEY,
  baseURL: "https://api.moonshot.cn/v1",
});

export async function POST(req: Request) {
  const body = (await req.json()) as {
    messages: Array<{ role: string; parts?: unknown[]; content?: unknown }>;
    sessionId: string;
    locale: string;
  };

  const { messages, sessionId, locale } = body;

  if (!sessionId || !locale || !Array.isArray(messages)) {
    return Response.json(
      { error: "Missing required fields: sessionId, locale, messages" },
      { status: 400 }
    );
  }

  const modelMessages = await convertToModelMessages(
    messages as Omit<UIMessage, "id">[]
  );

  const { systemPrompt } = processMessage(
    sessionId,
    modelMessages,
    locale as "en" | "zh"
  );

  const tools = getAgentTools();

  const result = streamText({
    model: kimi("kimi-k2.6"),
    system: systemPrompt,
    messages: modelMessages,
    tools,
  });

  return result.toUIMessageStreamResponse();
}
