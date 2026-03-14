local Workspace = game:GetService('Workspace')

local connected = 0

local function bindRoom(room)
    if not room:IsA('Model') then
        return
    end
    if not room:GetAttribute('MazeGenerated') then
        return
    end

    local button = room:FindFirstChild('ButtonPart')
    local floor = room:FindFirstChild('Floor')
    if not (button and floor and floor:IsA('BasePart')) then
        return
    end

    local prompt = button:FindFirstChildOfClass('ProximityPrompt')
    if not prompt then
        return
    end
    if prompt:GetAttribute('Bound') then
        return
    end

    prompt:SetAttribute('Bound', true)
    connected += 1
    prompt.Triggered:Connect(function(player)
        floor.BrickColor = BrickColor.random()
        print(player.Name .. ' 触发了按钮，房间地板已变色')
    end)
end

for _, room in ipairs(Workspace:GetChildren()) do
    bindRoom(room)
end

Workspace.ChildAdded:Connect(function(child)
    task.defer(function()
        bindRoom(child)
    end)
end)

print('InteractionHandler 初始化完成')
