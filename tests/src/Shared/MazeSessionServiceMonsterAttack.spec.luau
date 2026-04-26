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
    assert(
        capturedRuntimeOptions.EnableSightFallback == false,
        'Maze headline monster should disable sight fallback for sound-only targeting'
    )
    assert(
        capturedRuntimeOptions.SoundMemorySeconds == 4,
        'Maze headline monster should configure the first sound memory window'
    )
    assert(
        capturedRuntimeOptions.SoundRangeMultiplier == 1,
        'Maze headline monster should use loudness as the first hearing radius'
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

    local reportedSounds = {}
    service.MonsterService = {
        reportSoundStimulus = function(_, player, loudness)
            table.insert(reportedSounds, {
                Loudness = loudness,
                UserId = player.UserId,
            })
            return true
        end,
    }
    service.World = {
        getDoor = function()
            return {
                IsOpen = true,
            }
        end,
        toggleDoor = function()
            return true
        end,
    }

    service:_setPlayerSprinting(activePlayer, true)
    service:_toggleDoor(activePlayer, 'Door_A')
    service:_handleUseTool(activePlayer)

    assert(#reportedSounds == 3, 'Sprint, door, and tool interactions should report sound')
    assert(reportedSounds[1].Loudness == 48, 'Sprint should use the high sound pressure tier')
    assert(
        reportedSounds[2].Loudness == 34,
        'Door interactions should use the map interaction tier'
    )
    assert(reportedSounds[3].Loudness == 28, 'Tool use should use the tool sound tier')
end
