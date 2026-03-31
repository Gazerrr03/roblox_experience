local HttpService = game:GetService('HttpService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local ServerStorage = game:GetService('ServerStorage')

local MonsterBriefGateway = {}
MonsterBriefGateway.__index = MonsterBriefGateway

local DEFAULT_TIMEOUT_SECONDS = 8
local DEFAULT_ENDPOINT_ATTRIBUTE = 'MonsterBriefGatewayUrl'
local DEFAULT_API_KEY_ATTRIBUTE = 'MonsterBriefGatewayApiKey'
local DEFAULT_PROVIDER_ATTRIBUTE = 'MonsterBriefLlmProvider'
local DEFAULT_PROVIDER_API_KEY_ATTRIBUTE = 'MonsterBriefLlmApiKey'
local DEFAULT_PROVIDER_BASE_URL_ATTRIBUTE = 'MonsterBriefLlmBaseUrl'
local DEFAULT_PROVIDER_MODEL_ATTRIBUTE = 'MonsterBriefLlmModel'

local PROVIDER = table.freeze({
    Moonshot = 'moonshot',
    DeepSeek = 'deepseek',
})

local BRIEF_SYSTEM_PROMPT = table.concat({
    '你是 Roblox 怪物设计助手。',
    '任务：把玩家输入转成可执行的 brief JSON。',
    '严格输出 JSON，不要 markdown，不要额外解释。',
    '若信息缺失，输出：{"Ok":true,"Status":"NeedMoreInfo","Question":"..."}。',
    '若信息足够，输出：{"Ok":true,"Status":"Ready","Brief":{...}}。',
    'Brief 必须包含：Goal, Experience, Semantics.Lore, Semantics.Atmosphere, Semantics.TriggerIntentSummary, Semantics.CounterplayIntentSummary, SuccessCriteria(至少1条)。',
    'Prompt 字段保留用户原始需求。',
    'Atmosphere 只用单词：Dread/Horror/Tense/Pressure/Stealth。',
    '文本尽量简短中文。',
}, '\n')

MonsterBriefGateway.ErrorCode = table.freeze({
    EmptyPrompt = 'EmptyPrompt',
    EndpointNotConfigured = 'EndpointNotConfigured',
    HttpRequestFailed = 'HttpRequestFailed',
    UpstreamRejected = 'UpstreamRejected',
    InvalidResponse = 'InvalidResponse',
})

local function trimText(value)
    if type(value) ~= 'string' then
        return ''
    end

    return string.match(value, '^%s*(.-)%s*$') or ''
end

local function resolveAttributeString(attributeName)
    for _, container in ipairs({ game, ReplicatedStorage, ServerStorage }) do
        local value = container:GetAttribute(attributeName)
        if type(value) == 'string' and value ~= '' then
            return value
        end
    end

    return nil
end

local function decodeJson(body)
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, body)
    if not ok then
        return nil
    end

    return decoded
end

local function normalizeBaseUrl(baseUrl)
    local value = trimText(baseUrl)
    if value == '' then
        return nil
    end

    return string.gsub(value, '/+$', '')
end

local function normalizeProviderName(providerName)
    local value = string.lower(trimText(providerName))
    if value == PROVIDER.Moonshot or value == PROVIDER.DeepSeek then
        return value
    end

    return nil
end

local function normalizeContentAsJson(content)
    if type(content) ~= 'string' then
        return nil
    end

    local decoded = decodeJson(content)
    if decoded ~= nil then
        return decoded
    end

    local fenced = string.match(content, '^```[%a]*%s*([%s%S]-)%s*```$')
    if type(fenced) == 'string' then
        decoded = decodeJson(fenced)
        if decoded ~= nil then
            return decoded
        end
    end

    local firstBrace = string.find(content, '{', 1, true)
    local lastBrace = string.find(content, '}$')
    if firstBrace ~= nil and lastBrace ~= nil and firstBrace < lastBrace then
        decoded = decodeJson(string.sub(content, firstBrace, lastBrace))
        if decoded ~= nil then
            return decoded
        end
    end

    return nil
end

local function extractErrorMessage(responseBody)
    local decoded = decodeJson(responseBody)
    if type(decoded) ~= 'table' then
        return nil
    end

    local errorObject = decoded.error
    if type(errorObject) == 'table' then
        local message = trimText(errorObject.message)
        if message ~= '' then
            return message
        end
    end

    local message = trimText(decoded.message)
    if message ~= '' then
        return message
    end

    return nil
end

function MonsterBriefGateway.new(options)
    local gatewayOptions = options or {}

    return setmetatable({
        Endpoint = gatewayOptions.Endpoint,
        ApiKey = gatewayOptions.ApiKey,
        HttpRequest = gatewayOptions.HttpRequest,
        TimeoutSeconds = gatewayOptions.TimeoutSeconds or DEFAULT_TIMEOUT_SECONDS,
        EndpointAttributeName = gatewayOptions.EndpointAttributeName or DEFAULT_ENDPOINT_ATTRIBUTE,
        ApiKeyAttributeName = gatewayOptions.ApiKeyAttributeName or DEFAULT_API_KEY_ATTRIBUTE,
        Provider = gatewayOptions.Provider,
        ProviderApiKey = gatewayOptions.ProviderApiKey,
        ProviderBaseUrl = gatewayOptions.ProviderBaseUrl,
        ProviderModel = gatewayOptions.ProviderModel,
        ProviderAttributeName = gatewayOptions.ProviderAttributeName or DEFAULT_PROVIDER_ATTRIBUTE,
        ProviderApiKeyAttributeName = gatewayOptions.ProviderApiKeyAttributeName
            or DEFAULT_PROVIDER_API_KEY_ATTRIBUTE,
        ProviderBaseUrlAttributeName = gatewayOptions.ProviderBaseUrlAttributeName
            or DEFAULT_PROVIDER_BASE_URL_ATTRIBUTE,
        ProviderModelAttributeName = gatewayOptions.ProviderModelAttributeName
            or DEFAULT_PROVIDER_MODEL_ATTRIBUTE,
    }, MonsterBriefGateway)
end

function MonsterBriefGateway:_resolveEndpoint()
    return self.Endpoint or resolveAttributeString(self.EndpointAttributeName)
end

function MonsterBriefGateway:_resolveApiKey()
    return self.ApiKey or resolveAttributeString(self.ApiKeyAttributeName)
end

function MonsterBriefGateway:_resolveProvider()
    return normalizeProviderName(
        self.Provider or resolveAttributeString(self.ProviderAttributeName)
    )
end

function MonsterBriefGateway:_resolveProviderApiKey()
    return self.ProviderApiKey or resolveAttributeString(self.ProviderApiKeyAttributeName)
end

function MonsterBriefGateway:_resolveProviderBaseUrl()
    return normalizeBaseUrl(
        self.ProviderBaseUrl or resolveAttributeString(self.ProviderBaseUrlAttributeName)
    )
end

function MonsterBriefGateway:_resolveProviderModel()
    local model =
        trimText(self.ProviderModel or resolveAttributeString(self.ProviderModelAttributeName))
    if model == '' then
        return nil
    end

    return model
end

function MonsterBriefGateway:_request(payload)
    if self.HttpRequest then
        return self.HttpRequest(payload)
    end

    return HttpService:RequestAsync(payload)
end

function MonsterBriefGateway:_requestProviderBrief(provider, prompt, playerContext)
    local apiKey = self:_resolveProviderApiKey()
    local baseUrl = self:_resolveProviderBaseUrl()
    local model = self:_resolveProviderModel()
    if not apiKey or not baseUrl or not model then
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.EndpointNotConfigured,
                Message = 'UGC LLM 配置不完整（Provider/BaseUrl/Model/ApiKey）。',
            }
    end

    local body = {
        model = model,
        messages = {
            {
                role = 'system',
                content = BRIEF_SYSTEM_PROMPT,
            },
            {
                role = 'user',
                content = HttpService:JSONEncode({
                    Prompt = prompt,
                    Player = playerContext or {},
                }),
            },
        },
    }

    local success, responseOrError = pcall(function()
        return self:_request({
            Url = string.format('%s/chat/completions', baseUrl),
            Method = 'POST',
            Headers = {
                ['Content-Type'] = 'application/json',
                Authorization = string.format('Bearer %s', apiKey),
            },
            Body = HttpService:JSONEncode(body),
            Timeout = self.TimeoutSeconds,
        })
    end)

    if not success then
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.HttpRequestFailed,
                Message = string.format(
                    'UGC LLM 请求失败(provider=%s)：%s',
                    tostring(provider),
                    tostring(responseOrError)
                ),
            }
    end

    local response = responseOrError
    if type(response) ~= 'table' or response.Success ~= true then
        local statusCode = if type(response) == 'table' then response.StatusCode else nil
        local providerMessage = if type(response) == 'table'
            then extractErrorMessage(response.Body)
            else nil
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.HttpRequestFailed,
                Message = string.format(
                    'UGC LLM 请求失败(provider=%s,status=%s)：%s',
                    tostring(provider),
                    tostring(statusCode),
                    providerMessage or '请检查 provider 配置和体验 HTTP 设置。'
                ),
            }
    end

    local payload = decodeJson(response.Body)
    local choices = payload and payload.choices
    local firstChoice = type(choices) == 'table' and choices[1] or nil
    local message = firstChoice and firstChoice.message
    local content = message and message.content
    local normalizedPayload = normalizeContentAsJson(content)
    if type(normalizedPayload) ~= 'table' then
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.InvalidResponse,
                Message = string.format(
                    'UGC LLM 返回格式无法解析(provider=%s)。',
                    tostring(provider)
                ),
            }
    end

    return true, normalizedPayload
end

function MonsterBriefGateway:generateBrief(prompt, playerContext)
    local normalizedPrompt = trimText(prompt)
    if normalizedPrompt == '' then
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.EmptyPrompt,
                Message = '请输入你想要生成的怪物描述。',
            }
    end

    local endpoint = self:_resolveEndpoint()
    if not endpoint then
        local provider = self:_resolveProvider()
        if provider ~= nil then
            local providerOk, providerPayload =
                self:_requestProviderBrief(provider, normalizedPrompt, playerContext)
            if not providerOk then
                return false, providerPayload
            end

            if providerPayload.Status == 'NeedMoreInfo' then
                return true,
                    {
                        Status = 'NeedMoreInfo',
                        Question = providerPayload.Question or '请补充更多细节后再试。',
                    }
            end

            if type(providerPayload.Brief) ~= 'table' then
                return false,
                    {
                        ErrorCode = MonsterBriefGateway.ErrorCode.InvalidResponse,
                        Message = 'UGC LLM 未返回有效 brief。',
                    }
            end

            return true,
                {
                    Status = 'Ready',
                    Brief = providerPayload.Brief,
                }
        end

        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.EndpointNotConfigured,
                Message = if RunService:IsStudio()
                    then 'MonsterBriefGatewayUrl 未配置，暂时无法调用 LLM 服务。'
                    else 'UGC 服务暂不可用，请稍后重试。',
            }
    end

    local requestBody = {
        Prompt = normalizedPrompt,
        Player = playerContext or {},
    }

    local headers = {
        ['Content-Type'] = 'application/json',
    }

    local apiKey = self:_resolveApiKey()
    if apiKey then
        headers.Authorization = string.format('Bearer %s', apiKey)
    end

    local success, responseOrError = pcall(function()
        return self:_request({
            Url = endpoint,
            Method = 'POST',
            Headers = headers,
            Body = HttpService:JSONEncode(requestBody),
            Timeout = self.TimeoutSeconds,
        })
    end)

    if not success then
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.HttpRequestFailed,
                Message = string.format('LLM 网关请求失败：%s', tostring(responseOrError)),
            }
    end

    local response = responseOrError
    if type(response) ~= 'table' or response.Success ~= true then
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.HttpRequestFailed,
                Message = 'LLM 网关请求失败，请稍后重试。',
            }
    end

    local payload = decodeJson(response.Body)
    if type(payload) ~= 'table' then
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.InvalidResponse,
                Message = 'LLM 网关返回了无法解析的内容。',
            }
    end

    if payload.Ok ~= true then
        return false,
            {
                ErrorCode = payload.ErrorCode or MonsterBriefGateway.ErrorCode.UpstreamRejected,
                Message = payload.Message or 'LLM 服务拒绝了本次请求。',
            }
    end

    if payload.Status == 'NeedMoreInfo' then
        return true,
            {
                Status = 'NeedMoreInfo',
                Question = payload.Question or '请补充更多细节后再试。',
            }
    end

    if type(payload.Brief) ~= 'table' then
        return false,
            {
                ErrorCode = MonsterBriefGateway.ErrorCode.InvalidResponse,
                Message = 'LLM 网关未返回有效 brief。',
            }
    end

    return true, {
        Status = 'Ready',
        Brief = payload.Brief,
    }
end

return MonsterBriefGateway
