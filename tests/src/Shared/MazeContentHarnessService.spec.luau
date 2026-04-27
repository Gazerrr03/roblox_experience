return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local placeModules = ReplicatedStorage:WaitForChild('PlaceModules')
    local MazeContentHarnessService = require(
        placeModules:WaitForChild('MazeContentHarness'):WaitForChild('MazeContentHarnessService')
    )

    local snapshots = {}
    local privateStates = {}
    local player = {
        UserId = 42,
        DisplayName = 'Scout',
    }
    local character = {
        Parent = true,
        LastPivot = nil,
    }
    function character:FindFirstChildOfClass(_className)
        return nil
    end
    function character:FindFirstChild(_name)
        return nil
    end
    function character:PivotTo(cframe)
        self.LastPivot = cframe
    end
    player.Character = character

    local inventorySummary = {
        Capacity = 5,
        Weight = 0,
        Count = 3,
        BackpackCount = 2,
        HeldCount = 1,
        Value = 0,
        BackpackItems = {
            { InstanceId = 1, Name = 'Flashlight', ItemCategory = 'Tool' },
            { InstanceId = 2, Name = 'Crowbar', ItemCategory = 'Tool' },
        },
        HeldItem = {
            InstanceId = 3,
            Name = 'Potion',
            ItemCategory = 'Tool',
            ToolCategory = 'Potion',
            CooldownSeconds = 1,
        },
        LootCount = 2,
        ClueCount = 0,
        ToolCount = 3,
        MissionCount = 2,
    }

    local fakeInventoryService = {
        Capacity = 5,
    }
    function fakeInventoryService:getSummary(_player)
        return inventorySummary
    end
    function fakeInventoryService:extractMissionCargo(_player)
        return inventorySummary, 2
    end
    function fakeInventoryService:addPlayer(_player) end
    function fakeInventoryService:removePlayer(_player) end

    local fakeControlStateService = {}
    function fakeControlStateService:addPlayer(_player) end
    function fakeControlStateService:removePlayer(_player) end
    function fakeControlStateService:getSummary(_player)
        return { Mode = 'Walk' }
    end
    function fakeControlStateService:requestSprintStop(_player)
        return true, { Mode = 'Walk' }
    end
    function fakeControlStateService:syncPlayerState(_player, _summary)
        return true, { Mode = 'Walk' }
    end

    local fakePlayerService = {}
    function fakePlayerService:addPlayer(_player) end
    function fakePlayerService:removePlayer(_player) end
    function fakePlayerService:getSummary(_player)
        return {
            Health = {
                CurrentHealthPips = 2,
                MaxHealthPips = 2,
                IsDead = false,
                CorpseActive = false,
            },
            PlayerState = {
                HealthPips = 2,
                MaxHealthPips = 2,
                CurrentStamina = 100,
                MaxStamina = 100,
                IsDead = false,
                CanSprint = true,
                CorpseActive = false,
            },
        }
    end
    function fakePlayerService:setSprinting(_player, _isSprinting)
        return true
    end

    local fakePlayerStateService = {}
    function fakePlayerStateService:addPlayer(_player) end
    function fakePlayerStateService:removePlayer(_player) end
    function fakePlayerStateService:step(_dt) end

    local fakeMonsterService = {
        DestroyCalls = 0,
    }
    function fakeMonsterService:destroy()
        self.DestroyCalls += 1
    end
    function fakeMonsterService:spawn(_patrolPoints, _initialPatrolIndex) end
    function fakeMonsterService:tryApplyPlayerMeleeHit(_player, _options)
        return false, 'NoMonster'
    end

    local service = MazeContentHarnessService.new({
        Seed = 5150,
        GetPlayers = function()
            return { player }
        end,
        Remotes = {
            MazeAction = {
                OnServerEvent = {
                    Connect = function(_self, _callback)
                        return {
                            Disconnect = function() end,
                        }
                    end,
                },
            },
            MazeState = {
                FireClient = function(_self, _player, snapshot)
                    table.insert(snapshots, snapshot)
                end,
            },
            MazePrivateState = {
                FireClient = function(_self, _player, payload)
                    table.insert(privateStates, payload)
                end,
            },
        },
        InventoryService = fakeInventoryService,
        ControlStateService = fakeControlStateService,
        PlayerService = fakePlayerService,
        PlayerStateService = fakePlayerStateService,
        MonsterServiceFactory = function(
            _profile,
            _isExpeditionActive,
            _canTargetPlayer,
            _canTraverse,
            _options
        )
            return fakeMonsterService
        end,
        WorldBuilder = {
            build = function()
                return {
                    Root = Instance.new('Folder'),
                    SpawnCFrame = CFrame.new(0, 5, 0),
                    ReturnHoldCFrame = CFrame.new(10, 5, 0),
                    getPatrolPoints = function()
                        return { CFrame.new(0, 0, 0) }, 1
                    end,
                    findRoomByPosition = function()
                        return { Kind = 'Loot' }
                    end,
                    bindInteractions = function()
                        return {
                            disconnectAll = function() end,
                        }
                    end,
                    getLootNode = function()
                        return nil
                    end,
                    toggleDoor = function()
                        return false
                    end,
                }
            end,
        },
        LoadCharacter = function(_player) end,
    })

    service.SessionState:addPlayer({
        UserId = player.UserId,
        Name = player.DisplayName,
    })
    local started = service.SessionState:beginExpedition()
    assert(started == true, 'Test harness should enter Expedition for local return assertions')

    service.World = {
        Root = Instance.new('Folder'),
        ReturnHoldCFrame = CFrame.new(10, 5, 0),
        findRoomByPosition = function()
            return { Kind = 'Loot' }
        end,
    }
    service.IsLaunched = true
    service:_recordWorldBuildMetadata()

    local snapshot = service:_buildSnapshotFor(player)
    assert(snapshot.SessionPhase == 'MazeActive', 'Snapshot should stay on local MazeActive phase')
    assert(
        snapshot.CurrentRound == 1 and snapshot.MaxRounds == 1,
        'Snapshot should be single-round'
    )
    assert(snapshot.IsDirectBoot == true, 'Snapshot should keep direct boot semantics')
    assert(
        snapshot.WorldBuildSource == 'ContentHarness',
        'Snapshot should advertise content harness source'
    )

    service:_broadcastSnapshot()
    assert(#snapshots == 1, 'Broadcast should emit a MazeState snapshot')
    assert(#privateStates == 1 and privateStates[1] == nil, 'Private state should remain nil')

    service:_returnPlayerLocally(player, 'returned')
    assert(
        service.SessionState.BankedItemCount == 2,
        'Local return should bank mission loot without teleport'
    )
    assert(
        service.SessionState:getActiveCount() == 0,
        'Local return should remove the active player'
    )
    assert(
        service.SessionState.LoopState == 'Completed',
        'Last local return should close the content loop'
    )
    assert(
        fakeMonsterService.DestroyCalls == 1,
        'Completing the local loop should stop the monster service'
    )
    assert(
        character.LastPivot == service.World.ReturnHoldCFrame,
        'Returned players should move to the hold area'
    )

    local returnedSummaries = service.SessionState:getReturnedSummaries()
    assert(#returnedSummaries == 1, 'Local return should produce a returned summary')
    assert(
        returnedSummaries[1].ReturnReason == 'returned',
        'Return summary should preserve local reason'
    )
end
