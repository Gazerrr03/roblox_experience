local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Packages = ReplicatedStorage:WaitForChild('Packages')
local Gameplay = require(Packages:WaitForChild('Gameplay'))

local MODE = Gameplay.ControlState.Mode

local FormalLocomotion = {}

FormalLocomotion.Mode = MODE
FormalLocomotion.WalkSpeed = 16
FormalLocomotion.SprintWalkSpeed = 24

function FormalLocomotion.summarize(playerStateSummary, controlStateSummary)
    local playerState = playerStateSummary or {}
    local controlState = controlStateSummary or {}
    local isDead = playerState.IsDead == true
    local canSprint = not isDead and playerState.CanSprint == true

    local mode = MODE.Walk
    if not isDead and controlState.Mode == MODE.Sprint then
        mode = MODE.Sprint
    end

    local walkSpeed = FormalLocomotion.WalkSpeed
    if isDead then
        walkSpeed = 0
    elseif mode == MODE.Sprint then
        walkSpeed = FormalLocomotion.SprintWalkSpeed
    end

    return {
        Mode = mode,
        WalkSpeed = walkSpeed,
        CanSprint = canSprint,
    }
end

function FormalLocomotion.formatStatus(playerStateSummary, movementSummary)
    local playerState = playerStateSummary or {}
    local movement = movementSummary or {}

    if playerState.IsDead then
        return 'Disabled'
    end

    if movement.CanSprint then
        return 'Ready'
    end

    return 'Recovering'
end

function FormalLocomotion.applyToHumanoid(humanoid, movementSummary)
    if not humanoid then
        return
    end

    humanoid.WalkSpeed = (movementSummary and movementSummary.WalkSpeed)
        or FormalLocomotion.WalkSpeed
end

return FormalLocomotion
