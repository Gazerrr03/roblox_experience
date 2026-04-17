return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local gameplay = require(packages:WaitForChild('Gameplay'))
    local shared = require(packages:WaitForChild('Shared'))

    local compileMonsterForMaze = gameplay.Monsters.compileMonsterForMaze
    local monsterServiceModule = shared.Runtime.MonsterService
    local monsterAssetIds = gameplay.Monsters.MonsterAssetIds

    local compileOk, runtimeProfile = compileMonsterForMaze(gameplay.Config.Monsters[1])
    assert(compileOk == true, 'Expected maze monster runtime profile')

    runtimeProfile.CombatHitPoints = 2

    local function createCharacter(position)
        local character = Instance.new('Model')
        character.Name = 'MeleeSpecCharacter'

        local rootPart = Instance.new('Part')
        rootPart.Name = 'HumanoidRootPart'
        rootPart.Anchored = true
        rootPart.Position = position
        rootPart.Parent = character

        return character
    end

    local fakePlayer = {
        UserId = 501,
        Character = createCharacter(Vector3.new(4, 0, 0)),
    }

    local service = monsterServiceModule.new(
        runtimeProfile,
        function()
            return true
        end,
        nil,
        function()
            return true
        end,
        {
            AssetLoader = function(assetId)
                assert(
                    assetId == monsterAssetIds.DefaultModelAssetId,
                    'Melee spec should request the configured model asset id'
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
            LoadAnimationTrack = function()
                return {
                    Looped = false,
                    Play = function() end,
                    Stop = function() end,
                    AdjustSpeed = function() end,
                    GetMarkerReachedSignal = function()
                        return nil
                    end,
                }
            end,
            CreateLoopSound = function()
                return {
                    Play = function() end,
                    Stop = function() end,
                }
            end,
            GetPlayers = function()
                return {}
            end,
            Raycast = function()
                return nil
            end,
            VisualSmoothingSpeed = 1,
        }
    )

    service:spawn({ Vector3.new(0, 0, 0) }, 1)
    assert(
        service.CombatMaxHealth == 2 and service.CombatCurrentHealth == 2,
        'spawn should initialize combat hit points from CombatHitPoints'
    )

    local hrp = fakePlayer.Character:FindFirstChild('HumanoidRootPart')
    assert(hrp ~= nil, 'Fake player should expose HumanoidRootPart')
    hrp.CFrame = CFrame.lookAt(Vector3.new(4, 0, 0), Vector3.new(0, 4, 0))

    local ok1, r1 = service:tryApplyPlayerMeleeHit(fakePlayer, {
        DamagePips = 1,
        SwingArcDegrees = 90,
        SwingRange = 8,
    })
    assert(
        ok1 == true and r1.Killed == false and r1.RemainingHitPoints == 1,
        'first melee hit should reduce remaining health without killing'
    )

    local ok2, r2 = service:tryApplyPlayerMeleeHit(fakePlayer, {
        DamagePips = 1,
        SwingArcDegrees = 90,
        SwingRange = 8,
    })
    assert(
        ok2 == true and r2.Killed == true and r2.RemainingHitPoints == 0,
        'second melee hit should kill and report zero remaining health'
    )

    assert(service.MonsterRoot == nil, 'lethal melee should destroy the monster instance')

    fakePlayer.Character:Destroy()
end
