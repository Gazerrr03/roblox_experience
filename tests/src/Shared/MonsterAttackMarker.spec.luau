return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local shared = require(packages:WaitForChild('Shared'))

    local MonsterService = shared.Runtime.MonsterService

    local function buildRuntimeProfile()
        return {
            Id = 'attack-marker-spec',
            Name = 'Attack Marker Spec',
            Presentation = {
                ModelAssetId = 4446576906,
                RigType = 'R6',
                AnimationMode = 'defaultR6',
                ChaseLoopSoundAssetId = 9118823108,
            },
            AttackRange = 4,
            AttackCooldownSeconds = 0.05,
            AttackDamagePips = 2,
            Speed = 12,
            SightRange = 36,
            PatrolSpeedMultiplier = 0.45,
            SpawnOffset = Vector3.new(0, 4, 0),
            Behaviors = {
                SenseNearestTarget = true,
                Chase = true,
                Attack = true,
            },
            Effects = {},
            Components = {
                Attack = {
                    ArcDegrees = 100,
                    CooldownSeconds = 0.05,
                    DamagePips = 2,
                    HitMarkerName = 'Hit',
                    Range = 4,
                },
            },
        }
    end

    local function createMonsterModel()
        local monsterModel = Instance.new('Model')
        monsterModel.Name = 'MarkerSpecMonster'

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

    local function createPlayer(userId, position)
        local character = Instance.new('Model')
        character.Name = string.format('PlayerCharacter%d', userId)

        local rootPart = Instance.new('Part')
        rootPart.Name = 'HumanoidRootPart'
        rootPart.Anchored = true
        rootPart.Position = position
        rootPart.Parent = character

        return {
            UserId = userId,
            Character = character,
        }
    end

    local function createTrack(name, withMarkerSupport)
        local markerEvents = {}
        local track = {
            Name = name,
            IsPlaying = false,
            Speed = 1,
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

        if withMarkerSupport then
            track.GetMarkerReachedSignal = function(_, markerName)
                if markerEvents[markerName] == nil then
                    markerEvents[markerName] = Instance.new('BindableEvent')
                end
                return markerEvents[markerName].Event
            end
            track.FireMarker = function(_, markerName)
                local markerEvent = markerEvents[markerName]
                if markerEvent then
                    markerEvent:Fire()
                end
            end
        end

        return track
    end

    local activePlayers = {}
    local hitEvents = {}
    local loadedTracks = {}
    local blockedPart = Instance.new('Part')
    local raycastMode = 'clear'
    local service = MonsterService.new(
        buildRuntimeProfile(),
        function()
            return true
        end,
        nil,
        nil,
        {
            AssetLoader = function()
                return createMonsterModel()
            end,
            GetPlayers = function()
                return activePlayers
            end,
            LoadAnimationTrack = function(_, _, animationName)
                local supportsMarkers = animationName == 'MonsterAttack'
                local track = createTrack(animationName, supportsMarkers)
                loadedTracks[animationName] = track
                return track
            end,
            OnAttackHit = function(player, damagePips, hitContext)
                table.insert(hitEvents, {
                    DamagePips = damagePips,
                    Player = player,
                    Reason = hitContext.Reason,
                })
            end,
            Raycast = function()
                if raycastMode == 'blocked' then
                    return {
                        Instance = blockedPart,
                    }
                end
                return nil
            end,
        }
    )

    activePlayers = {
        createPlayer(9001, Vector3.new(3, 4, 0)),
    }

    service:spawn({ Vector3.new(0, 0, 0) }, 1)
    assert(
        service.applyDamage == nil,
        'Monster runtime should not expose client damage settlement API'
    )
    service.MonsterRoot:PivotTo(CFrame.lookAt(Vector3.new(0, 4, 0), Vector3.new(5, 4, 0)))
    service:update(0.2)

    assert(#hitEvents == 0, 'Attack should not deal damage before the Hit marker is fired')

    loadedTracks.MonsterAttack:FireMarker('Hit')
    assert(#hitEvents == 1, 'Forward targets within range should be hit when marker fires')
    assert(hitEvents[1].DamagePips == 2, 'Attack damage should follow runtime AttackDamagePips')

    activePlayers[1].Character.HumanoidRootPart.Position = Vector3.new(-3, 4, 0)
    service:update(0.2)
    loadedTracks.MonsterAttack:FireMarker('Hit')
    assert(#hitEvents == 1, 'Targets behind the monster should fail the 100 degree arc gate')

    local boundaryRadians = math.rad(50)
    activePlayers[1].Character.HumanoidRootPart.Position =
        Vector3.new(math.cos(boundaryRadians) * 3, 4, math.sin(boundaryRadians) * 3)
    service:update(0.2)
    loadedTracks.MonsterAttack:FireMarker('Hit')
    assert(#hitEvents == 2, 'Targets on the 50 degree boundary should pass the arc gate')

    activePlayers[1].Character.HumanoidRootPart.Position = Vector3.new(3, 4, 0)
    raycastMode = 'blocked'
    service:update(0.2)
    loadedTracks.MonsterAttack:FireMarker('Hit')
    assert(#hitEvents == 2, 'Blocked line-of-sight should prevent marker damage')

    service:destroy()
    blockedPart:Destroy()

    local noMarkerHits = 0
    local noMarkerService = MonsterService.new(
        buildRuntimeProfile(),
        function()
            return true
        end,
        nil,
        nil,
        {
            AssetLoader = function()
                return createMonsterModel()
            end,
            GetPlayers = function()
                return activePlayers
            end,
            LoadAnimationTrack = function(_, _, animationName)
                local supportsMarkers = animationName ~= 'MonsterAttack'
                return createTrack(animationName, supportsMarkers)
            end,
            OnAttackHit = function()
                noMarkerHits += 1
            end,
        }
    )

    activePlayers[1].Character.HumanoidRootPart.Position = Vector3.new(3, 4, 0)
    noMarkerService:spawn({ Vector3.new(0, 0, 0) }, 1)
    noMarkerService.MonsterRoot:PivotTo(CFrame.lookAt(Vector3.new(0, 4, 0), Vector3.new(5, 4, 0)))
    noMarkerService:update(0.2)
    noMarkerService:update(0.2)
    assert(noMarkerHits == 0, 'Animations without Hit marker support should never settle damage')
    noMarkerService:destroy()
end
