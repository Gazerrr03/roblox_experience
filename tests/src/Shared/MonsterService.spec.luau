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
            DisplayName = string.format('Player%d', userId),
        }
    end

    local function createMonsterModel()
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

                return createMonsterModel()
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

    local function createSoundOnlyService(soundPlayers, clock)
        local chaseSounds = {}
        local soundOnlyService = monsterServiceModule.new(
            runtimeProfile,
            function()
                return true
            end,
            nil,
            nil,
            {
                AssetLoader = function()
                    return createMonsterModel()
                end,
                AutoUpdateOnHeartbeat = false,
                Clock = function()
                    return clock.Now
                end,
                CreateLoopSound = function()
                    local sound = {
                        IsPlaying = false,
                        Play = function(self)
                            self.IsPlaying = true
                        end,
                        Stop = function(self)
                            self.IsPlaying = false
                        end,
                    }
                    table.insert(chaseSounds, sound)
                    return sound
                end,
                EnableSightFallback = false,
                GetPlayers = function()
                    return soundPlayers.List
                end,
                LoadAnimationTrack = function(_, _, animationName)
                    return createTrack(animationName)
                end,
                SoundMemorySeconds = 0.4,
                VisualSmoothingSpeed = 1,
            }
        )

        soundOnlyService:spawn({
            Vector3.new(0, 0, 0),
        }, 1)

        return soundOnlyService, chaseSounds
    end

    local soundPlayers = { List = {} }
    local soundClock = { Now = 0 }
    local noSoundService, noSoundChaseSounds = createSoundOnlyService(soundPlayers, soundClock)
    local noSoundSpawnPosition = noSoundService:_getCurrentPosition()
    soundPlayers.List = {
        createPlayer(201, noSoundSpawnPosition + Vector3.new(8, 0, 0)),
    }
    noSoundService:update(0.2)
    assert(
        noSoundService.EnemyRuntime.Blackboard.CurrentTarget == nil,
        'Sound-only monster should not target a visible nearby player without sound'
    )
    assert(
        noSoundService:_getCurrentPosition() == noSoundSpawnPosition,
        'Sound-only monster should stay still when no sound stimulus exists'
    )
    assert(
        noSoundChaseSounds[1].IsPlaying == false,
        'Sound-only monster should not start chase audio without sound'
    )
    noSoundService:destroy()

    soundPlayers = { List = {} }
    soundClock = { Now = 0 }
    local heardService, heardChaseSounds = createSoundOnlyService(soundPlayers, soundClock)
    local heardSpawnPosition = heardService:_getCurrentPosition()
    local loudPlayer = createPlayer(202, heardSpawnPosition + Vector3.new(36, 0, 0))
    soundPlayers.List = { loudPlayer }
    assert(
        heardService:reportSoundStimulus(loudPlayer, 64) == true,
        'Valid player sound should be registered'
    )
    heardService:update(0.2)
    assert(
        heardService.EnemyRuntime.Blackboard.CurrentTarget == loudPlayer,
        'Sound-only monster should target the player who made an in-range sound'
    )
    assert(
        heardService:_getCurrentPosition().X > heardSpawnPosition.X,
        'Sound-only monster should move toward a heard sound source'
    )
    assert(heardChaseSounds[1].IsPlaying == true, 'Sound-driven chase should start chase audio')
    heardService:destroy()

    soundPlayers = { List = {} }
    soundClock = { Now = 0 }
    local priorityService = createSoundOnlyService(soundPlayers, soundClock)
    local prioritySpawnPosition = priorityService:_getCurrentPosition()
    local nearVisualPlayer = createPlayer(203, prioritySpawnPosition + Vector3.new(5, 0, 0))
    local farSoundPlayer = createPlayer(204, prioritySpawnPosition + Vector3.new(60, 0, 0))
    local soundPosition = prioritySpawnPosition + Vector3.new(28, 0, 0)
    soundPlayers.List = { nearVisualPlayer, farSoundPlayer }
    priorityService:reportSoundStimulus(farSoundPlayer, 72, soundPosition)
    priorityService:update(0.2)
    assert(
        priorityService.EnemyRuntime.Blackboard.CurrentTarget == farSoundPlayer,
        'Sound-only monster should choose the loud player over a nearer visual player'
    )
    assert(
        priorityService.EnemyRuntime.Blackboard.TargetPositions[farSoundPlayer] == soundPosition,
        'Sound target movement should use the emitted sound position, not visual fallback'
    )
    priorityService:destroy()

    soundPlayers = { List = {} }
    soundClock = { Now = 0 }
    local expiryService, expiryChaseSounds = createSoundOnlyService(soundPlayers, soundClock)
    local expirySpawnPosition = expiryService:_getCurrentPosition()
    local expiryPlayer = createPlayer(205, expirySpawnPosition + Vector3.new(30, 0, 0))
    soundPlayers.List = { expiryPlayer }
    expiryService:reportSoundStimulus(expiryPlayer, 64, nil, 0.2)
    expiryService:update(0.2)
    assert(
        expiryService.EnemyRuntime.Blackboard.CurrentTarget == expiryPlayer,
        'Fresh sound should drive a sound-only target'
    )
    soundClock.Now = 1
    expiryService:update(0.2)
    assert(
        expiryService.EnemyRuntime.Blackboard.CurrentTarget == nil,
        'Expired sound should stop driving the sound-only target'
    )
    assert(
        expiryService.EnemyRuntime.Blackboard.LastSeenPosition == nil,
        'Expired sound should not leave a stale search position in sound-only mode'
    )
    assert(
        expiryChaseSounds[1].IsPlaying == false,
        'Expired sound should stop the sound-driven chase audio'
    )
    expiryService:destroy()
end
