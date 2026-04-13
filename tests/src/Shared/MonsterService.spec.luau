return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local gameplay = require(packages:WaitForChild('Gameplay'))
    local shared = require(packages:WaitForChild('Shared'))
    local monsterAssetIds = gameplay.Monsters.MonsterAssetIds

    local monsterServiceModule = shared.Runtime.MonsterService
    local compileMonsterForMaze = gameplay.Monsters.compileMonsterForMaze

    local compileOk, runtimeProfile = compileMonsterForMaze(gameplay.Config.Monsters[1])
    assert(compileOk == true, 'Expected the maze monster runtime profile to compile')

    local function createTrack(name)
        return {
            Name = name,
            IsPlaying = false,
            Speed = 0,
            Play = function(self)
                self.IsPlaying = true
            end,
            Stop = function(self)
                self.IsPlaying = false
            end,
            AdjustSpeed = function(self, speed)
                self.Speed = speed
            end,
        }
    end

    local function createCharacter(position)
        local character = Instance.new('Model')
        character.Name = 'MonsterServiceSpecCharacter'

        local rootPart = Instance.new('Part')
        rootPart.Name = 'HumanoidRootPart'
        rootPart.Anchored = true
        rootPart.Position = position
        rootPart.Parent = character

        return character
    end

    local function createPlayer(userId, position)
        return {
            UserId = userId,
            Character = createCharacter(position),
        }
    end

    local loadedTracks = {}
    local warnings = {}
    local sounds = {}
    local activePlayers = {}
    local service = monsterServiceModule.new(
        runtimeProfile,
        function()
            return true
        end,
        nil,
        nil,
        {
            AssetLoader = function(assetId)
                assert(
                    assetId == monsterAssetIds.DefaultModelAssetId,
                    'Monster service should request the configured model asset'
                )

                local monsterModel = Instance.new('Model')
                monsterModel.Name = 'Noob'

                local rootPart = Instance.new('Part')
                rootPart.Name = 'HumanoidRootPart'
                rootPart.Size = Vector3.new(2, 2, 1)
                rootPart.Parent = monsterModel

                local head = Instance.new('Part')
                head.Name = 'Head'
                head.Size = Vector3.new(2, 1, 1)
                head.Parent = monsterModel

                local humanoid = Instance.new('Humanoid')
                humanoid.Parent = monsterModel

                return monsterModel
            end,
            LoadAnimationTrack = function(_, _, animationName)
                local track = createTrack(animationName)
                loadedTracks[animationName] = track
                return track
            end,
            CreateLoopSound = function(_, soundAssetId, soundName)
                local sound = {
                    Name = soundName,
                    AssetId = soundAssetId,
                    IsPlaying = false,
                    Play = function(self)
                        self.IsPlaying = true
                    end,
                    Stop = function(self)
                        self.IsPlaying = false
                    end,
                }
                table.insert(sounds, sound)
                return sound
            end,
            GetPlayers = function()
                return activePlayers
            end,
            VisualSmoothingSpeed = 1,
            Warn = function(message)
                table.insert(warnings, message)
            end,
        }
    )

    service:spawn({
        Vector3.new(0, 0, 0),
        Vector3.new(24, 0, 0),
    }, 1)

    assert(
        service.MonsterRoot ~= nil and service.MonsterRoot:IsA('Model'),
        'Monster should spawn as a model'
    )
    assert(
        service.MonsterPositionPart ~= nil
            and service.MonsterPositionPart.Name == 'HumanoidRootPart',
        'Monster should use the humanoid root part as its position anchor'
    )
    assert(loadedTracks.MonsterIdle ~= nil, 'Monster should create an idle animation track')
    assert(loadedTracks.MonsterWalk ~= nil, 'Monster should create a walk animation track')
    assert(loadedTracks.MonsterRun ~= nil, 'Monster should create a run animation track')
    assert(#warnings == 0, 'Successful model loads should not emit fallback warnings')
    assert(#sounds == 1, 'Configured chase audio should create one looped sound')
    assert(
        sounds[1].AssetId == monsterAssetIds.DefaultChaseLoopSoundAssetId,
        'Monster should use the configured chase loop asset id'
    )

    local spawnPosition = service.MonsterPositionPart.Position
    service:update(0.5)
    assert(loadedTracks.MonsterIdle.IsPlaying == true, 'No target should keep the monster idle')
    assert(
        service.MonsterPositionPart.Position == spawnPosition,
        'Without a sensed target, the monster should stay still instead of patrolling'
    )
    assert(sounds[1].IsPlaying == false, 'Idle monsters should not play the chase loop')

    activePlayers = {
        createPlayer(101, Vector3.new(10, 0, 0)),
    }

    service:update(0.5)

    assert(loadedTracks.MonsterRun.IsPlaying == true, 'Sensed targets should switch to chase')
    assert(sounds[1].IsPlaying == true, 'Chasing should start the looped chase sound')
    assert(
        service:_getCurrentPosition().X > spawnPosition.X,
        'Chasing should advance the monster logical position toward the target'
    )
    assert(
        service.MonsterPositionPart.Position.X > spawnPosition.X,
        'Chasing should move the visible monster position forward'
    )
    assert(
        service.MonsterPositionPart.Position.X < service:_getCurrentPosition().X,
        'Visual smoothing should avoid snapping the visible position to the full logical step'
    )

    activePlayers = {}
    service:update(0.5)
    assert(
        loadedTracks.MonsterIdle.IsPlaying == true,
        'Losing the target should return the monster to idle'
    )
    assert(sounds[1].IsPlaying == false, 'Losing the target should stop the chase loop')

    service:destroy()
    assert(service.MonsterRoot == nil, 'Destroy should clear the spawned model reference')

    local fallbackWarnings = {}
    local fallbackService = monsterServiceModule.new(
        runtimeProfile,
        function()
            return true
        end,
        nil,
        nil,
        {
            AssetLoader = function()
                return nil, 'InjectedAssetLoadFailure'
            end,
            Warn = function(message)
                table.insert(fallbackWarnings, message)
            end,
        }
    )

    fallbackService:spawn({
        Vector3.new(0, 0, 0),
    }, 1)

    assert(
        fallbackService.MonsterRoot ~= nil and fallbackService.MonsterRoot:IsA('Part'),
        'Failed asset loads should fall back to the placeholder sphere'
    )
    assert(#fallbackWarnings == 1, 'Fallback loads should emit a warning for diagnostics')

    fallbackService:destroy()
end
