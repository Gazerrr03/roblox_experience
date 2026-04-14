-- Pure geometry for player crowbar / melee vs a monster anchor position (tests + runtime).

local EPS = 1e-4

local PlayerMonsterMelee = {}

function PlayerMonsterMelee.horizontalUnit(vector3)
    if typeof(vector3) ~= 'Vector3' then
        return nil
    end

    local horizontal = Vector3.new(vector3.X, 0, vector3.Z)
    if horizontal.Magnitude <= EPS then
        return nil
    end

    return horizontal.Unit
end

function PlayerMonsterMelee.evaluateSwing(
    playerPosition,
    playerLookVector,
    monsterPosition,
    swingRange,
    swingArcDegrees
)
    if typeof(playerPosition) ~= 'Vector3' then
        return false, 'InvalidPlayerPosition'
    end
    if typeof(monsterPosition) ~= 'Vector3' then
        return false, 'InvalidMonsterPosition'
    end

    local range = swingRange
    if type(range) ~= 'number' or range <= 0 then
        return false, 'InvalidSwingRange'
    end

    local arc = swingArcDegrees
    if type(arc) ~= 'number' or arc <= 0 then
        return false, 'InvalidSwingArc'
    end

    local offset = monsterPosition - playerPosition
    local distance = offset.Magnitude
    if distance > range + EPS then
        return false, 'OutOfRange'
    end

    local facing = PlayerMonsterMelee.horizontalUnit(playerLookVector)
    if facing == nil then
        return false, 'InvalidFacing'
    end

    local toMonster = PlayerMonsterMelee.horizontalUnit(offset)
    if toMonster == nil then
        return true, 'HitGeometryOk'
    end

    local halfArcRad = math.rad(arc * 0.5)
    local minDot = math.cos(halfArcRad)
    local dot = facing:Dot(toMonster)
    if dot + EPS < minDot then
        return false, 'OutOfSwingArc'
    end

    return true, 'HitGeometryOk'
end

return PlayerMonsterMelee
