return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local gameplay = require(ReplicatedStorage:WaitForChild('Packages'):WaitForChild('Gameplay'))

    local Enemy = gameplay.Monsters.Enemy

    local updateOrder = {}
    local components = {
        Perception = {
            init = function() end,
            update = function(_, blackboard)
                table.insert(updateOrder, 'Perception')
                blackboard.Transient.PerceptionToken = 'seen'
                blackboard.Transient.HasTarget = true
                blackboard.Transient.TargetPlayer = 'Target'
                blackboard.Transient.TargetPosition = Vector3.new(8, 0, 0)
            end,
            destroy = function() end,
        },
        Movement = {
            init = function() end,
            update = function(_, blackboard)
                table.insert(updateOrder, 'Movement')
                assert(
                    blackboard.Transient.PerceptionToken == 'seen',
                    'Movement should consume target data from blackboard writes'
                )
                blackboard.Transient.NextPosition = Vector3.new(4, 0, 0)
                blackboard.Transient.DesiredAnimation = 'Run'
                blackboard.Transient.DesiredAnimationSpeed = 1.15
                blackboard.Transient.ShouldPlayChaseLoop = true
            end,
            destroy = function() end,
        },
        Attack = {
            init = function() end,
            update = function(_, blackboard)
                table.insert(updateOrder, 'Attack')
                assert(
                    blackboard.Transient.PerceptionToken == 'seen',
                    'Attack should consume perception output via blackboard instead of direct component calls'
                )
            end,
            destroy = function() end,
        },
    }

    local stateMachine = {
        Current = 'Idle',
        getState = function(self)
            return self.Current
        end,
        update = function(self, blackboard)
            table.insert(updateOrder, 'FSM')
            assert(
                blackboard.Transient.PerceptionToken == 'seen',
                'FSM should read from blackboard after perception stage'
            )
            self.Current = 'Alert'
            blackboard:setState(self.Current)
        end,
    }

    local enemy = Enemy.new({
        Id = 'spec-enemy',
        Name = 'Spec Enemy',
    }, {
        Components = components,
        StateMachine = stateMachine,
    })

    enemy:spawn()
    local decision = enemy:update(0.1, {
        Behaviors = {},
        CurrentPosition = Vector3.new(0, 0, 0),
        PatrolSpeedMultiplier = 1,
        PlayerPositions = {},
        SightRange = 10,
        Speed = 10,
    })

    assert(
        table.concat(updateOrder, ' -> ') == 'Perception -> FSM -> Movement -> Attack',
        'Enemy runtime should execute the fixed pipeline order'
    )
    assert(decision.State == 'Alert', 'FSM stage should drive state output')
    assert(decision.TargetPlayer == 'Target', 'Perception output should flow into decision payload')
    assert(decision.DesiredAnimation == 'Run', 'Movement output should flow into decision payload')
    assert(decision.ShouldPlayChaseLoop == true, 'Movement output should control chase loop intent')
    assert(
        table.concat(Enemy.UpdateOrder, ' -> ') == 'Perception -> FSM -> Movement -> Attack',
        'Enemy runtime should expose the canonical update order'
    )

    enemy:destroy()
end
