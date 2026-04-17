return function()
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local runModules = ReplicatedStorage:WaitForChild('PlaceModules'):WaitForChild('Run')
    local ShipDoors = require(runModules:WaitForChild('ShipDoors'))

    local shipModel = Instance.new('Model')
    shipModel.Name = 'Sci-Fi Space Ship'

    local dropship = Instance.new('Model')
    dropship.Name = 'Helghast/VAK Dropship'
    dropship.Parent = shipModel

    local largeDoorConfigs = {
        {
            folderName = 'Left Door 1',
            panelParentName = 'Helghast Dropship Improved Left Door 1',
        },
        {
            folderName = 'Left Door 2',
            panelParentName = 'Helghast Dropship Improved Left Door 2',
        },
        {
            folderName = 'Right Door 1',
            panelParentName = 'Helghast Dropship Improved Right Door 1',
        },
        {
            folderName = 'Right Door 2',
            panelParentName = 'Helghast Dropship Improved Right Door 2',
        },
    }

    local panels = {}

    for _, config in ipairs(largeDoorConfigs) do
        local doorFolder = Instance.new('Folder')
        doorFolder.Name = config.folderName
        doorFolder.Parent = dropship

        local container = Instance.new('Model')
        container.Name = 'Container'
        container.Parent = doorFolder

        local panelParent = Instance.new('Model')
        panelParent.Name = config.panelParentName
        panelParent.Parent = container

        local panel = Instance.new('Part')
        panel.Name = 'Panel'
        panel.Size = Vector3.new(8, 8, 1)
        panel.Anchored = true
        panel.Parent = panelParent

        panels[config.folderName] = panel
    end

    local leftSlidingDoor = Instance.new('Folder')
    leftSlidingDoor.Name = 'Left Door'
    leftSlidingDoor.Parent = dropship
    local leftSlidingPart = Instance.new('Part')
    leftSlidingPart.Name = 'SlidingPart'
    leftSlidingPart.Size = Vector3.new(4, 4, 1)
    leftSlidingPart.Parent = leftSlidingDoor

    local rightSlidingDoor = Instance.new('Folder')
    rightSlidingDoor.Name = 'Right Door'
    rightSlidingDoor.Parent = dropship
    local rightSlidingPart = Instance.new('Part')
    rightSlidingPart.Name = 'SlidingPart'
    rightSlidingPart.Size = Vector3.new(4, 4, 1)
    rightSlidingPart.Parent = rightSlidingDoor

    local doors = ShipDoors.init(shipModel)

    assert(
        #doors == 6,
        'ShipDoors should register all four large doors and two sliding doors when authored parts exist'
    )

    for folderName, panel in pairs(panels) do
        local prompt = panel:FindFirstChild('ShipDoorPrompt')

        assert(
            prompt ~= nil,
            string.format('%s should get a direct prompt on the visible door panel', folderName)
        )
        assert(
            prompt.RequiresLineOfSight == false,
            string.format(
                '%s prompt should ignore line of sight so players can open from either side',
                folderName
            )
        )
        assert(
            prompt.KeyboardKeyCode == Enum.KeyCode.E,
            string.format('%s prompt should explicitly use E as the activation key', folderName)
        )
        assert(
            prompt.ActionText == 'Close Door',
            string.format('%s prompt should match the authored open-door state', folderName)
        )
    end
end
