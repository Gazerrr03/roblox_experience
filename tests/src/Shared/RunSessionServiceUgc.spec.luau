return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local RunSessionService = require(runModules:WaitForChild('RunSessionService'))

    local readyBrief = {
        Prompt = '做一个追逐型怪物',
        Goal = '压迫并追逐最近玩家',
        Experience = '持续紧张',
        SuccessCriteria = { '怪物可成功生成并进入队列' },
        Semantics = {
            Lore = '来自废弃通道的追猎者。',
            Atmosphere = 'Dread',
            TriggerIntentSummary = '探索开始后追击最近玩家。',
            CounterplayIntentSummary = '绕拐角并拉开距离。 ',
        },
    }

    local fakeGateway = {
        generateBrief = function(_self, prompt, playerContext)
            assert(
                type(prompt) == 'string' and prompt ~= '',
                'Prompt should flow into brief gateway'
            )
            assert(
                type(playerContext) == 'table' and type(playerContext.UserId) == 'number',
                'Brief gateway should receive player context'
            )
            return true,
                {
                    Status = 'Ready',
                    Brief = readyBrief,
                }
        end,
    }

    local fakeRandom = {
        NextInteger = function(_self, minimum, maximum)
            assert(minimum == 1 and maximum >= minimum, 'Seed bounds should stay valid')
            return 1001
        end,
    }

    local service = RunSessionService.new({
        MonsterBriefGateway = fakeGateway,
        GenerateRandomSource = fakeRandom,
    })
    service.IsLaunched = true

    local fakePlayer = {
        UserId = 404,
        DisplayName = 'UgcRunner',
    }

    service:_addPlayerState(fakePlayer)
    service:_grantStarterUgcTokenIfNeeded(fakePlayer, nil)
    assert(
        service.InventoryService:countByItemId(fakePlayer, 'ugc-gen-token') == 1,
        'Players should receive one starter UGC generation token'
    )

    service:_requestGenerateUgcMonster(fakePlayer, '请生成一个追逐怪物')
    assert(
        service.PendingUgcMonsterByUserId[fakePlayer.UserId] ~= nil,
        'Successful generation should queue a pending UGC monster payload'
    )
    assert(
        service.InventoryService:countByItemId(fakePlayer, 'ugc-gen-token') == 0,
        'Successful generation should consume one UGC token'
    )
    assert(
        service:_getUgcGenerationState(fakePlayer).Status == 'Ready',
        'Successful generation should set UGC state to Ready'
    )

    local failingGateway = {
        generateBrief = function()
            return false,
                {
                    ErrorCode = 'GatewayDown',
                    Message = 'LLM 服务不可用',
                }
        end,
    }

    local failingService = RunSessionService.new({
        MonsterBriefGateway = failingGateway,
        GenerateRandomSource = fakeRandom,
    })
    failingService.IsLaunched = true
    failingService:_addPlayerState(fakePlayer)
    failingService:_grantStarterUgcTokenIfNeeded(fakePlayer, nil)
    failingService:_requestGenerateUgcMonster(fakePlayer, '请生成一个追逐怪物')

    assert(
        failingService.PendingUgcMonsterByUserId[fakePlayer.UserId] == nil,
        'Gateway failure should not queue any pending UGC monster payload'
    )
    assert(
        failingService.InventoryService:countByItemId(fakePlayer, 'ugc-gen-token') == 1,
        'Gateway failure should not consume UGC generation tokens'
    )
    assert(
        failingService:_getUgcGenerationState(fakePlayer).Status == 'Rejected',
        'Gateway failure should set UGC state to Rejected'
    )

    local openedUserId
    local openedPayloadType
    failingService.Remotes = {
        RunPrivateState = {
            FireClient = function(_self, player, payload)
                openedUserId = player.UserId
                openedPayloadType = payload and payload.Type
            end,
        },
    }
    failingService:_openUgcLabPanel(fakePlayer)
    assert(
        openedUserId == fakePlayer.UserId,
        'UGC console should target the triggering player only'
    )
    assert(
        openedPayloadType == 'OpenUgcLabPanel',
        'UGC console should request opening the UGC popup'
    )
end
