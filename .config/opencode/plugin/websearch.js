// src/index.ts
import { tool } from "@opencode-ai/plugin";

// src/providers/registry.ts
var PROVIDER_TYPES_BY_ID = {
  anthropic: "anthropic",
  "github-copilot": "copilot",
  "kimi-for-coding": "kimi-for-coding",
  moonshotai: "moonshot",
  "moonshotai-cn": "moonshot",
  openai: "openai"
};
var NPM_TO_TYPE = {
  "@ai-sdk/anthropic": "anthropic",
  "@ai-sdk/github-copilot": "copilot",
  "@ai-sdk/openai": "openai"
};
var KIMI_MODEL_PREFIX = "kimi-";
var isKimiModel = (modelID) => modelID.toLowerCase().startsWith(KIMI_MODEL_PREFIX);
var detectProviderType = (provider) => {
  const byID = PROVIDER_TYPES_BY_ID[provider.id];
  if (byID) {
    return byID;
  }
  for (const [modelKey, model] of Object.entries(provider.models)) {
    const modelID = model.id ?? modelKey;
    if (isKimiModel(modelID)) {
      return "moonshot";
    }
    const byNpm = NPM_TO_TYPE[model.api.npm];
    if (byNpm) {
      return byNpm;
    }
  }
  return null;
};

// src/config.ts
var WEBSEARCH_ALWAYS = "always";
var WEBSEARCH_AUTO = "auto";
var getWebsearchOption = (model) => {
  const value = model.options.websearch;
  if (value === WEBSEARCH_ALWAYS || value === WEBSEARCH_AUTO) {
    return value;
  }
  return null;
};
var stripV1Suffix = (url) => url.replace(/\/v1\/?$/, "");
var extractStringOption = (options, key) => typeof options[key] === "string" ? options[key] : undefined;
var normalizeBaseURL = (type, baseURL) => type === "anthropic" ? stripV1Suffix(baseURL) : baseURL;
var resolveBaseURL = (provider, type) => {
  const configured = extractStringOption(provider.options, "baseURL");
  return configured ? normalizeBaseURL(type, configured) : undefined;
};
var collectWebsearchModels = (provider) => {
  let lockedModel = undefined;
  let fallbackModel = undefined;
  for (const model of Object.values(provider.models)) {
    const flag = getWebsearchOption(model);
    if (flag === WEBSEARCH_ALWAYS && !lockedModel) {
      lockedModel = model.id;
    }
    if (flag === WEBSEARCH_AUTO && !fallbackModel) {
      fallbackModel = model.id;
    }
  }
  return { fallbackModel, lockedModel };
};
var collectDefaultModel = (provider) => {
  const [firstModel] = Object.values(provider.models);
  return firstModel?.id;
};
var scanProvider = (provider) => {
  const type = detectProviderType(provider);
  if (!type) {
    return null;
  }
  const apiKey = provider.key ?? extractStringOption(provider.options, "apiKey");
  const { fallbackModel, lockedModel } = collectWebsearchModels(provider);
  if (!apiKey && !lockedModel && !fallbackModel) {
    return null;
  }
  const credentials = apiKey ? { apiKey, baseURL: resolveBaseURL(provider, type) } : null;
  const defaultModel = collectDefaultModel(provider);
  return {
    credentials,
    defaultModel,
    fallbackModel,
    lockedModel,
    providerID: provider.id,
    type
  };
};
var scanProviders = (providers) => {
  const result = [];
  for (const provider of providers) {
    const resolution = scanProvider(provider);
    if (resolution) {
      result.push(resolution);
    }
  }
  return result;
};
var GENERAL_MODEL_HINT = "claude-sonnet-4-6, claude-opus-4-6, gpt-5.4, gpt-5.4-mini, kimi-k2.6";
var COPILOT_MODEL_HINT = "gpt-5.3-codex, gpt-5.2-codex, gpt-5.2, gpt-5.1, gpt-5.4-mini";
var formatNoProviderError = () => `Error: web-search requires an Anthropic, OpenAI (API key or ChatGPT OAuth), Moonshot, or GitHub Copilot provider.

No supported provider credentials (API key or OAuth) were found.

To fix this, add an Anthropic, OpenAI, or Moonshot provider to your opencode.json:

{
  "provider": {
    "anthropic": {
      "options": {
        "apiKey": "{env:ANTHROPIC_API_KEY}"
      }
    }
  }
}

Or:

{
  "provider": {
    "openai": {
      "options": {
        "apiKey": "{env:OPENAI_API_KEY}"
      }
    }
  }
}

Or:

{
  "provider": {
    "moonshotai": {
      "options": {
        "apiKey": "{env:MOONSHOT_API_KEY}"
      }
    }
  }
}

Steps:
1. Open your opencode.json (project root, .opencode/, or ~/.config/opencode/)
2. Ensure you have an Anthropic/OpenAI/Moonshot provider configured with a valid API key, or active OpenAI ChatGPT OAuth/Copilot auth
3. Restart OpenCode to pick up the configuration change`;
var formatUnsupportedProviderError = (activeModelID) => `Error: your current model (${activeModelID}) does not support web search.

Web search requires an Anthropic, OpenAI, Moonshot, or GitHub Copilot web-search-capable model.

Known Copilot models that work with web search today include: ${COPILOT_MODEL_HINT}.

You can either:
1. Switch to a supported model (e.g. ${GENERAL_MODEL_HINT})
2. Set \`"websearch": "auto"\` on a supported model to use it as a fallback:

{
  "provider": {
    "anthropic": {
      "models": {
        "claude-sonnet-4-5": {
          "options": {
            "websearch": "auto"
          }
        }
      }
    }
  }
}

Or set \`"websearch": "always"\` to always use that model for web search regardless of your active model.`;

// src/providers/anthropic/index.ts
import Anthropic, { APIError } from "@anthropic-ai/sdk";

// src/providers/shared/search.ts
var EMPTY_LENGTH = 0;
var MAX_RESPONSE_TOKENS = 16000;
var SEARCH_INPUT_PREFIX = "Perform a web search for the query: ";
var SEARCH_SYSTEM_PROMPT = "You are an assistant for performing a web search tool use";
var buildSearchInput = (query) => `${SEARCH_INPUT_PREFIX}${query}`;
var buildStructuredResponse = (query, outputText, hits) => {
  const results = [];
  const trimmedOutputText = outputText.trim();
  if (trimmedOutputText.length > EMPTY_LENGTH) {
    results.push(trimmedOutputText);
  }
  if (hits.length > EMPTY_LENGTH) {
    results.push(hits);
  }
  return { query, results };
};

// src/providers/shared/errors.ts
var formatUnhandledSearchError = (error) => {
  if (error instanceof Error) {
    return `Error performing web search: ${error.message}`;
  }
  return `Error performing web search: ${String(error)}`;
};

// src/providers/anthropic/index.ts
var DEFAULT_SEARCH_USES = 8;
var processBlock = (block) => {
  if (block.type === "text") {
    const text = block.text.trim();
    if (text.length > EMPTY_LENGTH) {
      return text;
    }
  }
  if (block.type === "web_search_tool_result") {
    if (!Array.isArray(block.content)) {
      return `Web search error: ${block.content.error_code}`;
    }
    return block.content.map((searchResult) => ({
      title: searchResult.title,
      url: searchResult.url
    }));
  }
  return null;
};
var processResponseBlocks = (query, content) => {
  const results = [];
  for (const block of content) {
    const result = processBlock(block);
    if (result !== null) {
      results.push(result);
    }
  }
  return { query, results };
};
var buildWebSearchTool = () => ({
  max_uses: DEFAULT_SEARCH_USES,
  name: "web_search",
  type: "web_search_20250305"
});
var formatErrorMessage = (error) => {
  if (error instanceof APIError) {
    return `Anthropic API error: ${error.message} (status: ${error.status})`;
  }
  return formatUnhandledSearchError(error);
};
var createAnthropicClient = (config) => {
  const options = {
    apiKey: config.apiKey
  };
  if (config.baseURL) {
    options.baseURL = config.baseURL;
  }
  return new Anthropic(options);
};
var executeSearch = async (config, query) => {
  const client = createAnthropicClient(config);
  const webSearchTool = buildWebSearchTool();
  const response = await client.messages.create({
    max_tokens: MAX_RESPONSE_TOKENS,
    messages: [
      {
        content: buildSearchInput(query),
        role: "user"
      }
    ],
    model: config.model,
    system: SEARCH_SYSTEM_PROMPT,
    tools: [webSearchTool]
  });
  const content = response.content;
  const structured = processResponseBlocks(query, content);
  return JSON.stringify(structured);
};

// src/providers/chatgpt/constants.ts
var CHATGPT_DEFAULT_BASE_URL = "https://chatgpt.com/backend-api/codex";
var CHATGPT_USER_AGENT = "opencode-websearch";

// src/providers/chatgpt/index.ts
var DATA_PREFIX = "data: ";
var EMPTY_RESPONSE_BODY = "ChatGPT API returned an empty response body";
var EVENT_DELIMITER = `

`;
var EVENT_PREFIX = "event: ";
var NOT_FOUND = -1;
var SSE_ACCEPT = "text/event-stream";
var STREAM_ENABLED = true;
var STORE_DISABLED = false;
var USER_ROLE = "user";
var WEB_SEARCH_INCLUDE = ["web_search_call.action.sources"];
var WEB_SEARCH_TOOL = { type: "web_search" };
var formatErrorMessage2 = (error) => {
  if (error instanceof Error && "status" in error && typeof error.status === "number") {
    return `ChatGPT API error: ${error.message} (status: ${error.status})`;
  }
  return formatUnhandledSearchError(error);
};
var buildDefaultHeaders = (accountId, apiKey) => {
  const headers = {
    Accept: SSE_ACCEPT,
    Authorization: `Bearer ${apiKey}`,
    "Content-Type": "application/json",
    "User-Agent": CHATGPT_USER_AGENT
  };
  if (accountId) {
    headers["chatgpt-account-id"] = accountId;
  }
  return headers;
};
var resolveResponsesURL = (baseURL) => {
  const resolvedBaseURL = (baseURL ?? CHATGPT_DEFAULT_BASE_URL).replace(/\/$/, "");
  return `${resolvedBaseURL}/responses`;
};
var buildRequestBody = (config, query) => ({
  include: WEB_SEARCH_INCLUDE,
  input: [
    {
      content: [{ text: buildSearchInput(query), type: "input_text" }],
      role: USER_ROLE
    }
  ],
  instructions: SEARCH_SYSTEM_PROMPT,
  model: config.model,
  store: STORE_DISABLED,
  stream: STREAM_ENABLED,
  tool_choice: "auto",
  tools: [WEB_SEARCH_TOOL]
});
var parseErrorBody = (text) => {
  if (text.length === EMPTY_LENGTH) {
    return "no body";
  }
  try {
    const parsed = JSON.parse(text);
    if (typeof parsed.detail === "string" && parsed.detail.length > EMPTY_LENGTH) {
      return parsed.detail;
    }
    if (parsed.error && typeof parsed.error.message === "string" && parsed.error.message.length > EMPTY_LENGTH) {
      return parsed.error.message;
    }
  } catch {
    return text;
  }
  return text;
};
var throwAPIError = async (response) => {
  const text = await response.text();
  const message = parseErrorBody(text);
  const error = Object.assign(new Error(message), { status: response.status });
  throw error;
};
var createStreamState = () => ({
  hits: [],
  outputText: "",
  seenURLs: new Set
});
var parseEventBlock = (block) => {
  const lines = block.split(`
`);
  let data = "";
  let type = "";
  for (const line of lines) {
    if (line.startsWith(DATA_PREFIX)) {
      data += line.slice(DATA_PREFIX.length);
    }
    if (line.startsWith(EVENT_PREFIX)) {
      type = line.slice(EVENT_PREFIX.length);
    }
  }
  if (type.length === EMPTY_LENGTH || data.length === EMPTY_LENGTH) {
    return null;
  }
  return { data, type };
};
var parseEventData = (data) => {
  try {
    return JSON.parse(data);
  } catch {
    return null;
  }
};
var pushUniqueHit = (state, url) => {
  if (state.seenURLs.has(url)) {
    return;
  }
  state.seenURLs.add(url);
  state.hits.push({ title: url, url });
};
var appendSearchSources = (item, state) => {
  if (!item || item.type !== "web_search_call") {
    return;
  }
  const { action } = item;
  if (!action || action.type !== "search" || !action.sources) {
    return;
  }
  for (const source of action.sources) {
    pushUniqueHit(state, source.url);
  }
};
var applyEventData = (event, state) => {
  const parsed = parseEventData(event.data);
  if (!parsed) {
    return;
  }
  if (event.type === "response.output_text.delta" && typeof parsed.delta === "string") {
    state.outputText += parsed.delta;
  }
  if (event.type === "response.output_item.done") {
    appendSearchSources(parsed.item, state);
  }
};
var consumeBuffer = (buffer, state) => {
  let remaining = buffer;
  while (true) {
    const delimiterIndex = remaining.indexOf(EVENT_DELIMITER);
    if (delimiterIndex === NOT_FOUND) {
      return remaining;
    }
    const block = remaining.slice(EMPTY_LENGTH, delimiterIndex);
    remaining = remaining.slice(delimiterIndex + EVENT_DELIMITER.length);
    const event = parseEventBlock(block);
    if (!event) {
      continue;
    }
    applyEventData(event, state);
  }
};
var readStreamResponse = async (response) => {
  const { body } = response;
  if (!body) {
    throw new Error(EMPTY_RESPONSE_BODY);
  }
  const state = createStreamState();
  const decoder = new TextDecoder;
  let buffer = "";
  for await (const chunk of body) {
    buffer += decoder.decode(chunk, { stream: true });
    buffer = consumeBuffer(buffer, state);
  }
  buffer += decoder.decode();
  consumeBuffer(buffer, state);
  return state;
};
var executeSearch2 = async (config, query) => {
  const response = await fetch(resolveResponsesURL(config.baseURL), {
    body: JSON.stringify(buildRequestBody(config, query)),
    headers: buildDefaultHeaders(config.accountId, config.apiKey),
    method: "POST"
  });
  if (!response.ok) {
    return throwAPIError(response);
  }
  const streamState = await readStreamResponse(response);
  const structured = buildStructuredResponse(query, streamState.outputText, streamState.hits);
  return JSON.stringify(structured);
};

// src/providers/shared/openai-compatible.ts
import OpenAI from "openai";
var createOpenAICompatibleClient = (config, defaultHeaders) => {
  const options = {
    apiKey: config.apiKey
  };
  if (config.baseURL) {
    options.baseURL = config.baseURL;
  }
  if (defaultHeaders) {
    options.defaultHeaders = defaultHeaders;
  }
  return new OpenAI(options);
};
var collectMessageTextParts = (items) => {
  const textParts = [];
  for (const item of items) {
    if (item.type !== "message") {
      continue;
    }
    const message = item;
    for (const part of message.content) {
      if (part.type !== "output_text") {
        continue;
      }
      const textPart = part;
      const text = textPart.text.trim();
      if (text.length > EMPTY_LENGTH) {
        textParts.push(text);
      }
    }
  }
  return textParts;
};
var resolveOutputText = (outputText, items) => {
  const directText = outputText.trim();
  if (directText.length > EMPTY_LENGTH) {
    return directText;
  }
  const textParts = collectMessageTextParts(items);
  if (textParts.length === EMPTY_LENGTH) {
    return "";
  }
  return textParts.join(`

`);
};
var resolveChatCompletionOutputText = (message) => {
  if (typeof message.content !== "string") {
    return "";
  }
  const content = message.content.trim();
  if (content.length === EMPTY_LENGTH) {
    return "";
  }
  return content;
};
var pushUniqueHit2 = (seen, hits, title, url) => {
  if (seen.has(url)) {
    return;
  }
  seen.add(url);
  hits.push({ title, url });
};
var appendAnnotationHits = (items, seen, hits) => {
  for (const item of items) {
    if (item.type !== "message") {
      continue;
    }
    const message = item;
    for (const part of message.content) {
      if (part.type !== "output_text") {
        continue;
      }
      const outputText = part;
      for (const annotation of outputText.annotations) {
        if (annotation.type !== "url_citation") {
          continue;
        }
        pushUniqueHit2(seen, hits, annotation.title, annotation.url);
      }
    }
  }
};
var appendWebSearchSourceHits = (items, seen, hits) => {
  for (const item of items) {
    if (item.type !== "web_search_call") {
      continue;
    }
    const call = item;
    const { action } = call;
    if (action.type !== "search") {
      continue;
    }
    const { sources } = action;
    if (!sources || sources.length === EMPTY_LENGTH) {
      continue;
    }
    for (const source of sources) {
      pushUniqueHit2(seen, hits, source.url, source.url);
    }
  }
};
var collectUniqueAnnotationHits = (items) => {
  const seen = new Set;
  const hits = [];
  appendAnnotationHits(items, seen, hits);
  return hits;
};
var collectUniqueAnnotationAndSourceHits = (items) => {
  const seen = new Set;
  const hits = [];
  appendAnnotationHits(items, seen, hits);
  appendWebSearchSourceHits(items, seen, hits);
  return hits;
};
var collectUniqueChatCompletionAnnotationHits = (message) => {
  const { annotations } = message;
  if (!annotations || annotations.length === EMPTY_LENGTH) {
    return [];
  }
  const seen = new Set;
  const hits = [];
  for (const annotation of annotations) {
    if (annotation.type !== "url_citation") {
      continue;
    }
    const citation = annotation.url_citation;
    pushUniqueHit2(seen, hits, citation.title, citation.url);
  }
  return hits;
};

// src/providers/copilot/index.ts
import { APIError as APIError2 } from "openai";

// src/providers/copilot/constants.ts
var COPILOT_DEFAULT_BASE_URL = "https://api.githubcopilot.com";
var COPILOT_INITIATOR = "user";
var COPILOT_INTENT = "conversation-edits";
var COPILOT_USER_AGENT = "opencode-websearch";

// src/providers/copilot/index.ts
var WEB_SEARCH_INCLUDE2 = [
  "web_search_call.action.sources"
];
var WEB_SEARCH_TOOL2 = { type: "web_search" };
var formatErrorMessage3 = (error) => {
  if (error instanceof APIError2) {
    return `GitHub Copilot API error: ${error.message} (status: ${error.status})`;
  }
  return formatUnhandledSearchError(error);
};
var executeSearch3 = async (config, query) => {
  const client = createOpenAICompatibleClient(config, {
    "Openai-Intent": COPILOT_INTENT,
    "User-Agent": COPILOT_USER_AGENT,
    "x-initiator": COPILOT_INITIATOR
  });
  const response = await client.responses.create({
    include: WEB_SEARCH_INCLUDE2,
    input: buildSearchInput(query),
    instructions: SEARCH_SYSTEM_PROMPT,
    max_output_tokens: MAX_RESPONSE_TOKENS,
    model: config.model,
    tool_choice: "auto",
    tools: [WEB_SEARCH_TOOL2]
  });
  const outputText = resolveOutputText(response.output_text, response.output);
  const hits = collectUniqueAnnotationAndSourceHits(response.output);
  const structured = buildStructuredResponse(query, outputText, hits);
  return JSON.stringify(structured);
};

// src/providers/kimi-for-coding/index.ts
import { APIError as APIError3 } from "openai";
var INITIAL_TURN = 0;
var MAX_SEARCH_TURNS = 8;
var TURN_INCREMENT = 1;
var TOOL_CALL_FINISH_REASON = "tool_calls";
var TOOL_ROLE = "tool";
var USER_ROLE2 = "user";
var WEB_SEARCH_FUNCTION_NAME = "$web_search";
var WEB_SEARCH_TOOL3 = {
  function: {
    name: WEB_SEARCH_FUNCTION_NAME
  },
  type: "builtin_function"
};
var formatErrorMessage4 = (error) => {
  if (error instanceof APIError3) {
    return `Kimi for Coding API error: ${error.message} (status: ${error.status})`;
  }
  return formatUnhandledSearchError(error);
};
var buildMessages = (query) => [
  {
    content: SEARCH_SYSTEM_PROMPT,
    role: "system"
  },
  {
    content: buildSearchInput(query),
    role: USER_ROLE2
  }
];
var buildRequestBody2 = (model, messages) => ({
  messages,
  model,
  thinking: { type: "disabled" },
  tool_choice: "auto",
  tools: [WEB_SEARCH_TOOL3]
});
var createCompletion = async (client, model, messages) => client.post("/chat/completions", {
  body: buildRequestBody2(model, messages)
});
var extractBuiltinToolCalls = (message) => {
  if (!message.tool_calls) {
    return [];
  }
  const toolCalls = [];
  for (const toolCall of message.tool_calls) {
    const candidate = toolCall;
    if (candidate.type === "builtin_function" && candidate.function && typeof candidate.function.arguments === "string" && typeof candidate.function.name === "string" && typeof candidate.id === "string") {
      toolCalls.push(candidate);
    }
  }
  return toolCalls;
};
var appendAssistantToolCallMessage = (messages, message) => {
  messages.push({
    content: message.content,
    role: "assistant",
    tool_calls: message.tool_calls
  });
};
var appendToolResultMessage = (messages, toolCall) => {
  messages.push({
    content: toolCall.function.arguments,
    name: toolCall.function.name,
    role: TOOL_ROLE,
    tool_call_id: toolCall.id
  });
};
var buildEmptyResponse = (query) => JSON.stringify(buildStructuredResponse(query, "", []));
var buildFinalResponse = (query, message) => {
  const hits = collectUniqueChatCompletionAnnotationHits(message);
  const outputText = resolveChatCompletionOutputText(message);
  const structured = buildStructuredResponse(query, outputText, hits);
  return JSON.stringify(structured);
};
var buildMaxTurnsResponse = (query) => {
  const errorText = `Error: Kimi for Coding web search exceeded the maximum of ${MAX_SEARCH_TURNS} tool-call turns without producing a final answer.`;
  return JSON.stringify(buildStructuredResponse(query, errorText, []));
};
var runSearchLoop = async (client, model, messages, query) => {
  for (let turn = INITIAL_TURN;turn < MAX_SEARCH_TURNS; turn += TURN_INCREMENT) {
    const completion = await createCompletion(client, model, messages);
    const [choice] = completion.choices;
    if (!choice) {
      return buildEmptyResponse(query);
    }
    const toolCalls = extractBuiltinToolCalls(choice.message);
    if (choice.finish_reason !== TOOL_CALL_FINISH_REASON || toolCalls.length === EMPTY_LENGTH) {
      return buildFinalResponse(query, choice.message);
    }
    appendAssistantToolCallMessage(messages, choice.message);
    for (const toolCall of toolCalls) {
      appendToolResultMessage(messages, toolCall);
    }
  }
  return buildMaxTurnsResponse(query);
};
var executeSearch4 = async (config, query) => {
  const client = createOpenAICompatibleClient(config);
  const messages = buildMessages(query);
  return runSearchLoop(client, config.model, messages, query);
};

// src/providers/moonshot/index.ts
import { APIError as APIError4 } from "openai";
var INITIAL_TURN2 = 0;
var MAX_SEARCH_TURNS2 = 8;
var TURN_INCREMENT2 = 1;
var TOOL_CALL_FINISH_REASON2 = "tool_calls";
var TOOL_ROLE2 = "tool";
var USER_ROLE3 = "user";
var WEB_SEARCH_FUNCTION_NAME2 = "$web_search";
var WEB_SEARCH_TOOL4 = {
  function: {
    name: WEB_SEARCH_FUNCTION_NAME2,
    parameters: {
      properties: {
        query: { type: "string" }
      },
      required: ["query"],
      type: "object"
    }
  },
  type: "function"
};
var formatErrorMessage5 = (error) => {
  if (error instanceof APIError4) {
    return `Moonshot API error: ${error.message} (status: ${error.status})`;
  }
  return formatUnhandledSearchError(error);
};
var buildMessages2 = (query) => [
  {
    content: SEARCH_SYSTEM_PROMPT,
    role: "system"
  },
  {
    content: buildSearchInput(query),
    role: USER_ROLE3
  }
];
var buildRequestBody3 = (model, messages) => ({
  messages,
  model,
  thinking: { type: "disabled" },
  tool_choice: "auto",
  tools: [WEB_SEARCH_TOOL4]
});
var createCompletion2 = async (client, model, messages) => client.post("/chat/completions", {
  body: buildRequestBody3(model, messages)
});
var toMoonshotFunctionToolCall = (toolCall) => {
  const candidate = toolCall;
  if (typeof candidate.id !== "string") {
    return null;
  }
  if (!candidate.function) {
    return null;
  }
  const { arguments: callArguments, name } = candidate.function;
  if (typeof callArguments !== "string") {
    return null;
  }
  if (typeof name !== "string") {
    return null;
  }
  return {
    arguments: callArguments,
    id: candidate.id,
    name
  };
};
var extractFunctionToolCalls = (message) => {
  if (!message.tool_calls) {
    return [];
  }
  const toolCalls = [];
  for (const toolCall of message.tool_calls) {
    const parsed = toMoonshotFunctionToolCall(toolCall);
    if (!parsed) {
      continue;
    }
    toolCalls.push(parsed);
  }
  return toolCalls;
};
var appendAssistantToolCallMessage2 = (messages, message) => {
  messages.push({
    content: message.content,
    role: "assistant",
    tool_calls: message.tool_calls
  });
};
var parseToolArguments = (toolCall) => {
  try {
    return JSON.parse(toolCall.arguments);
  } catch {
    return { error: "Invalid tool arguments JSON" };
  }
};
var resolveToolResult = (toolCall) => {
  if (toolCall.name !== WEB_SEARCH_FUNCTION_NAME2) {
    return `Error: unable to find tool by name '${toolCall.name}'`;
  }
  return parseToolArguments(toolCall);
};
var appendToolResultMessage2 = (messages, toolCall) => {
  const content = JSON.stringify(resolveToolResult(toolCall));
  messages.push({
    content,
    name: toolCall.name,
    role: TOOL_ROLE2,
    tool_call_id: toolCall.id
  });
};
var buildEmptyResponse2 = (query) => JSON.stringify(buildStructuredResponse(query, "", []));
var buildFinalResponse2 = (query, message) => {
  const hits = collectUniqueChatCompletionAnnotationHits(message);
  const outputText = resolveChatCompletionOutputText(message);
  const structured = buildStructuredResponse(query, outputText, hits);
  return JSON.stringify(structured);
};
var buildMaxTurnsResponse2 = (query) => {
  const errorText = `Error: Moonshot web search exceeded the maximum of ${MAX_SEARCH_TURNS2} tool-call turns without producing a final answer.`;
  return JSON.stringify(buildStructuredResponse(query, errorText, []));
};
var runSearchLoop2 = async (client, model, messages, query) => {
  for (let turn = INITIAL_TURN2;turn < MAX_SEARCH_TURNS2; turn += TURN_INCREMENT2) {
    const completion = await createCompletion2(client, model, messages);
    const [choice] = completion.choices;
    if (!choice) {
      return buildEmptyResponse2(query);
    }
    const toolCalls = extractFunctionToolCalls(choice.message);
    if (choice.finish_reason !== TOOL_CALL_FINISH_REASON2 || toolCalls.length === EMPTY_LENGTH) {
      return buildFinalResponse2(query, choice.message);
    }
    appendAssistantToolCallMessage2(messages, choice.message);
    for (const toolCall of toolCalls) {
      appendToolResultMessage2(messages, toolCall);
    }
  }
  return buildMaxTurnsResponse2(query);
};
var executeSearch5 = async (config, query) => {
  const client = createOpenAICompatibleClient(config);
  const messages = buildMessages2(query);
  return runSearchLoop2(client, config.model, messages, query);
};

// src/providers/openai/index.ts
import { APIError as APIError5 } from "openai";
var WEB_SEARCH_TOOL5 = { type: "web_search" };
var formatErrorMessage6 = (error) => {
  if (error instanceof APIError5) {
    return `OpenAI API error: ${error.message} (status: ${error.status})`;
  }
  return formatUnhandledSearchError(error);
};
var executeSearch6 = async (config, query) => {
  const client = createOpenAICompatibleClient(config);
  const response = await client.responses.create({
    input: buildSearchInput(query),
    instructions: SEARCH_SYSTEM_PROMPT,
    max_output_tokens: MAX_RESPONSE_TOKENS,
    model: config.model,
    tools: [WEB_SEARCH_TOOL5]
  });
  const hits = collectUniqueAnnotationHits(response.output);
  const structured = buildStructuredResponse(query, response.output_text, hits);
  return JSON.stringify(structured);
};

// src/providers/index.ts
var PROVIDER_ADAPTERS = {
  anthropic: {
    executeSearch,
    formatErrorMessage
  },
  chatgpt: {
    executeSearch: executeSearch2,
    formatErrorMessage: formatErrorMessage2
  },
  copilot: {
    executeSearch: executeSearch3,
    formatErrorMessage: formatErrorMessage3
  },
  "kimi-for-coding": {
    executeSearch: executeSearch4,
    formatErrorMessage: formatErrorMessage4
  },
  moonshot: {
    executeSearch: executeSearch5,
    formatErrorMessage: formatErrorMessage5
  },
  openai: {
    executeSearch: executeSearch6,
    formatErrorMessage: formatErrorMessage6
  }
};
var dispatchSearch = async (providerType, config, query) => PROVIDER_ADAPTERS[providerType].executeSearch(config, query);
var dispatchErrorMessage = (providerType, error) => PROVIDER_ADAPTERS[providerType].formatErrorMessage(error);

// src/helpers.ts
var getCurrentMonthYear = () => new Date().toLocaleDateString("en-US", { month: "long", year: "numeric" });

// src/model-picker.ts
var findActive = (active, resolutions) => resolutions.find((resolution) => resolution.providerID === active.providerID) ?? null;
var findFirstWithKey = (resolutions, key) => resolutions.find((resolution) => Boolean(resolution[key])) ?? null;
var pickModel = (resolutions, active) => {
  if (active) {
    const direct = findActive(active, resolutions);
    if (direct) {
      return { modelID: active.modelID, resolution: direct };
    }
  }
  const locked = findFirstWithKey(resolutions, "lockedModel");
  if (locked?.lockedModel) {
    return { modelID: locked.lockedModel, resolution: locked };
  }
  const fallback = findFirstWithKey(resolutions, "fallbackModel");
  if (fallback?.fallbackModel) {
    return { modelID: fallback.fallbackModel, resolution: fallback };
  }
  const defaultResolution = resolutions.find((resolution) => resolution.defaultModel);
  if (defaultResolution?.defaultModel) {
    return { modelID: defaultResolution.defaultModel, resolution: defaultResolution };
  }
  return null;
};

// src/providers/shared/auth.ts
import { existsSync, readFileSync } from "node:fs";
import { join, sep } from "node:path";
var AUTH_FILE_NAME = "auth.json";
var OPENCODE_DIR = "opencode";
var PATH_START = 0;
var SHARE_DIR = "share";
var STATE_DIR = "state";
var resolveAuthPathFromStatePath = (statePath) => {
  if (!statePath) {
    return null;
  }
  const stateMarker = `${sep}${STATE_DIR}${sep}${OPENCODE_DIR}`;
  if (!statePath.endsWith(stateMarker)) {
    return null;
  }
  const dataMarker = `${sep}${SHARE_DIR}${sep}${OPENCODE_DIR}`;
  const dataPath = `${statePath.slice(PATH_START, -stateMarker.length)}${dataMarker}`;
  return join(dataPath, AUTH_FILE_NAME);
};
var resolveAuthPath = async (client, directory) => {
  const response = await client.path.get({ query: { directory } });
  return resolveAuthPathFromStatePath(response.data?.state);
};
var parseAuthStore = (content) => {
  try {
    const parsed = JSON.parse(content);
    if (parsed && typeof parsed === "object") {
      return parsed;
    }
    return null;
  } catch {
    return null;
  }
};
var readAuthEntry = async (client, directory, key) => {
  const authPath = await resolveAuthPath(client, directory);
  if (!authPath || !existsSync(authPath)) {
    return null;
  }
  const store = parseAuthStore(readFileSync(authPath, "utf8"));
  const candidate = store?.[key];
  if (!candidate || typeof candidate !== "object") {
    return null;
  }
  return candidate;
};

// src/providers/chatgpt/auth.ts
var OPENAI_AUTH_KEY = "openai";
var buildCredentials = (entry) => {
  if (entry.type !== "oauth") {
    return null;
  }
  if (typeof entry.access !== "string" || !entry.access) {
    return null;
  }
  if (typeof entry.accountId !== "string" || !entry.accountId) {
    return null;
  }
  return {
    accountId: entry.accountId,
    apiKey: entry.access,
    baseURL: CHATGPT_DEFAULT_BASE_URL
  };
};
var resolveChatGPTCredentials = async (client, directory) => {
  const entry = await readAuthEntry(client, directory, OPENAI_AUTH_KEY);
  return entry ? buildCredentials(entry) : null;
};

// src/providers/copilot/auth.ts
var COPILOT_AUTH_KEY = "github-copilot";
var HTTP_PREFIX = "http://";
var HTTPS_PREFIX = "https://";
var STRIP_LAST_CHAR = -1;
var STRING_START = 0;
var stripScheme = (value) => {
  if (value.startsWith(HTTPS_PREFIX)) {
    return value.slice(HTTPS_PREFIX.length);
  }
  if (value.startsWith(HTTP_PREFIX)) {
    return value.slice(HTTP_PREFIX.length);
  }
  return value;
};
var normalizeDomain = (value) => {
  const stripped = stripScheme(value.trim());
  return stripped.endsWith("/") ? stripped.slice(STRING_START, STRIP_LAST_CHAR) : stripped;
};
var buildCopilotBaseURL = (enterpriseUrl) => {
  if (!enterpriseUrl) {
    return COPILOT_DEFAULT_BASE_URL;
  }
  const domain = normalizeDomain(enterpriseUrl);
  return domain ? `https://copilot-api.${domain}` : COPILOT_DEFAULT_BASE_URL;
};
var buildCredentials2 = (entry) => {
  if (entry.type !== "oauth") {
    return null;
  }
  if (typeof entry.refresh !== "string" || !entry.refresh) {
    return null;
  }
  return {
    apiKey: entry.refresh,
    baseURL: buildCopilotBaseURL(entry.enterpriseUrl)
  };
};
var resolveCopilotCredentials = async (client, directory) => {
  const entry = await readAuthEntry(client, directory, COPILOT_AUTH_KEY);
  return entry ? buildCredentials2(entry) : null;
};

// src/providers/kimi-for-coding/auth.ts
var KIMI_FOR_CODING_AUTH_KEY = "kimi-for-coding";
var KIMI_FOR_CODING_BASE_URL = "https://api.kimi.com/coding/v1";
var KIMI_FOR_CODING_AUTH_TYPE_API = "api";
var MIN_KEY_LENGTH = 1;
var isKimiForCodingAuthEntry = (entry) => entry.type === KIMI_FOR_CODING_AUTH_TYPE_API && typeof entry.key === "string" && entry.key.length >= MIN_KEY_LENGTH;
var buildCredentials3 = (entry) => {
  if (typeof entry.key !== "string") {
    throw new Error("Kimi for Coding auth entry is missing a key");
  }
  return { apiKey: entry.key, baseURL: KIMI_FOR_CODING_BASE_URL };
};
var resolveKimiForCodingCredentials = async (readAuthEntry2) => {
  const entry = await readAuthEntry2(KIMI_FOR_CODING_AUTH_KEY);
  return entry && isKimiForCodingAuthEntry(entry) ? buildCredentials3(entry) : null;
};

// src/providers/moonshot/auth.ts
var MOONSHOT_DEFAULT_BASE_URL = "https://api.moonshot.ai/v1";
var MOONSHOT_AUTH_KEYS = ["moonshotai", "moonshotai-cn", "moonshot"];
var MOONSHOT_AUTH_TYPE_API = "api";
var MIN_KEY_LENGTH2 = 1;
var isMoonshotAuthEntry = (entry) => entry.type === MOONSHOT_AUTH_TYPE_API && typeof entry.key === "string" && entry.key.length >= MIN_KEY_LENGTH2;
var buildCredentials4 = (entry) => {
  if (typeof entry.key !== "string") {
    throw new Error("Moonshot auth entry is missing a key");
  }
  return { apiKey: entry.key, baseURL: MOONSHOT_DEFAULT_BASE_URL };
};
var resolveMoonshotCredentials = async (readAuthEntry2) => {
  for (const key of MOONSHOT_AUTH_KEYS) {
    const entry = await readAuthEntry2(key);
    if (entry && isMoonshotAuthEntry(entry)) {
      return buildCredentials4(entry);
    }
  }
  return null;
};

// src/index.ts
var CANONICAL_COPILOT_ID = "github-copilot";
var CANONICAL_OPENAI_ID = "openai";
var KIMI_FOR_CODING_BASE_URL2 = "https://api.kimi.com/coding/v1";
var KIMI_FOR_CODING_ID = "kimi-for-coding";
var MIN_QUERY_LENGTH = 2;
var NO_RESOLUTIONS = 0;
var hasCredentials = (resolution) => resolution.credentials !== null;
var attachMoonshotCredentials = (scanned, credentials) => {
  const canonical = scanned.find((resolution) => resolution.type === "moonshot");
  if (canonical && !canonical.credentials) {
    canonical.credentials = credentials;
  }
};
var attachKimiForCodingCredentials = (scanned, credentials) => {
  const canonical = scanned.find((resolution) => resolution.type === "kimi-for-coding");
  if (canonical) {
    canonical.credentials = {
      apiKey: credentials.apiKey,
      baseURL: canonical.credentials?.baseURL ?? credentials.baseURL
    };
    return;
  }
  scanned.push({
    credentials,
    defaultModel: "kimi-for-coding",
    providerID: KIMI_FOR_CODING_ID,
    type: "kimi-for-coding"
  });
};
var attachChatGPTCredentials = (scanned, chatgpt) => {
  const canonical = scanned.find((resolution) => resolution.providerID === CANONICAL_OPENAI_ID);
  if (canonical && !canonical.credentials?.baseURL) {
    canonical.credentials = chatgpt;
    canonical.type = "chatgpt";
  }
};
var attachCopilotCredentials = (scanned, copilot) => {
  const canonical = scanned.find((resolution) => resolution.providerID === CANONICAL_COPILOT_ID);
  if (canonical && !canonical.credentials?.baseURL) {
    canonical.credentials = copilot;
    return;
  }
  if (!canonical) {
    scanned.push({
      credentials: copilot,
      providerID: CANONICAL_COPILOT_ID,
      type: "copilot"
    });
  }
};
var buildSearchConfig = (picked) => {
  const { credentials, type } = picked.resolution;
  if (type === "kimi-for-coding") {
    return {
      apiKey: credentials.apiKey.trim(),
      baseURL: KIMI_FOR_CODING_BASE_URL2,
      model: "kimi-for-coding"
    };
  }
  return { ...credentials, model: picked.modelID };
};
var loadResolutions = async (client, directory) => {
  const { data } = await client.config.providers();
  if (!data) {
    return [];
  }
  const scanned = scanProviders(data.providers);
  const kimiForCoding = await resolveKimiForCodingCredentials(async (key) => readAuthEntry(client, directory, key));
  if (kimiForCoding) {
    attachKimiForCodingCredentials(scanned, kimiForCoding);
  }
  const moonshot = await resolveMoonshotCredentials(async (key) => readAuthEntry(client, directory, key));
  if (moonshot) {
    attachMoonshotCredentials(scanned, moonshot);
  }
  const chatgpt = await resolveChatGPTCredentials(client, directory);
  if (chatgpt) {
    attachChatGPTCredentials(scanned, chatgpt);
  }
  const copilot = await resolveCopilotCredentials(client, directory);
  if (copilot) {
    attachCopilotCredentials(scanned, copilot);
  }
  return scanned.filter(hasCredentials);
};
var src_default = async (input) => {
  let resolutions = null;
  const activeModels = new Map;
  const trackActiveModel = (sessionID, model) => {
    if (model?.id && model?.providerID) {
      activeModels.set(sessionID, {
        modelID: model.id,
        providerID: model.providerID
      });
    }
  };
  return {
    "chat.message": async (hookInput) => {
      trackActiveModel(hookInput.sessionID, hookInput.model);
    },
    "chat.params": async (hookInput) => {
      trackActiveModel(hookInput.sessionID, hookInput.model);
    },
    tool: {
      "web-search": tool({
        args: {
          query: tool.schema.string().min(MIN_QUERY_LENGTH).describe("The search query to use")
        },
        description: `- Allows OpenCode to search the web and use the results to inform responses
- Provides up-to-date information for current events and recent data
- Returns search result information formatted as search result blocks, including links as markdown hyperlinks
- Use this tool for accessing information beyond the model's knowledge cutoff
- Searches are performed automatically within a single API call

CRITICAL REQUIREMENT - You MUST follow this:
  - After answering the user's question, you MUST include a "Sources:" section at the end of your response
  - In the Sources section, list all relevant URLs from the search results as markdown hyperlinks: [Title](URL)
  - This is MANDATORY - never skip including sources in your response
  - Example format:

    [Your answer here]

    Sources:
    - [Source Title 1](https://example.com/1)
    - [Source Title 2](https://example.com/2)

Usage notes:
IMPORTANT - Use the correct year in search queries:
  - It is currently ${getCurrentMonthYear()}. You MUST use this when searching for recent information, documentation, or current events.
  - Example: If the user asks for "latest React docs", search for "React documentation" with the current year, NOT last year`,
        async execute(args, context) {
          resolutions ??= await loadResolutions(input.client, input.directory);
          const activeFromContext = context.extra?.model;
          const activeFromHook = activeModels.get(context.sessionID);
          const active = activeFromContext ? {
            modelID: activeFromContext.id ?? "unknown",
            providerID: activeFromContext.providerID ?? "unknown"
          } : activeFromHook;
          const picked = pickModel(resolutions, active);
          if (!picked) {
            return resolutions.length === NO_RESOLUTIONS ? formatNoProviderError() : formatUnsupportedProviderError(active?.modelID ?? "unknown");
          }
          try {
            return await dispatchSearch(picked.resolution.type, buildSearchConfig(picked), args.query);
          } catch (error) {
            return dispatchErrorMessage(picked.resolution.type, error);
          }
        }
      })
    }
  };
};
export {
  src_default as default
};
