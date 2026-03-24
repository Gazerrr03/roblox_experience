return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local gameplay = require(packages:WaitForChild('Gameplay'))
    local shared = require(packages:WaitForChild('Shared'))

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

    local loadedTracks = {}
    local warnings = {}
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
                    assetId == 4446576906,
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

    service:update(0.5)
    assert(loadedTracks.MonsterWalk.IsPlaying == true, 'Patrol updates should play the walk track')

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
