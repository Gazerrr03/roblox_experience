return function()
    local HttpService = game:GetService('HttpService')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local MonsterBriefGateway = require(runModules:WaitForChild('MonsterBriefGateway'))

    local capturedRequest
    local gateway = MonsterBriefGateway.new({
        Endpoint = 'https://litellm.example.com/v1/chat/completions',
        EndpointProtocol = 'openai-chat',
        EndpointModel = 'moonshot/kimi-k2.5',
        ApiKey = 'test-key',
        HttpRequest = function(payload)
            capturedRequest = payload
            return {
                Success = true,
                Body = HttpService:JSONEncode({
                    choices = {
                        {
                            message = {
                                content = HttpService:JSONEncode({
                                    Ok = true,
                                    Status = 'Ready',
                                    Brief = {
                                        Prompt = '做一个压迫追逐怪',
                                        Goal = '持续追逐玩家',
                                        Experience = '压迫感',
                                        SuccessCriteria = { '可在迷宫内稳定追逐玩家' },
                                        Semantics = {
                                            Lore = '来自废弃实验室的追猎者',
                                            Atmosphere = 'Dread',
                                            TriggerIntentSummary = '听到玩家动静后开始追逐',
                                            CounterplayIntentSummary = '利用拐角拉开距离',
                                        },
                                    },
                                }),
                            },
                        },
                    },
                }),
            }
        end,
    })

    local ok, result = gateway:generateBrief('做一个压迫追逐怪', {
        UserId = 101,
        Name = 'Runner',
    })
    assert(ok == true, 'OpenAI compatible endpoint should be accepted')
    assert(result.Status == 'Ready', 'OpenAI compatible endpoint should produce Ready result')
    assert(type(result.Brief) == 'table', 'OpenAI compatible endpoint should decode brief payload')
    assert(
        capturedRequest ~= nil
            and capturedRequest.Url == 'https://litellm.example.com/v1/chat/completions',
        'Gateway should request the configured OpenAI endpoint URL'
    )

    local decodedBody = HttpService:JSONDecode(capturedRequest.Body)
    assert(
        decodedBody.model == 'moonshot/kimi-k2.5',
        'Gateway should pass configured endpoint model to OpenAI endpoint'
    )

    local fallbackGateway = MonsterBriefGateway.new({
        Endpoint = 'https://brief-gateway.example.com/generate',
        ApiKey = 'test-key',
        HttpRequest = function(_payload)
            return {
                Success = true,
                Body = HttpService:JSONEncode({
                    Ok = true,
                    Status = 'NeedMoreInfo',
                    Question = '请补充怪物弱点。',
                }),
            }
        end,
    })

    local fallbackOk, fallbackResult = fallbackGateway:generateBrief('做一个怪物', {
        UserId = 102,
        Name = 'FallbackRunner',
    })
    assert(fallbackOk == true, 'Legacy brief-json endpoint should remain supported')
    assert(
        fallbackResult.Status == 'NeedMoreInfo'
            and fallbackResult.Question == '请补充怪物弱点。',
        'Legacy brief-json endpoint should preserve NeedMoreInfo response'
    )
end
