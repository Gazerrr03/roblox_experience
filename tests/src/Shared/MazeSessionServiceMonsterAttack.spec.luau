return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local mazeModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Maze')
    local MazeSessionService = require(mazeModules:WaitForChild('MazeSessionService'))

    local capturedRuntimeOptions = nil
    local service = MazeSessionService.new({
        MonsterServiceFactory = function(_, _, _, _, runtimeOptions)
            capturedRuntimeOptions = runtimeOptions
            return {
                destroy = function() end,
                spawn = function() end,
            }
        end,
    })

    assert(
        type(capturedRuntimeOptions) == 'table'
            and type(capturedRuntimeOptions.OnAttackHit) == 'function',
        'Maze runtime should wire server-side monster hit callback into MonsterService options'
    )

    service._setStatus = function(self, status)
        self.Status = status
    end

    local function createPlayer(userId, displayName)
        local character = Instance.new('Model')
        character.Name = displayName .. 'Character'

        local rootPart = Instance.new('Part')
        rootPart.Name = 'HumanoidRootPart'
        rootPart.Anchored = true
        rootPart.Position = Vector3.new(0, 5, 0)
        rootPart.Parent = character

        return {
            UserId = userId,
            DisplayName = displayName,
            Character = character,
        }
    end

    local activePlayer = createPlayer(101, 'Alpha')
    service:_addPlayerState(activePlayer)
    local beforeSummary = service.PlayerStateService:getSummary(activePlayer)

    capturedRuntimeOptions.OnAttackHit(activePlayer, 1)
    local afterSummary = service.PlayerStateService:getSummary(activePlayer)
    assert(
        afterSummary.HealthPips == beforeSummary.HealthPips - 1,
        'Server attack callback should settle light damage through player state service'
    )

    capturedRuntimeOptions.OnAttackHit(activePlayer, 3)
    local invalidSummary = service.PlayerStateService:getSummary(activePlayer)
    assert(
        invalidSummary.HealthPips == afterSummary.HealthPips,
        'Unsupported damage pips should be ignored by the maze attack callback bridge'
    )

    local inactivePlayer = createPlayer(202, 'Bravo')
    capturedRuntimeOptions.OnAttackHit(inactivePlayer, 1)
    local inactiveResult = service.PlayerStateService:get(inactivePlayer)
    assert(
        inactiveResult == nil,
        'Attack callback should not create or mutate state for players outside server tracking'
    )
end
