-- ShipDoors.luau
-- Sci-Fi Space Ship door controller
-- Controls 4 hinged cargo doors (CFrame rotation) + 2 small sliding doors (Z-axis slide)
-- Triggered via ProximityPrompt

local TweenService = game:GetService('TweenService')

local ShipDoors = {}
ShipDoors.__index = ShipDoors

-- Configuration
local TWEEN_INFO_OPEN = TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_INFO_CLOSE = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local ROTATION_ANGLE = 80 -- degrees to swing from closed toward open
local SLIDE_DISTANCE = 4 -- studs to slide for small doors
local PROMPT_MAX_ACTIVATION_DISTANCE = 10

-- Rotate a CFrame around a pivot point by angle on Y axis
local function rotateAroundPivot(cframe, pivotPos, angleDeg)
    local pivotCF = CFrame.new(pivotPos) * CFrame.Angles(0, math.rad(angleDeg), 0)
    return cframe:ToWorldSpace(pivotCF)
end

function ShipDoors.new(config)
    local self = setmetatable({}, ShipDoors)

    self.Name = config.name
    self.Parts = config.parts or {}
    self.HingePosition = config.hingePosition
    self.RotationAngle = config.rotationAngle or ROTATION_ANGLE
    self.SlideOffset = config.slideOffset or Vector3.new(0, 0, 0)
    self.IsLargeDoor = config.isLargeDoor or false

    self._isOpen = true
    self._isAnimating = false
    self._isLocked = false
    self._originalCFrames = {}
    self._prompts = {}

    -- Store original CFrames (OPEN position = ship's as-built state)
    for _, part in ipairs(self.Parts) do
        self._originalCFrames[part] = part.CFrame
    end

    return self
end

-- CLOSED position = original rotated around hinge
function ShipDoors:_getClosedCFrame(part)
    if self.IsLargeDoor then
        return rotateAroundPivot(
            self._originalCFrames[part],
            self.HingePosition,
            self.RotationAngle
        )
    else
        return self._originalCFrames[part] + self.SlideOffset
    end
end

function ShipDoors:_getOpenCFrame(part)
    return self._originalCFrames[part]
end

function ShipDoors:_setCollision(enabled)
    for _, part in ipairs(self.Parts) do
        part.CanCollide = enabled
    end
end

function ShipDoors:_setPromptActionText(actionText)
    for _, prompt in ipairs(self._prompts) do
        prompt.ActionText = actionText
    end
end

function ShipDoors:_setPromptEnabled(enabled)
    for _, prompt in ipairs(self._prompts) do
        prompt.Enabled = enabled
    end
end

function ShipDoors:open()
    if self._isOpen or self._isAnimating then
        return
    end
    self._isAnimating = true
    self:_setCollision(false)

    for _, part in ipairs(self.Parts) do
        local tween = TweenService:Create(part, TWEEN_INFO_OPEN, {
            CFrame = self:_getOpenCFrame(part),
        })
        tween:Play()
    end

    task.delay(TWEEN_INFO_OPEN.Time, function()
        self._isOpen = true
        self._isAnimating = false
        self:_setPromptActionText('Close Door')
    end)
end

function ShipDoors:close()
    if not self._isOpen or self._isAnimating then
        return
    end
    self._isAnimating = true

    for _, part in ipairs(self.Parts) do
        local tween = TweenService:Create(part, TWEEN_INFO_CLOSE, {
            CFrame = self:_getClosedCFrame(part),
        })
        tween:Play()
    end

    task.delay(TWEEN_INFO_CLOSE.Time, function()
        self._isOpen = false
        self._isAnimating = false
        self:_setCollision(true)
        self:_setPromptActionText('Open Door')
    end)
end

function ShipDoors:toggle()
    if self._isLocked then
        return
    end

    if self._isOpen then
        self:close()
    else
        self:open()
    end
end

function ShipDoors:lock()
    self._isLocked = true
    self:_setPromptEnabled(false)
end

function ShipDoors:unlock()
    self._isLocked = false
    self:_setPromptEnabled(true)
end

function ShipDoors:isLocked()
    return self._isLocked == true
end

-- ============================================================
-- FIND DOOR PANEL — recurses into Model children to find MeshPart
-- ============================================================

local function findMeshPart(model)
    if model:IsA('MeshPart') or model:IsA('Part') then
        return model
    end
    for _, child in ipairs(model:GetChildren()) do
        local found = findMeshPart(child)
        if found then
            return found
        end
    end
    return nil
end

local function clearPromptArtifacts(part)
    for _, child in ipairs(part:GetChildren()) do
        if
            child.Name == 'ShipDoorPrompt'
            or child.Name == 'ShipDoorPromptInside'
            or child.Name == 'ShipDoorPromptOutside'
            or child.Name == 'ShipDoorPromptInsideAttachment'
            or child.Name == 'ShipDoorPromptOutsideAttachment'
        then
            child:Destroy()
        end
    end
end

local function createPrompt(parent, name, objectText, actionText)
    local prompt = Instance.new('ProximityPrompt')
    prompt.Name = name
    prompt.ActionText = actionText or 'Open Door'
    prompt.ObjectText = objectText
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.MaxActivationDistance = PROMPT_MAX_ACTIVATION_DISTANCE
    prompt.HoldDuration = 0
    prompt.RequiresLineOfSight = false
    prompt.Parent = parent
    return prompt
end

local function attachDoorPrompt(door, part, objectText)
    clearPromptArtifacts(part)

    local prompt = createPrompt(
        part,
        'ShipDoorPrompt',
        objectText,
        door._isOpen and 'Close Door' or 'Open Door'
    )
    prompt.Triggered:Connect(function()
        door:toggle()
    end)

    table.insert(door._prompts, prompt)
end

-- ============================================================
-- INIT - set up all doors on the Sci-Fi Space Ship model
-- Call this once after the ship model is available in the workspace
-- ============================================================

function ShipDoors.init(shipModel)
    if not shipModel or not shipModel:IsA('Model') then
        warn('[ShipDoors] Invalid ship model provided')
        return
    end

    local dropship = shipModel:FindFirstChild('Helghast/VAK Dropship')
    if not dropship then
        warn('[ShipDoors] Helghast/VAK Dropship not found in ship model')
        return
    end

    local allDoors = {}

    -- Panel paths: Model child -> MeshPart child "Union1"
    local largeDoorConfigs = {
        {
            name = 'Left Door 1',
            folderName = 'Left Door 1',
            panelParentName = 'Helghast Dropship Improved Left Door 1',
            hingePosition = Vector3.new(58.85, 24.95, 294.61),
            rotationAngle = ROTATION_ANGLE,
        },
        {
            name = 'Left Door 2',
            folderName = 'Left Door 2',
            panelParentName = 'Helghast Dropship Improved Left Door 2',
            hingePosition = Vector3.new(54.82, 24.95, 290.58),
            rotationAngle = ROTATION_ANGLE,
        },
        {
            name = 'Right Door 1',
            folderName = 'Right Door 1',
            panelParentName = 'Helghast Dropship Improved Right Door 1',
            hingePosition = Vector3.new(45.06, 24.95, 308.40),
            rotationAngle = ROTATION_ANGLE,
        },
        {
            name = 'Right Door 2',
            folderName = 'Right Door 2',
            panelParentName = 'Helghast Dropship Improved Right Door 2',
            hingePosition = Vector3.new(41.03, 24.95, 304.37),
            rotationAngle = ROTATION_ANGLE,
        },
    }

    -- LARGE HINGED DOORS
    -- Each door folder contains multiple Model children; the panel is inside one of them.
    -- We must search all Model children, not just FindFirstChild("Model"), which only returns the first.
    local function findPanelParentInDoorFolder(doorFolder, panelParentName)
        if not doorFolder then
            return nil
        end
        for _, child in ipairs(doorFolder:GetChildren()) do
            if child:IsA('Model') then
                local found = child:FindFirstChild(panelParentName)
                if found then
                    return found
                end
            end
        end
        return nil
    end

    for _, config in ipairs(largeDoorConfigs) do
        local doorFolder = dropship:FindFirstChild(config.folderName)
        local panelParent = findPanelParentInDoorFolder(doorFolder, config.panelParentName)
        local panel = panelParent and findMeshPart(panelParent)

        if not panel then
            warn(
                '[ShipDoors] Panel not found: '
                    .. config.panelParentName
                    .. '/Union1 in '
                    .. config.folderName
            )
        end

        if panel then
            panel.Anchored = true
            panel.CanCollide = false

            local door = ShipDoors.new({
                name = config.name,
                parts = { panel },
                hingePosition = config.hingePosition,
                rotationAngle = config.rotationAngle,
                isLargeDoor = true,
            })

            attachDoorPrompt(door, panel, config.name)

            table.insert(allDoors, door)
            print('[ShipDoors] Registered large hinged door: ' .. config.name)
        end
    end

    -- SMALL SLIDING DOORS
    local smallDoorConfigs = {
        {
            name = 'Left Sliding Door',
            folderName = 'Left Door',
            slideOffset = Vector3.new(0, 0, -SLIDE_DISTANCE),
        },
        {
            name = 'Right Sliding Door',
            folderName = 'Right Door',
            slideOffset = Vector3.new(0, 0, -SLIDE_DISTANCE),
        },
    }

    for _, config in ipairs(smallDoorConfigs) do
        local doorFolder = dropship:FindFirstChild(config.folderName)
        local part = doorFolder and doorFolder:FindFirstChildOfClass('Part')

        if not part then
            warn('[ShipDoors] Part not found in ' .. config.folderName)
        end

        if part then
            part.Anchored = true
            part.CanCollide = false

            local door = ShipDoors.new({
                name = config.name,
                parts = { part },
                hingePosition = part.Position,
                rotationAngle = 0,
                slideOffset = config.slideOffset,
                isLargeDoor = false,
            })

            attachDoorPrompt(door, part, config.name)

            table.insert(allDoors, door)
            print('[ShipDoors] Registered small sliding door: ' .. config.name)
        end
    end

    print('[ShipDoors] Initialized with ' .. #allDoors .. ' doors')
    return allDoors
end

return ShipDoors
