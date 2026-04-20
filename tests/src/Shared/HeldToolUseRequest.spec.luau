return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local packages = ReplicatedStorage:WaitForChild('Packages')
    local gameplay = require(packages:WaitForChild('Gameplay'))

    local HeldToolUseRequest = gameplay.HeldToolUseRequest

    local function makeCharacterWithHead()
        local character = Instance.new('Model')
        character.Name = 'HeldToolUseSpecCharacter'

        local head = Instance.new('Part')
        head.Name = 'Head'
        head.Anchored = true
        head.Parent = character

        return character, head
    end

    local function createBaseDeps(heldItem, consumeResult)
        local statuses = {}
        local consumeCalls = 0

        local deps = {
            canManageInventory = function()
                return true
            end,
            inventoryService = {
                getSummary = function()
                    return {
                        HeldItem = heldItem,
                    }
                end,
                consumeHeldItemState = function(_, _, _)
                    consumeCalls += 1
                    return true, consumeResult
                end,
            },
            monsterService = nil,
            playerService = {
                getSummary = function()
                    return {
                        PlayerState = {
                            IsDead = false,
                        },
                    }
                end,
                healHealthPips = function()
                    error('healHealthPips should not be called in this branch', 0)
                end,
            },
            setStatus = function(message)
                table.insert(statuses, message)
            end,
        }

        return deps, statuses, function()
            return consumeCalls
        end
    end

    do
        local character, head = makeCharacterWithHead()
        local player = {
            UserId = 801,
            DisplayName = 'FlashlightSpec',
            Character = character,
        }
        local heldItem = {
            Name = 'Flashlight',
            ToolCategory = 'Flashlight',
            CurrentState = 100,
            ConsumePerUse = 0,
            StateModel = 'Battery',
        }
        local deps, statuses, getConsumeCalls = createBaseDeps(heldItem, heldItem)

        HeldToolUseRequest.apply(player, deps)

        local light = head:FindFirstChild('FlashlightLight')
        assert(light ~= nil and light:IsA('SpotLight'), 'Flashlight use should create a head light')
        assert(light.Enabled == true, 'First flashlight use should turn the head light on')
        assert(
            string.find(statuses[#statuses], 'Headlamp on.', 1, true) ~= nil,
            'Status should report when the head light turns on'
        )

        HeldToolUseRequest.apply(player, deps)

        assert(light.Enabled == false, 'Second flashlight use should turn the head light off')
        assert(
            string.find(statuses[#statuses], 'Headlamp off.', 1, true) ~= nil,
            'Status should report when the head light turns off'
        )
        assert(
            getConsumeCalls() == 2,
            'Flashlight use should still pass through the shared consume path on each use'
        )

        character:Destroy()
    end

    do
        local player = {
            UserId = 802,
            DisplayName = 'CrowbarSpec',
            Character = nil,
        }
        local heldItem = {
            Name = 'Crowbar',
            ToolCategory = 'Crowbar',
            CurrentState = 10,
            ConsumePerUse = 0,
            StateModel = 'Durability',
            MeleeDamage = 1,
            SwingArcDegrees = 75,
            SwingRange = 8,
        }
        local deps, statuses = createBaseDeps(heldItem, heldItem)
        local meleePayload = nil
        deps.monsterService = {
            tryApplyPlayerMeleeHit = function(_, _, payload)
                meleePayload = payload
                return true,
                    {
                        Killed = false,
                        RemainingHitPoints = 2,
                    }
            end,
        }

        HeldToolUseRequest.apply(player, deps)

        assert(meleePayload ~= nil, 'Crowbar use should call the shared melee hook')
        assert(meleePayload.DamagePips == 1, 'Crowbar use should forward MeleeDamage as DamagePips')
        assert(
            meleePayload.SwingArcDegrees == 75 and meleePayload.SwingRange == 8,
            'Crowbar use should forward swing arc and range to the monster service'
        )
        assert(
            string.find(statuses[#statuses], 'Foe stamina: ~2.', 1, true) ~= nil,
            'Status should report the remaining monster hit points after a non-lethal melee hit'
        )
    end

    do
        local player = {
            UserId = 803,
            DisplayName = 'PotionSpec',
            Character = nil,
        }
        local heldItem = {
            Name = 'Potion',
            ToolCategory = 'Potion',
            CurrentState = 2,
            ConsumePerUse = 1,
            StateModel = 'Charges',
            HealHealthPips = 1,
        }
        local consumedHeldItem = table.clone(heldItem)
        consumedHeldItem.CurrentState = 1
        local deps, statuses = createBaseDeps(heldItem, consumedHeldItem)
        local healedPips = nil
        deps.playerService.healHealthPips = function(_, _, amount)
            healedPips = amount
            return true, 4
        end

        HeldToolUseRequest.apply(player, deps)

        assert(healedPips == 1, 'Potion use should forward HealHealthPips to PlayerService')
        assert(
            string.find(statuses[#statuses], 'health pips: 4.', 1, true) ~= nil,
            'Status should report healed health after potion use'
        )
        assert(
            string.find(statuses[#statuses], 'Charges remaining: 1', 1, true) ~= nil,
            'Status should include the consumed potion state in the shared output message'
        )
    end
end
